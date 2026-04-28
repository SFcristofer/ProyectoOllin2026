public with sharing class TechBeneficiarioController {
    @AuraEnabled(cacheable=true)
    public static List<TechBeneficiarioWrapper> getBeneficiarioList() {
        List<TechBeneficiarioWrapper> wrappers = new List<TechBeneficiarioWrapper>();
        for (Account a : TechBeneficiarioSelector.getRecentBeneficiarios()) {
            wrappers.add(new TechBeneficiarioWrapper(a));
        }
        return wrappers;
    }

    @AuraEnabled
    public static String saveBeneficiarioWithRelations(Account beneficiario, Map<String, List<String>> relationsMap) {
        try {
            upsert beneficiario;
            if (relationsMap != null) {
                for (String tipo : relationsMap.keySet()) {
                    List<String> ids = relationsMap.get(tipo);
                    if (ids == null || ids.isEmpty()) continue;
                    if (tipo == 'Fianza') {
                        List<Tech_Fianza__c> toUpdate = new List<Tech_Fianza__c>();
                        for (String fId : ids) {
                            toUpdate.add(new Tech_Fianza__c(Id = (Id)fId, Beneficiarios__c = beneficiario.Id));
                        }
                        update toUpdate;
                    }
                }
            }
            return beneficiario.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar beneficiario: ' + e.getMessage());
        }
    }
}