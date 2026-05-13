public without sharing class TechOpportunityRenovacionHandler {

    /*
     * =====================================================================================
     * CLASE: TechOpportunityRenovacionHandler
     * =====================================================================================
     *
     * Estado:
     * - Clase conservada por compatibilidad.
     *
     * Regla:
     * - La lógica oficial de renovación perdida vive en:
     *      TechOpportunityTriggerHandler.procesarRenovacionPerdida(...)
     *
     * Motivo:
     * - Evitar duplicidad de lógica.
     * - Evitar uso de estatus no existentes como "No Renovada".
     */

    public static void procesarRenovacionPerdida(
        List<Opportunity> nuevasOportunidades,
        Map<Id, Opportunity> oportunidadesAnteriores
    ) {
        TechOpportunityTriggerHandler.procesarRenovacionPerdida(
            nuevasOportunidades,
            oportunidadesAnteriores
        );
    }
}