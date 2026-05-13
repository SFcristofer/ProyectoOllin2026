public with sharing class TechPrecalificacionController {

    @AuraEnabled(cacheable=true)
    public static Map<String, List<Map<String,String>>> getPrecalificacionesByContratistaMap() {
        Map<String, List<Map<String,String>>> result = new Map<String, List<Map<String,String>>>();
        for (Precalificacion__c p : [
            SELECT Id, Name, Contratista__c
            FROM Precalificacion__c
            WHERE Contratista__c != null
            ORDER BY CreatedDate DESC
        ]) {
            String key = (String)p.Contratista__c;
            if (!result.containsKey(key)) result.put(key, new List<Map<String,String>>());
            result.get(key).add(new Map<String,String>{ 'id' => p.Id, 'name' => p.Name });
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<TechPrecalificacionWrapper> getPrecalificacionList() {
        List<TechPrecalificacionWrapper> wrappers = new List<TechPrecalificacionWrapper>();
        for (Precalificacion__c p : TechPrecalificacionSelector.getRecent()) {
            wrappers.add(new TechPrecalificacionWrapper(p));
        }
        return wrappers;
    }

    @AuraEnabled(cacheable=false)
    public static List<TechPrecalificacionWrapper> getPrecalificacionesByContratista(Id contratistaId) {
        List<Precalificacion__c> records = TechPrecalificacionSelector.getByContratista(contratistaId);
        List<TechPrecalificacionWrapper> wrappers = new List<TechPrecalificacionWrapper>();
        for (Precalificacion__c p : records) {
            wrappers.add(new TechPrecalificacionWrapper(p));
        }
        return wrappers;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean tienePrecalificacionProspecto(Id prospectoId) {
        return [SELECT COUNT() FROM Precalificacion__c WHERE Prospecto__c = :prospectoId] > 0;
    }

    @AuraEnabled(cacheable=false)
    public static List<TechPrecalificacionWrapper> getPrecalificacionesByProspecto(Id prospectoId) {
        List<Precalificacion__c> records = TechPrecalificacionSelector.getByProspecto(prospectoId);
        List<TechPrecalificacionWrapper> wrappers = new List<TechPrecalificacionWrapper>();
        for (Precalificacion__c p : records) {
            wrappers.add(new TechPrecalificacionWrapper(p));
        }
        return wrappers;
    }

    @AuraEnabled
    public static String savePrecalificacion(Precalificacion__c precalificacion) {
        try {
            upsert precalificacion;
            return precalificacion.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar precalificación: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void deletePrecalificacion(Id precalificacionId) {
        try {
            delete new Precalificacion__c(Id = precalificacionId);
        } catch (Exception e) {
            throw new AuraHandledException('Error al eliminar precalificación: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> searchContratistas(String term) {
        String q = '%' + String.escapeSingleQuotes(term) + '%';
        List<Map<String, String>> results = new List<Map<String, String>>();
        for (Account a : [SELECT Id, Name FROM Account WHERE Name LIKE :q ORDER BY Name LIMIT 10]) {
            results.add(new Map<String, String>{ 'id' => a.Id, 'name' => a.Name });
        }
        return results;
    }
}