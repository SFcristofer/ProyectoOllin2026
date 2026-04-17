public with sharing class TechAmpliacionController {
    @AuraEnabled(cacheable=true)
    public static List<TechAmpliacionWrapper> getAmpliacionesList() {
        List<TechAmpliacionWrapper> wrappers = new List<TechAmpliacionWrapper>();
        for (Endoso__c e : TechAmpliacionSelector.getRecentAmpliaciones()) {
            wrappers.add(new TechAmpliacionWrapper(e));
        }
        return wrappers;
    }
}
