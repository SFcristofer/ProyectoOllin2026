public with sharing class TechFianzaController {
    @AuraEnabled(cacheable=true)
    public static List<TechFianzaWrapper> getFianzasList() {
        List<TechFianzaWrapper> wrappers = new List<TechFianzaWrapper>();
        for (Tech_Fianza__c f : TechFianzaSelector.getRecentFianzas()) {
            wrappers.add(new TechFianzaWrapper(f));
        }
        return wrappers;
    }

    @AuraEnabled
    public static List<Map<String,String>> searchContratistas(String term) {
        String q = '%' + String.escapeSingleQuotes(term) + '%';
        List<Map<String,String>> results = new List<Map<String,String>>();
        for (Account a : [SELECT Id, Name FROM Account WHERE Name LIKE :q ORDER BY Name LIMIT 10]) {
            results.add(new Map<String,String>{ 'id' => a.Id, 'name' => a.Name });
        }
        return results;
    }

    @AuraEnabled
    public static List<Map<String,String>> searchVendedores(String term) {
        String q = '%' + String.escapeSingleQuotes(term) + '%';
        List<Map<String,String>> results = new List<Map<String,String>>();
        for (Tech_Vendedor__c v : [SELECT Id, Name FROM Tech_Vendedor__c WHERE Name LIKE :q ORDER BY Name LIMIT 10]) {
            results.add(new Map<String,String>{ 'id' => v.Id, 'name' => v.Name });
        }
        return results;
    }

    @AuraEnabled
    public static List<Map<String,String>> searchContratosForFianza(String term) {
        String q = '%' + String.escapeSingleQuotes(term) + '%';
        List<Map<String,String>> results = new List<Map<String,String>>();
        for (Contract c : [SELECT Id, ContractNumber FROM Contract WHERE ContractNumber LIKE :q ORDER BY ContractNumber LIMIT 10]) {
            results.add(new Map<String,String>{ 'id' => c.Id, 'name' => c.ContractNumber });
        }
        return results;
    }

    @AuraEnabled
    public static void deleteRelacion(String relId) {
        // No-op: direct lookups on Tech_Fianza__c replace Tech_Relacion__c bridge records
    }

    @AuraEnabled
    public static void addRelacionFianza(String fianzaId, String relatedId, String tipo) {
        try {
            Tech_Fianza__c tf = new Tech_Fianza__c(Id = (Id)fianzaId);
            if      (tipo == 'Contratista')  tf.Contratistas__c  = (Id)relatedId;
            else if (tipo == 'Vendedor')     tf.Vendedor__c      = (Id)relatedId;
            else if (tipo == 'Contrato')     tf.Contrato__c      = (Id)relatedId;
            else if (tipo == 'Beneficiario') tf.Beneficiarios__c = (Id)relatedId;
            else if (tipo == 'Afianzadora')  tf.Afianzadoras__c  = (Id)relatedId;
            update tf;
        } catch (Exception e) {
            throw new AuraHandledException('Error al agregar relación: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String saveFianzaWithRelations(Tech_Fianza__c fianza, Map<String, List<String>> relationsMap) {
        try {
            upsert fianza;
            if (relationsMap != null) {
                Tech_Fianza__c toUpdate = new Tech_Fianza__c(Id = fianza.Id);
                Boolean needsUpdate = false;
                for (String tipo : relationsMap.keySet()) {
                    List<String> ids = relationsMap.get(tipo);
                    if (ids == null || ids.isEmpty()) continue;
                    String relatedId = ids[0];
                    if      (tipo == 'Contratista')  { toUpdate.Contratistas__c  = (Id)relatedId; needsUpdate = true; }
                    else if (tipo == 'Vendedor')     { toUpdate.Vendedor__c      = (Id)relatedId; needsUpdate = true; }
                    else if (tipo == 'Contrato')     { toUpdate.Contrato__c      = (Id)relatedId; needsUpdate = true; }
                    else if (tipo == 'Beneficiario') { toUpdate.Beneficiarios__c = (Id)relatedId; needsUpdate = true; }
                    else if (tipo == 'Afianzadora')  { toUpdate.Afianzadoras__c  = (Id)relatedId; needsUpdate = true; }
                }
                if (needsUpdate) update toUpdate;
            }
            return fianza.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar fianza y relaciones: ' + e.getMessage());
        }
    }
}