trigger TechOpportunityTrigger on Opportunity (
    before insert,
    before update,
    after update
) {

    /*
     * =====================================================================================
     * BEFORE INSERT / BEFORE UPDATE
     * =====================================================================================
     *
     * Lógicas actuales:
     * - Calcular fecha fin de vigencia.
     * - Calcular número de pagos.
     */
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {

        TechOpportunityTriggerHandler.calcularFechaFinVigencia(Trigger.new);

        TechOpportunityTriggerHandler.calcularNumeroPagos(Trigger.new);
    }

    /*
     * =====================================================================================
     * AFTER UPDATE
     * =====================================================================================
     *
     * Lógicas:
     * - Procesar oportunidad de renovación perdida.
     * - Procesar prospecto ganado.
     * - Crear seguro/fianza al ganar oportunidad.
     */
    if (Trigger.isAfter && Trigger.isUpdate) {

        /*
         * Nueva lógica:
         * Si la Opportunity de renovación se marca como perdida,
         * actualiza la póliza origen a "No Renovada".
         */
        TechOpportunityRenovacionHandler.procesarRenovacionPerdida(
            Trigger.new,
            Trigger.oldMap
        );

        /*
         * Lógica existente:
         * Convierte prospecto a cuenta cuando aplica.
         */
        TechOpportunityProspectoGanadoHandler.procesar(
            Trigger.new,
            Trigger.oldMap
        );

        /*
         * Lógica existente:
         * Crea seguro/fianza cuando la oportunidad se marca como ganada.
         */
        TechOpportunityTriggerHandler.generarProductoAlGanarOportunidad(
            Trigger.new,
            Trigger.oldMap
        );
    }
}