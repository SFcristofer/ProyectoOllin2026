public with sharing class TechProyectoController {
    @AuraEnabled(cacheable=true)
    public static List<TechProyectoWrapper> getProyectosList() {
        List<TechProyectoWrapper> wrappers = new List<TechProyectoWrapper>();
        for (Proyecto__c p : TechProyectoSelector.getRecentProyectos()) {
            wrappers.add(new TechProyectoWrapper(p));
        }
        return wrappers;
    }
}
