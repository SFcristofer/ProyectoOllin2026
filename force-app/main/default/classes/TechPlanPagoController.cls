public with sharing class TechPlanPagoController {
    @AuraEnabled(cacheable=true)
    public static List<TechPlanPagoWrapper> getPlanPagoList() {
        List<TechPlanPagoWrapper> result = new List<TechPlanPagoWrapper>();
        for (Tech_Plan_de_Pago__c p : TechPlanPagoSelector.getRecentPlanes()) {
            result.add(new TechPlanPagoWrapper(p));
        }
        return result;
    }
}