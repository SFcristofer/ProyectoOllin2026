public with sharing class TechContratistaSelector {
    public static List<Account> getRecentContratistas() {
        return [
            SELECT Id, Name, RFC__c, CreatedDate,
                   (SELECT Id, Name, Contrato__r.Name FROM Fianzas3__r ORDER BY CreatedDate DESC LIMIT 10)
            FROM Account
            WHERE RecordType.DeveloperName = 'Contratista'
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}