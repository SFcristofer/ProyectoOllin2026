public with sharing class TechComisionSelector {
    public static List<Tech_Comision__c> getRecentComisiones() {
        return [
            SELECT Id, Name, Estatus__c, Pct_Aplicado__c, Monto_Ollin__c, Monto_Vendedor__c,
                   Fianza__c, Fianza__r.Name,
                   Vendedor__c, Vendedor__r.Name,
                   Seguro__c, Seguro__r.Name,
                   Tabla_Comision__c, Tabla_Comision__r.Name,
                   CreatedDate
            FROM Tech_Comision__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}