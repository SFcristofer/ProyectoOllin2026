public with sharing class TechBeneficiarioSelector {
    public static List<Beneficiario__c> getRecentBeneficiarios() {
        return [
            SELECT Id, Name, CreatedDate
            FROM Beneficiario__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}
