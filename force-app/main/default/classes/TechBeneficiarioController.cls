public with sharing class TechBeneficiarioController {
    @AuraEnabled(cacheable=true)
    public static List<TechBeneficiarioWrapper> getBeneficiariosList() {
        List<TechBeneficiarioWrapper> wrappers = new List<TechBeneficiarioWrapper>();
        for (Beneficiario__c b : TechBeneficiarioSelector.getRecentBeneficiarios()) {
            wrappers.add(new TechBeneficiarioWrapper(b));
        }
        return wrappers;
    }
}
