public with sharing class TechContratoController {
    @AuraEnabled(cacheable=true)
    public static List<TechContratoWrapper> getContratosList() {
        List<TechContratoWrapper> wrappers = new List<TechContratoWrapper>();
        for (Contract c : TechContratoSelector.getRecentContratos()) {
            wrappers.add(new TechContratoWrapper(c));
        }
        return wrappers;
    }

    @AuraEnabled
    public static String saveContratoWithRelations(Contract contrato, Map<String, List<String>> relationsMap) {
        try {
            upsert contrato;
            if (relationsMap != null) {
                Contract toUpdate = new Contract(Id = contrato.Id);
                Boolean needsUpdate = false;
                for (String tipo : relationsMap.keySet()) {
                    List<String> ids = relationsMap.get(tipo);
                    if (ids == null || ids.isEmpty()) continue;
                    String relatedId = ids[0];
                    if (tipo == 'Contratista') { toUpdate.Contratista__c = (Id)relatedId; needsUpdate = true; }
                }
                if (needsUpdate) update toUpdate;
            }
            return contrato.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar contrato: ' + e.getMessage());
        }
    }
}