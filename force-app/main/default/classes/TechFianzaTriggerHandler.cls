public without sharing class TechFianzaTriggerHandler {

    /*
     * =====================================================================================
     * CLASE: TechFianzaTriggerHandler
     * =====================================================================================
     *
     * Objetivo:
     * - Validar que toda fianza nazca desde Contract.
     * - Bloquear nuevas fianzas desde Opportunity.
     * - Validar precalificación suficiente.
     * - Heredar datos del contrato.
     * - Generar plan y recibos para fianzas manuales.
     *
     * Regla:
     * - El flujo nuevo de fianzas es:
     *      Contract → Precalificación → Tech_Fianza__c → Plan de Pago → Recibos.
     */

    private static Boolean enEjecucionAfter = false;

    private static final String CAPACIDAD_SUFICIENTE = 'Capacidad Suficiente';
    private static final String ESTATUS_FIANZA_EMITIDA = 'Emitida';

    /*
     * =====================================================================================
     * BEFORE INSERT / BEFORE UPDATE
     * =====================================================================================
     */
    public static void beforeSave(
        List<Tech_Fianza__c> nuevasFianzas,
        Map<Id, Tech_Fianza__c> fianzasAnteriores
    ) {

        if (nuevasFianzas == null || nuevasFianzas.isEmpty()) {
            return;
        }

        Set<Id> contractIds = new Set<Id>();

        /*
         * -------------------------------------------------------------------------
         * 1. Validaciones iniciales
         * -------------------------------------------------------------------------
         */
        for (Tech_Fianza__c fianza : nuevasFianzas) {

            if (fianza == null) {
                continue;
            }

            Id contratoId = getId(fianza, 'Contrato__c');

            if (contratoId == null) {
                fianza.addError(
                    'La fianza debe estar relacionada con un contrato.'
                );
                continue;
            }

            /*
             * Las nuevas fianzas ya no deben nacer desde Opportunity.
             * Se permite que el campo exista solo como histórico.
             */
            if (fianza.Oportunidad__c != null) {
                fianza.addError(
                    'El nuevo proceso de fianzas no permite crear fianzas desde Opportunity. ' +
                    'La fianza debe nacer desde Contract.'
                );
                continue;
            }

            /*
             * No permitir cambiar el contrato de una fianza existente.
             */
            if (
                fianzasAnteriores != null &&
                fianza.Id != null &&
                fianzasAnteriores.containsKey(fianza.Id)
            ) {
                Tech_Fianza__c anterior = fianzasAnteriores.get(fianza.Id);

                Id contratoAnteriorId = getId(anterior, 'Contrato__c');

                if (
                    contratoAnteriorId != null &&
                    contratoAnteriorId != contratoId
                ) {
                    fianza.addError(
                        'No se permite cambiar el contrato de una fianza existente.'
                    );
                    continue;
                }
            }

            contractIds.add(contratoId);
        }

        if (contractIds.isEmpty()) {
            return;
        }

        /*
         * -------------------------------------------------------------------------
         * 2. Consultar contratos y validar precalificación
         * -------------------------------------------------------------------------
         */
        Map<Id, SObject> contratosPorId = obtenerContratos(contractIds);

        Set<Id> contratosConPrecalificacion =
            obtenerContratosConPrecalificacionSuficiente(contratosPorId);

        /*
         * -------------------------------------------------------------------------
         * 3. Heredar datos y validar datos financieros
         * -------------------------------------------------------------------------
         */
        for (Tech_Fianza__c fianza : nuevasFianzas) {

            if (fianza == null) {
                continue;
            }

            Id contratoId = getId(fianza, 'Contrato__c');

            if (contratoId == null) {
                continue;
            }

            if (!contratosPorId.containsKey(contratoId)) {
                fianza.addError(
                    'No fue posible localizar el contrato relacionado.'
                );
                continue;
            }

            if (!contratosConPrecalificacion.contains(contratoId)) {
                fianza.addError(
                    'No se puede emitir la fianza. El contrato debe contar con una ' +
                    'precalificación con Capacidad Afianzamiento Calc = "Capacidad Suficiente".'
                );
                continue;
            }

            heredarDatosContrato(
                fianza,
                contratosPorId.get(contratoId)
            );

            validarDatosFinancieros(fianza);
        }
    }

    /*
     * =====================================================================================
     * AFTER INSERT / AFTER UPDATE
     * =====================================================================================
     */
    public static void afterSave(
        List<Tech_Fianza__c> fianzas,
        Map<Id, Tech_Fianza__c> fianzasAnteriores
    ) {

        if (enEjecucionAfter) {
            return;
        }

        /*
         * Si la fianza fue creada desde TechFianzaContratoService,
         * el servicio genera los planes para evitar duplicidad.
         */
        if (TechFianzaContratoService.estaEjecutandoCreacionDesdeContrato()) {
            return;
        }

        if (fianzas == null || fianzas.isEmpty()) {
            return;
        }

        enEjecucionAfter = true;

        try {

            Set<Id> fianzaIdsParaPlan = new Set<Id>();

            for (Tech_Fianza__c fianza : fianzas) {

                if (fianza == null || fianza.Id == null) {
                    continue;
                }

                if (fianza.Prima_neta__c == null || fianza.Prima_neta__c <= 0) {
                    continue;
                }

                fianzaIdsParaPlan.add(fianza.Id);
            }

            if (!fianzaIdsParaPlan.isEmpty()) {
                TechPlanPagoService.generarPlanesYRecibosPorFianzaIds(
                    fianzaIdsParaPlan
                );
            }

        } finally {
            enEjecucionAfter = false;
        }
    }

    /*
     * =====================================================================================
     * HERENCIA DE DATOS DESDE CONTRACT
     * =====================================================================================
     */
    private static void heredarDatosContrato(
        Tech_Fianza__c fianza,
        SObject contrato
    ) {

        if (fianza == null || contrato == null) {
            return;
        }

        Id contratistaId = getId(contrato, 'Contratista__c');

        if (contratistaId == null) {
            contratistaId = getId(contrato, 'AccountId');
        }

        Id beneficiarioId = getId(contrato, 'Beneficiario__c');

        if (beneficiarioId == null) {
            beneficiarioId = getId(contrato, 'AccountId');
        }

        if (fianza.Contratistas__c == null) {
            fianza.Contratistas__c = contratistaId;
        }

        if (fianza.Beneficiarios__c == null) {
            fianza.Beneficiarios__c = beneficiarioId;
        }

        // Afianzadoras__c es lookup a Account; Institucion__c del contrato es objeto custom incompatible.
        // La institución se hereda vía Institucion__c (mismo tipo) — no asignar aquí.

        if (fianza.Vendedor__c == null) {
            fianza.Vendedor__c = getId(contrato, 'Vendedor__c');
        }

        if (String.isBlank(fianza.Periodo_Pago__c)) {
            fianza.Periodo_Pago__c = getString(contrato, 'Periodo_Pago__c');
        }

        if (String.isBlank(fianza.Periodo_Pago__c)) {
            fianza.Periodo_Pago__c = 'Contado';
        }

        if (fianza.Fecha_de_Emision__c == null) {

            Date fechaInicio = getDate(contrato, 'Fecha_Inicio__c');

            if (fechaInicio == null) {
                fechaInicio = getDate(contrato, 'StartDate');
            }

            fianza.Fecha_de_Emision__c = fechaInicio;
        }

        if (fianza.Fecha_de_Vencimiento__c == null) {

            Date fechaFin = getDate(contrato, 'Fecha_Fin_Vigente__c');

            if (fechaFin == null) {
                fechaFin = getDate(contrato, 'Fecha_Fin__c');
            }

            if (fechaFin == null) {
                fechaFin = getDate(contrato, 'EndDate');
            }

            fianza.Fecha_de_Vencimiento__c = fechaFin;
        }

        if (fianza.Fecha_Vencimiento_Vigente__c == null) {
            fianza.Fecha_Vencimiento_Vigente__c =
                fianza.Fecha_de_Vencimiento__c;
        }

        if (String.isBlank(fianza.Estatus__c)) {
            fianza.Estatus__c = ESTATUS_FIANZA_EMITIDA;
        }
    }

    /*
     * =====================================================================================
     * VALIDACIONES FINANCIERAS Y DE VIGENCIA
     * =====================================================================================
     */
    private static void validarDatosFinancieros(Tech_Fianza__c fianza) {

        if (fianza == null) {
            return;
        }

        if (fianza.Monto_Afianzado__c == null || fianza.Monto_Afianzado__c <= 0) {
            fianza.addError(
                'La fianza debe tener Monto Afianzado mayor a cero.'
            );
        }

        if (fianza.Prima_neta__c == null || fianza.Prima_neta__c <= 0) {
            fianza.addError(
                'La fianza debe tener Prima Neta mayor a cero.'
            );
        }

        if (fianza.Fecha_de_Emision__c == null) {
            fianza.addError(
                'La fianza debe tener Fecha de Emisión.'
            );
        }

        if (fianza.Fecha_de_Vencimiento__c == null) {
            fianza.addError(
                'La fianza debe tener Fecha de Vencimiento.'
            );
        }

        if (
            fianza.Fecha_de_Emision__c != null &&
            fianza.Fecha_de_Vencimiento__c != null &&
            fianza.Fecha_de_Vencimiento__c <= fianza.Fecha_de_Emision__c
        ) {
            fianza.addError(
                'La Fecha de Vencimiento debe ser mayor que la Fecha de Emisión.'
            );
        }
    }

    /*
     * =====================================================================================
     * CONSULTA DE CONTRACT
     * =====================================================================================
     */
    private static Map<Id, SObject> obtenerContratos(Set<Id> contractIds) {

        Map<Id, SObject> contratosPorId = new Map<Id, SObject>();

        if (contractIds == null || contractIds.isEmpty()) {
            return contratosPorId;
        }

        List<String> campos = new List<String>{
            'Id',
            'AccountId',
            'StartDate',
            'EndDate',
            'Status',
            'ContractNumber'
        };

        /*
         * Corrección principal:
         * Usamos DescribeSObjectResult y el helper ahora sí acepta este tipo.
         */
        Schema.DescribeSObjectResult contractDescribe =
            Contract.SObjectType.getDescribe();

        agregarCampoSiExiste(contractDescribe, campos, 'Contratista__c');
        agregarCampoSiExiste(contractDescribe, campos, 'Beneficiario__c');
        agregarCampoSiExiste(contractDescribe, campos, 'Institucion__c');
        agregarCampoSiExiste(contractDescribe, campos, 'Vendedor__c');
        agregarCampoSiExiste(contractDescribe, campos, 'Fecha_Inicio__c');
        agregarCampoSiExiste(contractDescribe, campos, 'Fecha_Fin__c');
        agregarCampoSiExiste(contractDescribe, campos, 'Fecha_Fin_Vigente__c');
        agregarCampoSiExiste(contractDescribe, campos, 'Precalificacion__c');
        agregarCampoSiExiste(contractDescribe, campos, 'Periodo_Pago__c');

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
     * VALIDACIÓN DE PRECALIFICACIÓN
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

            if (preId != null) {
                precalificacionIds.add(preId);
            }

            Id contratistaId = getId(contrato, 'Contratista__c');

            if (contratistaId == null) {
                contratistaId = getId(contrato, 'AccountId');
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

            Id contratistaId = getId(contrato, 'Contratista__c');

            if (contratistaId == null) {
                contratistaId = getId(contrato, 'AccountId');
            }

            Boolean validoPorPrecalificacion =
                preId != null &&
                precalificacionesSuficientes.contains(preId);

            Boolean validoPorContratista =
                contratistaId != null &&
                contratistasConPrecalificacionSuficiente.contains(contratistaId);

            if (validoPorPrecalificacion || validoPorContratista) {
                contratosValidos.add(contratoId);
            }
        }

        return contratosValidos;
    }

    /*
     * =====================================================================================
     * HELPERS DE SCHEMA
     * =====================================================================================
     */

    /*
     * Versión para Schema.SObjectType.
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
     * Versión para Schema.DescribeSObjectResult.
     * Esta es la corrección del error de compilación.
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

    private static Boolean campoExiste(
        Schema.SObjectType tipo,
        String campo
    ) {

        if (tipo == null || String.isBlank(campo)) {
            return false;
        }

        return tipo.getDescribe().fields.getMap().containsKey(campo);
    }

    private static Boolean campoExiste(
        Schema.DescribeSObjectResult describe,
        String campo
    ) {

        if (describe == null || String.isBlank(campo)) {
            return false;
        }

        return describe.fields.getMap().containsKey(campo);
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
}