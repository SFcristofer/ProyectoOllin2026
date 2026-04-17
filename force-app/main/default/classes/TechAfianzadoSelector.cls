public with sharing class TechAfianzadoSelector {
    public static List<Account> getRecentAfianzados() {
        return [
            SELECT Id, Name, RFC__c, CreatedDate
            FROM Account
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}
