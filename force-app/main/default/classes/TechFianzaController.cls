public with sharing class TechFianzaController {
    @AuraEnabled(cacheable=true)
    public static List<TechFianzaWrapper> getFianzasList() {
        List<TechFianzaWrapper> wrappers = new List<TechFianzaWrapper>();
        for (Fianza__c f : TechFianzaSelector.getRecentFianzas()) {
            wrappers.add(new TechFianzaWrapper(f));
        }
        return wrappers;
    }
}
