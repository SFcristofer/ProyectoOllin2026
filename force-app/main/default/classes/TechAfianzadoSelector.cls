public with sharing class TechAfianzadoSelector {
    public static List<Account> getRecentAfianzados() {
        return [
            SELECT Id, Name, RFC__c, CreatedDate,
                   (SELECT Id, Name FROM Fianzas1__r ORDER BY CreatedDate DESC LIMIT 5),
                   (SELECT Id, Name FROM Fianzas2__r ORDER BY CreatedDate DESC LIMIT 5),
                   (SELECT Id, Name FROM Fianzas3__r ORDER BY CreatedDate DESC LIMIT 5)
            FROM Account
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}