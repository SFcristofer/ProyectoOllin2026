public with sharing class TechComisionController {
    @AuraEnabled(cacheable=true)
    public static List<TechComisionWrapper> getComisionesList() {
        List<TechComisionWrapper> result = new List<TechComisionWrapper>();
        for (Tech_Comision__c c : TechComisionSelector.getRecentComisiones()) {
            result.add(new TechComisionWrapper(c));
        }
        return result;
    }
}