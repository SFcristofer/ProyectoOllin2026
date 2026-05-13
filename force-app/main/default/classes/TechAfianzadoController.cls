public with sharing class TechAfianzadoController {
    @AuraEnabled(cacheable=true)
    public static List<TechAfianzadoWrapper> getAfianzadoList() {
        List<TechAfianzadoWrapper> wrappers = new List<TechAfianzadoWrapper>();
        for (Account a : TechAfianzadoSelector.getRecentAfianzados()) {
            wrappers.add(new TechAfianzadoWrapper(a));
        }
        return wrappers;
    }

    @AuraEnabled
    public static String saveAfianzadoWithRelations(Account account, Map<String, List<String>> relationsMap) {
        try {
            upsert account;
            if (relationsMap != null) {
                for (String tipo : relationsMap.keySet()) {
                    List<String> ids = relationsMap.get(tipo);
                    if (ids == null || ids.isEmpty()) continue;
                    if (tipo == 'Fianza') {
                        List<Tech_Fianza__c> toUpdate = new List<Tech_Fianza__c>();
                        for (String fId : ids) {
                            toUpdate.add(new Tech_Fianza__c(Id = (Id)fId, Afianzadoras__c = account.Id));
                        }
                        update toUpdate;
                    }
                }
            }
            return account.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar afianzado: ' + e.getMessage());
        }
    }
}