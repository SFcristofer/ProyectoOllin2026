public with sharing class TechBeneficiarioSelector {
    public static List<Account> getRecentBeneficiarios() {
        return [
            SELECT Id, Name, RFC__c, CreatedDate,
                   (SELECT Id, Name FROM Fianzas2__r ORDER BY CreatedDate DESC LIMIT 10)
            FROM Account
            WHERE RecordType.DeveloperName = 'Beneficiario'
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}