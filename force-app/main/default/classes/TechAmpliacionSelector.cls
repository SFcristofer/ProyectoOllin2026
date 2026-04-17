public with sharing class TechAmpliacionSelector {
    public static List<Endoso__c> getRecentAmpliaciones() {
        return [
            SELECT Id, Name, CreatedDate
            FROM Endoso__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}
