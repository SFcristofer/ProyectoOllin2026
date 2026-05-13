public without sharing class TechOpportunityProspectoGanadoHandler {

    /*
     * =====================================================================================
     * CLASE: TechOpportunityProspectoGanadoHandler
     * =====================================================================================
     *
     * Estado:
     * - Clase conservada por compatibilidad.
     *
     * Regla:
     * - La lógica oficial de prospecto ganado vive en:
     *      TechOpportunityTriggerHandler.generarProductoAlGanarOportunidad(...)
     *
     * Motivo:
     * - Evitar doble conversión de prospecto.
     * - Evitar doble creación de seguro.
     * - Evitar procesamiento incorrecto de fianzas desde Opportunity.
     */

    public static void procesar(
        List<Opportunity> nuevasOportunidades,
        Map<Id, Opportunity> oportunidadesAnteriores
    ) {
        TechOpportunityTriggerHandler.generarProductoAlGanarOportunidad(
            nuevasOportunidades,
            oportunidadesAnteriores
        );
    }
}