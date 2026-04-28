public with sharing class TechAmpliacionSelector {
    public static List<Tech_Endoso__c> getRecentAmpliaciones() {
        return [
            SELECT Id, Name,
                   Fianza__c, Fianza__r.Name,
                   Tipo_endoso__c, Estado__c, Fecha_efectiva__c,
                   Afecta_prima__c, Diferencia_monto__c,
                   CreatedDate
            FROM Tech_Endoso__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}