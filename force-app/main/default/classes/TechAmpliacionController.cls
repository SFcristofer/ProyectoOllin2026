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
    public static List<Map<String,String>> searchFianzasForEndoso(String term) {
        String q = '%' + String.escapeSingleQuotes(term) + '%';
        List<Map<String,String>> results = new List<Map<String,String>>();
        for (Tech_Fianza__c f : [SELECT Id, Name, Estatus__c, Monto_Afianzado__c
                                  FROM Tech_Fianza__c WHERE Name LIKE :q ORDER BY Name LIMIT 10]) {
            String sub = '';
            if (f.Estatus__c         != null) sub += f.Estatus__c;
            if (f.Monto_Afianzado__c != null) sub += (sub.length() > 0 ? ' · ' : '') + '$' + f.Monto_Afianzado__c.format();
            results.add(new Map<String,String>{ 'id' => f.Id, 'name' => f.Name, 'sub' => sub });
        }
        return results;
    }

    @AuraEnabled
    public static void setFianzaOnEndoso(String endosoId, String fianzaId) {
        try {
            update new Tech_Endoso__c(Id = (Id)endosoId, Fianza__c = (Id)fianzaId);
        } catch (Exception e) {
            throw new AuraHandledException('Error al vincular fianza: ' + e.getMessage());
        }
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