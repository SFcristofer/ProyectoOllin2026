public with sharing class TechFianzaSelector {
    public static List<Fianza__c> getRecentFianzas() {
        return [
            SELECT Id, Name, Contratista__r.Name, Estatus__c, 
                   Monto_Afianzado__c, Fecha_de_Emisi_n__c, 
                   Fecha_de_Vencimiento__c, Costo_de_fianza__c, 
                   Afianzadora__c
            FROM Fianza__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}
