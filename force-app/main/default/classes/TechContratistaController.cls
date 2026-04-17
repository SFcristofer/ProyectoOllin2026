public with sharing class TechContratistaController {
    @AuraEnabled(cacheable=true)
    public static List<TechContratistaWrapper> getContratistasList() {
        List<TechContratistaWrapper> wrappers = new List<TechContratistaWrapper>();
        for (Contratista__c c : TechContratistaSelector.getRecentContratistas()) {
            wrappers.add(new TechContratistaWrapper(c));
        }
        return wrappers;
    }
}
