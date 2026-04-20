public with sharing class TechContratistaController {
    @AuraEnabled(cacheable=true)
    public static List<TechContratistaWrapper> getContratistaList() {
        List<TechContratistaWrapper> wrappers = new List<TechContratistaWrapper>();
        for (Contratista__c c : TechContratistaSelector.getRecentContratistas()) {
            wrappers.add(new TechContratistaWrapper(c));
        }
        return wrappers;
    }

    @AuraEnabled
    public static String saveContratistaWithRelations(Contratista__c contratista, Map<String, List<String>> relationsMap) {
        try {
            upsert contratista;
            List<Tech_Relacion__c> newRelations = new List<Tech_Relacion__c>();
            if (relationsMap != null) {
                for (String type : relationsMap.keySet()) {
                    for (String relatedId : relationsMap.get(type)) {
                        Tech_Relacion__c rel = new Tech_Relacion__c();
                        rel.Account__c = contratista.Id; // Usamos Account__c como Lookup genérico en el puente
                        rel.Tipo__c = type;
                        if (type == 'Fianza') rel.Fianza__c = (Id)relatedId;
                        else if (type == 'Contrato') rel.Contrato__c = (Id)relatedId;
                        newRelations.add(rel);
                    }
                }
            }
            if (!newRelations.isEmpty()) insert newRelations;
            return contratista.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar contratista: ' + e.getMessage());
        }
    }
}
