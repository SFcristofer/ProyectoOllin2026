public with sharing class TechReciboCobroController {
    @AuraEnabled(cacheable=true)
    public static List<TechReciboCobroWrapper> getRecibosList() {
        List<TechReciboCobroWrapper> result = new List<TechReciboCobroWrapper>();
        for (Tech_Recibo_Pago__c r : TechReciboCobroSelector.getRecentRecibos()) {
            result.add(new TechReciboCobroWrapper(r));
        }
        return result;
    }
}