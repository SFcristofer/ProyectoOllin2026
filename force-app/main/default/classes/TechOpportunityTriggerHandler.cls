public without sharing class TechOpportunityTriggerHandler {

    /*
     * =====================================================================================
     * CLASE: TechOpportunityTriggerHandler
     * =====================================================================================
     *
     * Objetivo:
     * - Ser el único orquestador del flujo de Opportunity.
     *
     * Funciones:
     * - Calcular Fecha_Fin_Vigencia__c.
     * - Calcular Numero_Pagos__c.
     * - Bloquear creación de fianzas desde Opportunity.
     * - Procesar Opportunity ganada para seguros.
     * - Convertir Prospecto a Account si aplica.
     * - Crear Tech_Seguro__c.
     * - Generar Plan de Pago y Recibos.
     * - Procesar renovación perdida.
     * - Procesar renovación ganada.
     *
     * Regla importante:
     * - Opportunity ya no crea Tech_Fianza__c.
     * - Fianzas nacen desde Contract.
     */

    private static Boolean enEjecucionAfter = false;
    private static Boolean enEjecucionRenovacion = false;

    private static final String ESTATUS_SEGURO_EMITIDA = 'Emitida';
    private static final String ESTATUS_SEGURO_RENOVADA = 'Renovada';

    /*
     * Picklist real detectado previamente:
     * Emitida, Vigente, Por renovar, Renovada, Vencida, Cancelada.
     */
    private static final String ESTATUS_SEGURO_RENOVACION_PERDIDA = 'Vencida';

    /*
     * =====================================================================================
     * COMPATIBILIDAD
     * =====================================================================================
     *
     * Método conservado por llamadas antiguas.
     * Internamente redirige al nuevo orquestador.
     */
    public static void generarSeguroAlGanarOportunidad(
        List<Opportunity> nuevasOportunidades,
        Map<Id, Opportunity> oportunidadesAnteriores
    ) {
        generarProductoAlGanarOportunidad(
            nuevasOportunidades,
            oportunidadesAnteriores
        );
    }

    /*
     * =====================================================================================
     * BLOQUEAR CIERRE GANADO DE FIANZAS DESDE OPPORTUNITY
     * =====================================================================================
     *
     * Regla:
     * - Si Ramo__c es Fianza/Fianzas, no se permite cerrar ganada desde Opportunity.
     * - El proceso correcto es:
     *      Contract → Precalificación → Tech_Fianza__c
     */
    public static void bloquearCierreGanadoFianzasDesdeOpportunity(
        List<Opportunity> nuevasOportunidades,
        Map<Id, Opportunity> oportunidadesAnteriores
    ) {

        if (nuevasOportunidades == null || nuevasOportunidades.isEmpty()) {
            return;
        }

        for (Opportunity opp : nuevasOportunidades) {

            if (opp == null) {
                continue;
            }

            Boolean intentaGanar = false;

            if (oportunidadesAnteriores == null) {
                intentaGanar = opp.IsWon == true;
            } else {
                Opportunity anterior = oportunidadesAnteriores.get(opp.Id);

                intentaGanar =
                    opp.IsWon == true &&
                    anterior != null &&
                    anterior.IsWon == false;
            }

            if (!intentaGanar) {
                continue;
            }

            if (esRamoFianza(opp)) {
                opp.addError(
                    'Las oportunidades de Fianza ya no se cierran como venta desde Opportunity. ' +
                    'El proceso de fianzas debe iniciar desde Contract, con precalificación, ' +
                    'emisión de fianza, plan de pago y recibos.'
                );
            }
        }
    }

    /*
     * =====================================================================================
     * ORQUESTADOR PRINCIPAL DE OPORTUNIDAD GANADA
     * =====================================================================================
     *
     * Se ejecuta en after update.
     *
     * Flujo:
     * - Identifica oportunidades que cambiaron a ganadas.
     * - Ignora oportunidades de fianza.
     * - Convierte prospecto si no tiene Account.
     * - Reconsulta Opportunity.
     * - Crea Tech_Seguro__c.
     * - Genera plan de pago y recibos.
     */
    public static void generarProductoAlGanarOportunidad(
        List<Opportunity> nuevasOportunidades,
        Map<Id, Opportunity> oportunidadesAnteriores
    ) {

        if (enEjecucionAfter) {
            return;
        }

        if (
            nuevasOportunidades == null ||
            nuevasOportunidades.isEmpty() ||
            oportunidadesAnteriores == null
        ) {
            return;
        }

        Set<Id> opportunityIdsGanadas = new Set<Id>();
        Set<Id> prospectoIdsPorConvertir = new Set<Id>();

        for (Opportunity opp : nuevasOportunidades) {

            if (opp == null) {
                continue;
            }

            Opportunity anterior = oportunidadesAnteriores.get(opp.Id);

            if (anterior == null) {
                continue;
            }

            Boolean cambioAGanada =
                opp.IsWon == true &&
                anterior.IsWon == false;

            if (!cambioAGanada) {
                continue;
            }

            /*
             * Fianzas ya no se procesan desde Opportunity.
             */
            if (esRamoFianza(opp)) {
                continue;
            }

            opportunityIdsGanadas.add(opp.Id);

            if (opp.Prospecto__c != null && opp.AccountId == null) {
                prospectoIdsPorConvertir.add(opp.Prospecto__c);
            }
        }

        if (opportunityIdsGanadas.isEmpty()) {
            return;
        }

        enEjecucionAfter = true;

        try {

            /*
             * -------------------------------------------------------------------------
             * 1. Convertir prospectos si aplica.
             * -------------------------------------------------------------------------
             */
            if (!prospectoIdsPorConvertir.isEmpty()) {
                TechProspectoConversionService.convertirProspectosACuenta(
                    new List<Id>(prospectoIdsPorConvertir)
                );

                actualizarOportunidadesConCuentaConvertida(
                    opportunityIdsGanadas
                );
            }

            /*
             * -------------------------------------------------------------------------
             * 2. Reconsultar oportunidades actualizadas.
             * -------------------------------------------------------------------------
             */
            List<Opportunity> oportunidades = consultarOportunidades(
                opportunityIdsGanadas
            );

            if (oportunidades.isEmpty()) {
                return;
            }

            /*
             * -------------------------------------------------------------------------
             * 3. Crear seguros.
             * -------------------------------------------------------------------------
             */
            Set<Id> segurosCreados = crearSegurosDesdeOportunidades(
                oportunidades
            );

            /*
             * -------------------------------------------------------------------------
             * 4. Generar planes y recibos.
             * -------------------------------------------------------------------------
             */
            if (!segurosCreados.isEmpty()) {
                TechPlanPagoService.generarPlanesYRecibosPorSeguroIds(
                    segurosCreados
                );
            }

        } finally {
            enEjecucionAfter = false;
        }
    }

    /*
     * =====================================================================================
     * ACTUALIZAR OPPORTUNITY CON ACCOUNT CONVERTIDO
     * =====================================================================================
     *
     * Si TechProspectoConversionService convierte el Lead, este método busca
     * Lead.ConvertedAccountId y actualiza Opportunity.AccountId.
     */
    private static void actualizarOportunidadesConCuentaConvertida(
        Set<Id> opportunityIds
    ) {

        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return;
        }

        List<Opportunity> oportunidades = [
            SELECT Id,
                   AccountId,
                   Prospecto__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
              AND AccountId = null
              AND Prospecto__c != null
        ];

        if (oportunidades.isEmpty()) {
            return;
        }

        Set<Id> leadIds = new Set<Id>();

        for (Opportunity opp : oportunidades) {
            leadIds.add(opp.Prospecto__c);
        }

        Map<Id, Lead> leadsPorId = new Map<Id, Lead>([
            SELECT Id,
                   IsConverted,
                   ConvertedAccountId
            FROM Lead
            WHERE Id IN :leadIds
        ]);

        List<Opportunity> oportunidadesPorActualizar =
            new List<Opportunity>();

        for (Opportunity opp : oportunidades) {

            Lead lead = leadsPorId.get(opp.Prospecto__c);

            if (
                lead == null ||
                lead.IsConverted != true ||
                lead.ConvertedAccountId == null
            ) {
                continue;
            }

            oportunidadesPorActualizar.add(
                new Opportunity(
                    Id = opp.Id,
                    AccountId = lead.ConvertedAccountId
                )
            );
        }

        if (!oportunidadesPorActualizar.isEmpty()) {
            update oportunidadesPorActualizar;
        }
    }

    /*
     * =====================================================================================
     * CONSULTAR OPPORTUNITIES
     * =====================================================================================
     */
    private static List<Opportunity> consultarOportunidades(
        Set<Id> opportunityIds
    ) {

        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return new List<Opportunity>();
        }

        return [
            SELECT Id,
                   Name,
                   AccountId,
                   Prospecto__c,
                   IsWon,
                   IsClosed,
                   Amount,
                   Vendedor_A__c,
                   Producto__c,
                   Metodo_Pago__c,
                   Periodo_Pago__c,
                   Numero_Pagos__c,
                   Fecha_Inicio_Vigencia__c,
                   Fecha_Fin_Vigencia__c,
                   Vigencia__c,
                   Ramo__c,
                   Institucion__c,
                   Subproducto__c,
                   Poliza_Renovar__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ];
    }

    /*
     * =====================================================================================
     * CREAR SEGUROS DESDE OPPORTUNITIES
     * =====================================================================================
     */
    private static Set<Id> crearSegurosDesdeOportunidades(
        List<Opportunity> oportunidades
    ) {

        Set<Id> segurosCreados = new Set<Id>();

        if (oportunidades == null || oportunidades.isEmpty()) {
            return segurosCreados;
        }

        Set<Id> opportunityIds = new Set<Id>();

        for (Opportunity opp : oportunidades) {

            if (opp == null || opp.Id == null) {
                continue;
            }

            if (esRamoFianza(opp)) {
                continue;
            }

            opportunityIds.add(opp.Id);
        }

        if (opportunityIds.isEmpty()) {
            return segurosCreados;
        }

        Map<Id, Tech_Seguro__c> segurosExistentesPorOpportunity =
            new Map<Id, Tech_Seguro__c>();

        for (Tech_Seguro__c seguroExistente : [
            SELECT Id,
                   Oportunidad__c
            FROM Tech_Seguro__c
            WHERE Oportunidad__c IN :opportunityIds
        ]) {
            segurosExistentesPorOpportunity.put(
                seguroExistente.Oportunidad__c,
                seguroExistente
            );
        }

        List<Tech_Seguro__c> segurosPorInsertar =
            new List<Tech_Seguro__c>();

        Set<Id> polizasOrigenRenovadas = new Set<Id>();

        for (Opportunity opp : oportunidades) {

            if (opp == null || opp.Id == null) {
                continue;
            }

            if (esRamoFianza(opp)) {
                continue;
            }

            if (segurosExistentesPorOpportunity.containsKey(opp.Id)) {
                continue;
            }

            if (opp.AccountId == null) {
                continue;
            }

            if (opp.Amount == null || opp.Amount <= 0) {
                continue;
            }

            Tech_Seguro__c seguro = new Tech_Seguro__c();

            putIfExists(seguro, 'Name', generarNombreSeguro(opp));
            putIfExists(seguro, 'Oportunidad__c', opp.Id);
            putIfExists(seguro, 'Cliente__c', opp.AccountId);

            /*
             * Campo real del modelo Tech:
             * Tech_Seguro__c.Vendedor_A__c
             */
            putIfExists(seguro, 'Vendedor_A__c', opp.Vendedor_A__c);

            putIfExists(seguro, 'Producto__c', opp.Producto__c);
            putIfExists(seguro, 'Forma_pago__c', opp.Metodo_Pago__c);
            putIfExists(seguro, 'Frecuencia_de_pago__c', opp.Periodo_Pago__c);
            putIfExists(seguro, 'Vigencia__c', opp.Vigencia__c);
            putIfExists(seguro, 'Ramo__c', opp.Ramo__c);
            putIfExists(seguro, 'Aseguradora__c', opp.Institucion__c);
            putIfExists(seguro, 'Subproducto__c', opp.Subproducto__c);
            putIfExists(seguro, 'Poliza_renovada__c', opp.Poliza_Renovar__c);
            putIfExists(seguro, 'Inicio_del_seguro__c', opp.Fecha_Inicio_Vigencia__c);
            putIfExists(seguro, 'Fin_del_seguro__c', opp.Fecha_Fin_Vigencia__c);
            putIfExists(seguro, 'Prima_neta__c', opp.Amount);
            putIfExists(seguro, 'Estatus__c', ESTATUS_SEGURO_EMITIDA);

            segurosPorInsertar.add(seguro);

            if (opp.Poliza_Renovar__c != null) {
                polizasOrigenRenovadas.add(opp.Poliza_Renovar__c);
            }
        }

        if (!segurosPorInsertar.isEmpty()) {
            insert segurosPorInsertar;

            for (Tech_Seguro__c seguro : segurosPorInsertar) {
                segurosCreados.add(seguro.Id);
            }
        }

        if (!polizasOrigenRenovadas.isEmpty()) {
            marcarPolizasOrigenComoRenovadas(
                polizasOrigenRenovadas
            );
        }

        return segurosCreados;
    }

    /*
     * =====================================================================================
     * PROCESAR RENOVACIÓN PERDIDA
     * =====================================================================================
     *
     * Regla:
     * - Si una Opportunity de renovación se cierra perdida,
     *   y tiene Poliza_Renovar__c, se actualiza la póliza origen.
     *
     * Valor usado:
     * - Vencida
     *
     * Nota:
     * - No se usa "No Renovada" porque no existe en el picklist real detectado.
     */
    public static void procesarRenovacionPerdida(
        List<Opportunity> nuevasOportunidades,
        Map<Id, Opportunity> oportunidadesAnteriores
    ) {

        if (enEjecucionRenovacion) {
            return;
        }

        if (
            nuevasOportunidades == null ||
            nuevasOportunidades.isEmpty() ||
            oportunidadesAnteriores == null
        ) {
            return;
        }

        Set<Id> seguroIds = new Set<Id>();
        Set<Id> opportunityIdsPerdidas = new Set<Id>();

        for (Opportunity opp : nuevasOportunidades) {

            if (opp == null) {
                continue;
            }

            Opportunity anterior = oportunidadesAnteriores.get(opp.Id);

            if (anterior == null) {
                continue;
            }

            Boolean cambioACerradaPerdida =
                opp.IsClosed == true &&
                opp.IsWon == false &&
                anterior.IsClosed == false;

            if (
                cambioACerradaPerdida &&
                opp.Poliza_Renovar__c != null
            ) {
                seguroIds.add(opp.Poliza_Renovar__c);
                opportunityIdsPerdidas.add(opp.Id);
            }
        }

        if (seguroIds.isEmpty()) {
            return;
        }

        enEjecucionRenovacion = true;

        try {

            Set<Id> segurosConOtraRenovacionActiva = new Set<Id>();

            for (Opportunity oppRelacionada : [
                SELECT Id,
                       Poliza_Renovar__c,
                       IsClosed,
                       IsWon
                FROM Opportunity
                WHERE Poliza_Renovar__c IN :seguroIds
                  AND Id NOT IN :opportunityIdsPerdidas
                  AND (
                        IsClosed = false
                        OR IsWon = true
                      )
            ]) {
                segurosConOtraRenovacionActiva.add(
                    oppRelacionada.Poliza_Renovar__c
                );
            }

            List<Tech_Seguro__c> segurosPorActualizar =
                new List<Tech_Seguro__c>();

            for (Tech_Seguro__c seguro : [
                SELECT Id,
                       Estatus__c
                FROM Tech_Seguro__c
                WHERE Id IN :seguroIds
            ]) {

                if (segurosConOtraRenovacionActiva.contains(seguro.Id)) {
                    continue;
                }

                if (seguro.Estatus__c == ESTATUS_SEGURO_RENOVACION_PERDIDA) {
                    continue;
                }

                seguro.Estatus__c = ESTATUS_SEGURO_RENOVACION_PERDIDA;
                segurosPorActualizar.add(seguro);
            }

            if (!segurosPorActualizar.isEmpty()) {
                update segurosPorActualizar;
            }

        } finally {
            enEjecucionRenovacion = false;
        }
    }

    /*
     * =====================================================================================
     * MARCAR PÓLIZA ORIGEN COMO RENOVADA
     * =====================================================================================
     */
    private static void marcarPolizasOrigenComoRenovadas(
        Set<Id> seguroIdsOrigen
    ) {

        if (seguroIdsOrigen == null || seguroIdsOrigen.isEmpty()) {
            return;
        }

        List<Tech_Seguro__c> segurosPorActualizar =
            new List<Tech_Seguro__c>();

        for (Tech_Seguro__c seguro : [
            SELECT Id,
                   Estatus__c
            FROM Tech_Seguro__c
            WHERE Id IN :seguroIdsOrigen
        ]) {

            if (seguro.Estatus__c == ESTATUS_SEGURO_RENOVADA) {
                continue;
            }

            seguro.Estatus__c = ESTATUS_SEGURO_RENOVADA;
            segurosPorActualizar.add(seguro);
        }

        if (!segurosPorActualizar.isEmpty()) {
            update segurosPorActualizar;
        }
    }

    /*
     * =====================================================================================
     * CALCULAR FECHA FIN DE VIGENCIA
     * =====================================================================================
     */
    public static void calcularFechaFinVigencia(
        List<Opportunity> registros
    ) {

        if (registros == null || registros.isEmpty()) {
            return;
        }

        for (Opportunity registro : registros) {

            if (
                registro.Fecha_Inicio_Vigencia__c != null &&
                registro.Vigencia__c != null &&
                registro.Vigencia__c > 0
            ) {
                registro.Fecha_Fin_Vigencia__c =
                    registro.Fecha_Inicio_Vigencia__c.addMonths(
                        registro.Vigencia__c.intValue()
                    );
            }
        }
    }

    /*
     * =====================================================================================
     * CALCULAR NÚMERO DE PAGOS
     * =====================================================================================
     */
    public static void calcularNumeroDePagos(
        List<Opportunity> registros
    ) {

        if (registros == null || registros.isEmpty()) {
            return;
        }

        for (Opportunity registro : registros) {

            if (
                registro.Vigencia__c == null ||
                String.isBlank(registro.Periodo_Pago__c)
            ) {
                registro.Numero_Pagos__c = null;
                continue;
            }

            Integer vigenciaMeses = registro.Vigencia__c.intValue();

            if (vigenciaMeses <= 0) {
                registro.Numero_Pagos__c = null;
                continue;
            }

            if (registro.Periodo_Pago__c == 'Contado') {
                registro.Numero_Pagos__c = 1;
                continue;
            }

            Integer mesesPorPago =
                obtenerMesesPorPeriodo(registro.Periodo_Pago__c);

            if (mesesPorPago == null || mesesPorPago <= 0) {
                registro.Numero_Pagos__c = null;
                continue;
            }

            Decimal numeroPagos =
                Decimal.valueOf(vigenciaMeses) /
                Decimal.valueOf(mesesPorPago);

            registro.Numero_Pagos__c =
                numeroPagos.setScale(
                    0,
                    System.RoundingMode.CEILING
                );
        }
    }

    /*
     * Alias de compatibilidad.
     */
    public static void calcularNumeroPagos(
        List<Opportunity> registros
    ) {
        calcularNumeroDePagos(registros);
    }

    /*
     * =====================================================================================
     * UTILIDADES
     * =====================================================================================
     */
    private static Integer obtenerMesesPorPeriodo(String periodoPago) {

        if (String.isBlank(periodoPago)) {
            return null;
        }

        if (periodoPago == 'Mensual') {
            return 1;
        }

        if (periodoPago == 'Bimestral') {
            return 2;
        }

        if (periodoPago == 'Trimestral') {
            return 3;
        }

        if (periodoPago == 'Semestral') {
            return 6;
        }

        if (periodoPago == 'Anual') {
            return 12;
        }

        if (periodoPago == 'Contado') {
            return 0;
        }

        return null;
    }

    private static Boolean esRamoFianza(Opportunity opp) {

        if (opp == null) {
            return false;
        }

        String ramo = normalizar(opp.Ramo__c);

        return
            ramo == 'FIANZA' ||
            ramo == 'FIANZAS';
    }

    private static String normalizar(String valor) {

        if (String.isBlank(valor)) {
            return '';
        }

        return valor.trim().toUpperCase();
    }

    private static String generarNombreSeguro(Opportunity opp) {

        String nombreBase = String.isBlank(opp.Name)
            ? 'Seguro'
            : opp.Name;

        return 'Seguro - ' + nombreBase;
    }

    private static void putIfExists(
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

        Schema.DescribeFieldResult d =
            campos.get(campo).getDescribe();

        if (!d.isCreateable() && !d.isUpdateable()) {
            return;
        }

        registro.put(campo, valor);
    }
}