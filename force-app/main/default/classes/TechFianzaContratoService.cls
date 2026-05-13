public without sharing class TechFianzaContratoService {

    /*
     * =====================================================================================
     * CLASE: TechFianzaContratoService
     * =====================================================================================
     *
     * Objetivo:
     * - Crear fianzas automáticamente desde Contract cuando el contrato se marca como Firmado.
     * - Validar precalificación suficiente.
     * - Crear fianzas de:
     *      1. Anticipo
     *      2. Cumplimiento
     *      3. Vicios Ocultos
     * - La fianza de Vicios Ocultos inicia al finalizar el contrato.
     * - Generar Plan de Pago y Recibos usando TechPlanPagoService.
     *
     * Reglas:
     * - Fianzas ya no nacen desde Opportunity.
     * - Toda fianza debe nacer desde Contract.
     * - La precalificación debe tener:
     *      Capacidad_Afianzamiento_Calc__c = 'Capacidad Suficiente'
     * - El plan de pago de fianzas se calcula sobre Prima_neta__c.
     */

    private static Boolean enCreacionDesdeContrato = false;

    public static final String ESTATUS_CONTRATO_FIRMADO = 'Firmado';
    public static final String CAPACIDAD_SUFICIENTE = 'Capacidad Suficiente';

    public static final String TIPO_FIANZA_ANTICIPO = 'Anticipo';
    public static final String TIPO_FIANZA_CUMPLIMIENTO = 'Cumplimiento';
    public static final String TIPO_FIANZA_VICIOS_OCULTOS = 'Vicios y Defectos Ocultos';

    public static final String ESTATUS_FIANZA_EMITIDA = 'Emitida';

    /*
     * Porcentajes sugeridos.
     * Ajustar si el negocio define reglas distintas.
     */
    private static final Decimal PORCENTAJE_ANTICIPO = 0.30;
    private static final Decimal PORCENTAJE_CUMPLIMIENTO = 0.10;
    private static final Decimal PORCENTAJE_VICIOS_OCULTOS = 0.10;

    /*
     * Factor estimado para calcular prima neta si el contrato no trae una prima específica.
     * Recomendación futura: sustituir por tabla de tarifa o motor de cotización de fianzas.
     */
    private static final Decimal FACTOR_PRIMA_DEFAULT = 0.01;

    /*
     * Vigencia adicional para Vicios Ocultos después del término del contrato.
     */
    private static final Integer MESES_VICIOS_OCULTOS = 12;

    private static final Set<String> TIPOS_FIANZA_AUTO = new Set<String>{
        TIPO_FIANZA_ANTICIPO,
        TIPO_FIANZA_CUMPLIMIENTO,
        TIPO_FIANZA_VICIOS_OCULTOS
    };

    public class ResultadoProceso {
        public Integer contratosRecibidos = 0;
        public Integer contratosValidos = 0;
        public Integer fianzasCreadas = 0;
        public Integer planesGenerados = 0;
        public List<String> mensajes = new List<String>();
    }

    public static Boolean estaEjecutandoCreacionDesdeContrato() {
        return enCreacionDesdeContrato;
    }

    /*
     * =====================================================================================
     * MÉTODO PRINCIPAL
     * =====================================================================================
     */
    public static ResultadoProceso procesarContratosFirmados(Set<Id> contractIds) {

        ResultadoProceso resultado = new ResultadoProceso();

        if (contractIds == null || contractIds.isEmpty()) {
            resultado.mensajes.add('No se recibieron contratos para procesar.');
            return resultado;
        }

        resultado.contratosRecibidos = contractIds.size();

        Map<Id, SObject> contratosPorId = obtenerContratos(contractIds);

        if (contratosPorId.isEmpty()) {
            resultado.mensajes.add('No se encontraron contratos.');
            return resultado;
        }

        Set<Id> contratosConPrecalificacion =
            obtenerContratosConPrecalificacionSuficiente(contratosPorId);

        resultado.contratosValidos = contratosConPrecalificacion.size();

        if (contratosConPrecalificacion.isEmpty()) {
            resultado.mensajes.add(
                'Ningún contrato cuenta con precalificación suficiente.'
            );
            return resultado;
        }

        Map<Id, Set<String>> tiposExistentesPorContrato =
            obtenerTiposFianzaExistentes(contratosConPrecalificacion);

        List<Tech_Fianza__c> fianzasPorInsertar = new List<Tech_Fianza__c>();

        for (Id contratoId : contratosConPrecalificacion) {

            SObject contrato = contratosPorId.get(contratoId);

            Set<String> tiposExistentes =
                tiposExistentesPorContrato.containsKey(contratoId)
                ? tiposExistentesPorContrato.get(contratoId)
                : new Set<String>();

            fianzasPorInsertar.addAll(
                construirFianzasPorContrato(
                    contrato,
                    tiposExistentes
                )
            );
        }

        if (fianzasPorInsertar.isEmpty()) {
            resultado.mensajes.add(
                'No se crearon fianzas porque ya existían o faltaban datos mínimos.'
            );
            return resultado;
        }

        Set<Id> fianzaIds = new Set<Id>();

        try {
            enCreacionDesdeContrato = true;

            insert fianzasPorInsertar;

            for (Tech_Fianza__c fianza : fianzasPorInsertar) {
                fianzaIds.add(fianza.Id);
            }

            resultado.fianzasCreadas = fianzaIds.size();

        } finally {
            enCreacionDesdeContrato = false;
        }

        if (!fianzaIds.isEmpty()) {
            TechPlanPagoService.generarPlanesYRecibosPorFianzaIds(fianzaIds);
            resultado.planesGenerados = fianzaIds.size();
        }

        resultado.mensajes.add(
            'Proceso terminado. Fianzas creadas: ' +
            String.valueOf(resultado.fianzasCreadas)
        );

        return resultado;
    }

    public static ResultadoProceso crearFianzasPorContrato(Id contractId) {

        if (contractId == null) {
            ResultadoProceso resultado = new ResultadoProceso();
            resultado.mensajes.add('No se recibió Contract Id.');
            return resultado;
        }

        return procesarContratosFirmados(new Set<Id>{ contractId });
    }

    /*
     * =====================================================================================
     * CONSTRUCCIÓN DE FIANZAS
     * =====================================================================================
     */
    private static List<Tech_Fianza__c> construirFianzasPorContrato(
        SObject contrato,
        Set<String> tiposExistentes
    ) {

        List<Tech_Fianza__c> fianzas = new List<Tech_Fianza__c>();

        if (contrato == null) {
            return fianzas;
        }

        if (tiposExistentes == null) {
            tiposExistentes = new Set<String>();
        }

        Date fechaInicio = obtenerFechaContratoInicio(contrato);
        Date fechaFin = obtenerFechaContratoFin(contrato);
        Decimal montoContrato = obtenerMontoContrato(contrato);

        if (
            fechaInicio == null ||
            fechaFin == null ||
            montoContrato == null ||
            montoContrato <= 0
        ) {
            return fianzas;
        }

        if (!tiposExistentes.contains(TIPO_FIANZA_ANTICIPO)) {
            fianzas.add(
                construirFianza(
                    contrato,
                    TIPO_FIANZA_ANTICIPO,
                    fechaInicio,
                    fechaFin,
                    montoContrato,
                    PORCENTAJE_ANTICIPO,
                    'Prima_Anticipo__c'
                )
            );
        }

        if (!tiposExistentes.contains(TIPO_FIANZA_CUMPLIMIENTO)) {
            fianzas.add(
                construirFianza(
                    contrato,
                    TIPO_FIANZA_CUMPLIMIENTO,
                    fechaInicio,
                    fechaFin,
                    montoContrato,
                    PORCENTAJE_CUMPLIMIENTO,
                    'Prima_Cumplimiento__c'
                )
            );
        }

        if (!tiposExistentes.contains(TIPO_FIANZA_VICIOS_OCULTOS)) {

            /*
             * Regla:
             * Vicios Ocultos inicia al finalizar el contrato.
             */
            Date inicioVicios = fechaFin;
            Date finVicios = fechaFin.addMonths(MESES_VICIOS_OCULTOS);

            fianzas.add(
                construirFianza(
                    contrato,
                    TIPO_FIANZA_VICIOS_OCULTOS,
                    inicioVicios,
                    finVicios,
                    montoContrato,
                    PORCENTAJE_VICIOS_OCULTOS,
                    'Prima_Vicios_Ocultos__c'
                )
            );
        }

        return fianzas;
    }

    private static Tech_Fianza__c construirFianza(
        SObject contrato,
        String tipoFianza,
        Date fechaInicio,
        Date fechaFin,
        Decimal montoContrato,
        Decimal porcentajeAfianzado,
        String campoPrimaContrato
    ) {

        Id contratoId = (Id) contrato.get('Id');

        Decimal montoAfianzado =
            (montoContrato * porcentajeAfianzado).setScale(2);

        Decimal primaNeta = getDecimal(contrato, campoPrimaContrato);

        if (primaNeta == null || primaNeta <= 0) {
            primaNeta = (montoAfianzado * FACTOR_PRIMA_DEFAULT).setScale(2);
        }

        Tech_Fianza__c fianza = new Tech_Fianza__c();

        String numeroContrato = getString(contrato, 'ContractNumber');

        if (String.isBlank(numeroContrato)) {
            numeroContrato = String.valueOf(contratoId);
        }

        setIfWritable(
            fianza,
            'Name',
            'Fianza ' + tipoFianza + ' - ' + numeroContrato
        );

        setIfWritable(fianza, 'Contrato__c', contratoId);

        fianza.Tipo_de_Riesgo__c = tipoFianza;

        fianza.Contratistas__c = obtenerContratista(contrato);
        fianza.Beneficiarios__c = obtenerBeneficiario(contrato);
        fianza.Afianzadoras__c = obtenerInstitucion(contrato);
        fianza.Vendedor__c = obtenerVendedor(contrato);

        fianza.Monto_Afianzado__c = montoAfianzado;
        fianza.Monto_Afianzado_Vigente__c = montoAfianzado;

        fianza.Prima_neta__c = primaNeta;
        fianza.Prima_Vigente__c = primaNeta;

        fianza.Fecha_de_Emision__c = fechaInicio;
        fianza.Fecha_de_Vencimiento__c = fechaFin;
        fianza.Fecha_Vencimiento_Vigente__c = fechaFin;

        fianza.Periodo_Pago__c = obtenerPeriodoPago(contrato);

        if (String.isBlank(fianza.Periodo_Pago__c)) {
            fianza.Periodo_Pago__c = 'Contado';
        }

        fianza.Estatus__c = ESTATUS_FIANZA_EMITIDA;

        return fianza;
    }

    /*
     * =====================================================================================
     * CONSULTA DE CONTRATOS
     * =====================================================================================
     */
    private static Map<Id, SObject> obtenerContratos(Set<Id> contractIds) {

        Map<Id, SObject> contratosPorId = new Map<Id, SObject>();

        List<String> campos = new List<String>{
            'Id',
            'Status',
            'AccountId',
            'StartDate',
            'EndDate',
            'ContractNumber'
        };

        /*
         * Esta versión corrige el error de firma.
         * Se usa Contract.SObjectType y el helper acepta SObjectType.
         */
        Schema.SObjectType contractType = Contract.SObjectType;

        agregarCampoSiExiste(contractType, campos, 'Contratista__c');
        agregarCampoSiExiste(contractType, campos, 'Beneficiario__c');
        agregarCampoSiExiste(contractType, campos, 'Institucion__c');
        agregarCampoSiExiste(contractType, campos, 'Vendedor__c');
        agregarCampoSiExiste(contractType, campos, 'Monto_Contrato__c');
        agregarCampoSiExiste(contractType, campos, 'Monto_Contrato_Vigente__c');
        agregarCampoSiExiste(contractType, campos, 'Fecha_Inicio__c');
        agregarCampoSiExiste(contractType, campos, 'Fecha_Fin__c');
        agregarCampoSiExiste(contractType, campos, 'Fecha_Fin_Vigente__c');
        agregarCampoSiExiste(contractType, campos, 'Precalificacion__c');
        agregarCampoSiExiste(contractType, campos, 'Periodo_Pago__c');
        agregarCampoSiExiste(contractType, campos, 'Prima_Anticipo__c');
        agregarCampoSiExiste(contractType, campos, 'Prima_Cumplimiento__c');
        agregarCampoSiExiste(contractType, campos, 'Prima_Vicios_Ocultos__c');

        String soql =
            'SELECT ' + String.join(campos, ',') +
            ' FROM Contract WHERE Id IN :contractIds';

        for (SObject contrato : Database.query(soql)) {
            contratosPorId.put((Id) contrato.get('Id'), contrato);
        }

        return contratosPorId;
    }

    /*
     * =====================================================================================
     * VALIDAR PRECALIFICACIÓN
     * =====================================================================================
     */
    private static Set<Id> obtenerContratosConPrecalificacionSuficiente(
        Map<Id, SObject> contratosPorId
    ) {

        Set<Id> contratosValidos = new Set<Id>();

        if (contratosPorId == null || contratosPorId.isEmpty()) {
            return contratosValidos;
        }

        Set<Id> precalificacionIds = new Set<Id>();
        Set<Id> contratistaIds = new Set<Id>();

        for (SObject contrato : contratosPorId.values()) {

            Id preId = getId(contrato, 'Precalificacion__c');
            Id contratistaId = obtenerContratista(contrato);

            if (preId != null) {
                precalificacionIds.add(preId);
            }

            if (contratistaId != null) {
                contratistaIds.add(contratistaId);
            }
        }

        if (precalificacionIds.isEmpty() && contratistaIds.isEmpty()) {
            return contratosValidos;
        }

        Set<Id> precalificacionesSuficientes = new Set<Id>();
        Set<Id> contratistasConPrecalificacionSuficiente = new Set<Id>();

        for (Precalificacion__c precalificacion : [
            SELECT Id,
                   ContratistaPrecalificacion__c,
                   Capacidad_Afianzamiento_Calc__c
            FROM Precalificacion__c
            WHERE (
                    Id IN :precalificacionIds
                    OR ContratistaPrecalificacion__c IN :contratistaIds
                  )
              AND Capacidad_Afianzamiento_Calc__c = :CAPACIDAD_SUFICIENTE
        ]) {

            precalificacionesSuficientes.add(precalificacion.Id);

            if (precalificacion.ContratistaPrecalificacion__c != null) {
                contratistasConPrecalificacionSuficiente.add(
                    precalificacion.ContratistaPrecalificacion__c
                );
            }
        }

        for (Id contratoId : contratosPorId.keySet()) {

            SObject contrato = contratosPorId.get(contratoId);

            Id preId = getId(contrato, 'Precalificacion__c');
            Id contratistaId = obtenerContratista(contrato);

            Boolean tienePrecalificacionDirecta =
                preId != null &&
                precalificacionesSuficientes.contains(preId);

            Boolean tienePrecalificacionPorContratista =
                contratistaId != null &&
                contratistasConPrecalificacionSuficiente.contains(contratistaId);

            if (tienePrecalificacionDirecta || tienePrecalificacionPorContratista) {
                contratosValidos.add(contratoId);
            }
        }

        return contratosValidos;
    }

    /*
     * =====================================================================================
     * OBTENER FIANZAS EXISTENTES
     * =====================================================================================
     */
    private static Map<Id, Set<String>> obtenerTiposFianzaExistentes(
        Set<Id> contractIds
    ) {

        Map<Id, Set<String>> mapa = new Map<Id, Set<String>>();

        if (contractIds == null || contractIds.isEmpty()) {
            return mapa;
        }

        if (!campoExiste(Tech_Fianza__c.SObjectType, 'Contrato__c')) {
            return mapa;
        }

        Set<String> tipos = new Set<String>(TIPOS_FIANZA_AUTO);

        String soql =
            'SELECT Id, Contrato__c, Tipo_de_Riesgo__c ' +
            'FROM Tech_Fianza__c ' +
            'WHERE Contrato__c IN :contractIds ' +
            'AND Tipo_de_Riesgo__c IN :tipos';

        for (SObject registro : Database.query(soql)) {

            Id contratoId = (Id) registro.get('Contrato__c');
            String tipo = (String) registro.get('Tipo_de_Riesgo__c');

            if (!mapa.containsKey(contratoId)) {
                mapa.put(contratoId, new Set<String>());
            }

            mapa.get(contratoId).add(tipo);
        }

        return mapa;
    }

    /*
     * =====================================================================================
     * HELPERS DE CONTRACT
     * =====================================================================================
     */
    private static Id obtenerContratista(SObject contrato) {

        Id contratistaId = getId(contrato, 'Contratista__c');

        if (contratistaId != null) {
            return contratistaId;
        }

        return getId(contrato, 'AccountId');
    }

    private static Id obtenerBeneficiario(SObject contrato) {

        Id beneficiarioId = getId(contrato, 'Beneficiario__c');

        if (beneficiarioId != null) {
            return beneficiarioId;
        }

        return getId(contrato, 'AccountId');
    }

    private static Id obtenerInstitucion(SObject contrato) {
        return getId(contrato, 'Institucion__c');
    }

    private static Id obtenerVendedor(SObject contrato) {
        return getId(contrato, 'Vendedor__c');
    }

    private static String obtenerPeriodoPago(SObject contrato) {
        return getString(contrato, 'Periodo_Pago__c');
    }

    private static Decimal obtenerMontoContrato(SObject contrato) {

        Decimal montoVigente = getDecimal(contrato, 'Monto_Contrato_Vigente__c');

        if (montoVigente != null && montoVigente > 0) {
            return montoVigente;
        }

        return getDecimal(contrato, 'Monto_Contrato__c');
    }

    private static Date obtenerFechaContratoInicio(SObject contrato) {

        Date fechaInicio = getDate(contrato, 'Fecha_Inicio__c');

        if (fechaInicio != null) {
            return fechaInicio;
        }

        return getDate(contrato, 'StartDate');
    }

    private static Date obtenerFechaContratoFin(SObject contrato) {

        Date fechaFinVigente = getDate(contrato, 'Fecha_Fin_Vigente__c');

        if (fechaFinVigente != null) {
            return fechaFinVigente;
        }

        Date fechaFin = getDate(contrato, 'Fecha_Fin__c');

        if (fechaFin != null) {
            return fechaFin;
        }

        return getDate(contrato, 'EndDate');
    }

    /*
     * =====================================================================================
     * HELPERS DE SCHEMA
     * =====================================================================================
     */
    private static Boolean campoExiste(
        Schema.SObjectType tipo,
        String campo
    ) {

        if (tipo == null || String.isBlank(campo)) {
            return false;
        }

        return tipo.getDescribe().fields.getMap().containsKey(campo);
    }

    /*
     * Versión para SObjectType.
     */
    private static void agregarCampoSiExiste(
        Schema.SObjectType tipo,
        List<String> campos,
        String campo
    ) {

        if (tipo == null || campos == null || String.isBlank(campo)) {
            return;
        }

        if (
            tipo.getDescribe().fields.getMap().containsKey(campo) &&
            !campos.contains(campo)
        ) {
            campos.add(campo);
        }
    }

    /*
     * Versión adicional para DescribeSObjectResult.
     * Esta versión evita el error:
     * Method does not exist or incorrect signature:
     * agregarCampoSiExiste(Schema.DescribeSObjectResult, List<String>, String)
     */
    private static void agregarCampoSiExiste(
        Schema.DescribeSObjectResult describe,
        List<String> campos,
        String campo
    ) {

        if (describe == null || campos == null || String.isBlank(campo)) {
            return;
        }

        if (
            describe.fields.getMap().containsKey(campo) &&
            !campos.contains(campo)
        ) {
            campos.add(campo);
        }
    }

    public static void setIfWritable(
        SObject registro,
        String campo,
        Object valor
    ) {

        if (registro == null || String.isBlank(campo)) {
            return;
        }

        Map<String, Schema.SObjectField> campos =
            registro.getSObjectType().getDescribe().fields.getMap();

        if (!campos.containsKey(campo)) {
            return;
        }

        Schema.DescribeFieldResult d = campos.get(campo).getDescribe();

        if (!d.isCreateable() && !d.isUpdateable()) {
            return;
        }

        registro.put(campo, valor);
    }

    /*
     * =====================================================================================
     * HELPERS DE LECTURA DINÁMICA
     * =====================================================================================
     */
    private static Object getValue(SObject registro, String campo) {

        if (registro == null || String.isBlank(campo)) {
            return null;
        }

        try {
            return registro.get(campo);
        } catch (Exception e) {
            return null;
        }
    }

    private static Id getId(SObject registro, String campo) {

        Object valor = getValue(registro, campo);

        if (valor == null) {
            return null;
        }

        try {
            return (Id) valor;
        } catch (Exception e) {
            return null;
        }
    }

    private static String getString(SObject registro, String campo) {

        Object valor = getValue(registro, campo);

        if (valor == null) {
            return null;
        }

        return String.valueOf(valor);
    }

    private static Date getDate(SObject registro, String campo) {

        Object valor = getValue(registro, campo);

        if (valor == null) {
            return null;
        }

        try {
            return (Date) valor;
        } catch (Exception e) {
            return null;
        }
    }

    private static Decimal getDecimal(SObject registro, String campo) {

        Object valor = getValue(registro, campo);

        if (valor == null) {
            return null;
        }

        if (valor instanceof Decimal) {
            return (Decimal) valor;
        }

        try {
            return Decimal.valueOf(String.valueOf(valor));
        } catch (Exception e) {
            return null;
        }
    }
}