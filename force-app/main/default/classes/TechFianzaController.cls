public with sharing class TechFianzaController {
    @AuraEnabled(cacheable=true)
    public static List<TechFianzaWrapper> getFianzasList() {
        List<TechFianzaWrapper> wrappers = new List<TechFianzaWrapper>();
        for (Fianza__c f : TechFianzaSelector.getRecentFianzas()) {
            wrappers.add(new TechFianzaWrapper(f));
        }
        return wrappers;
    }

    @AuraEnabled
    public static String saveFianzaWithRelations(Fianza__c fianza, Map<String, List<String>> relationsMap) {
        try {
            upsert fianza;
            
            List<Tech_Relacion__c> newRelations = new List<Tech_Relacion__c>();
            
            if (relationsMap != null) {
                for (String type : relationsMap.keySet()) {
                    for (String relatedId : relationsMap.get(type)) {
                        Tech_Relacion__c rel = new Tech_Relacion__c();
                        rel.Fianza__c = fianza.Id;
                        rel.Tipo__c = type;
                        
                        if (type == 'Contrato') rel.Contrato__c = (Id)relatedId;
                        else if (type == 'Endoso') rel.Endoso__c = (Id)relatedId;
                        else if (type == 'Contratista') rel.Account__c = (Id)relatedId;
                        else if (type == 'Vendedor') rel.Vendedor__c = (Id)relatedId;
                        
                        newRelations.add(rel);
                    }
                }
            }
            
            if (!newRelations.isEmpty()) {
                insert newRelations;
            }
            return fianza.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar fianza y relaciones: ' + e.getMessage());
        }
    }
}
