public with sharing class TechContratistaSelector {
    public static List<Contratista__c> getRecentContratistas() {
        return [
            SELECT Id, Name, CreatedDate
            FROM Contratista__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}
