public with sharing class TechContratoController {
    @AuraEnabled(cacheable=true)
    public static List<TechContratoWrapper> getContratosList() {
        List<TechContratoWrapper> wrappers = new List<TechContratoWrapper>();
        for (Contrato__c c : TechContratoSelector.getRecentContratos()) {
            wrappers.add(new TechContratoWrapper(c));
        }
        return wrappers;
    }
}
