public with sharing class TechAmpliacionController {
    @AuraEnabled(cacheable=true)
    public static List<TechAmpliacionWrapper> getAmpliacionesList() {
        List<TechAmpliacionWrapper> wrappers = new List<TechAmpliacionWrapper>();
        for (Tech_Endoso__c e : TechAmpliacionSelector.getRecentAmpliaciones()) {
            wrappers.add(new TechAmpliacionWrapper(e));
        }
        return wrappers;
    }

    @AuraEnabled
    public static String saveAmpliacionWithRelations(Tech_Endoso__c ampliacion, Map<String, List<String>> relationsMap) {
        try {
            upsert ampliacion;
            if (relationsMap != null) {
                Tech_Endoso__c toUpdate = new Tech_Endoso__c(Id = ampliacion.Id);
                Boolean needsUpdate = false;
                for (String tipo : relationsMap.keySet()) {
                    List<String> ids = relationsMap.get(tipo);
                    if (ids == null || ids.isEmpty()) continue;
                    if (tipo == 'Fianza') { toUpdate.Fianza__c = (Id)ids[0]; needsUpdate = true; }
                }
                if (needsUpdate) update toUpdate;
            }
            return ampliacion.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar ampliación: ' + e.getMessage());
        }
    }
}