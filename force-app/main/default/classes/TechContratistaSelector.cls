public with sharing class TechContratistaSelector {
    public static List<Account> getRecentContratistas() {
        return [
            SELECT Id, Name, RFC__c, BillingCity, BillingState, Phone, CreatedDate,
                   (SELECT Id, Name, Estatus__c, Monto_Afianzado__c, Fecha_de_Vencimiento__c FROM Fianzas3__r ORDER BY CreatedDate DESC LIMIT 10),
                   (SELECT Id, ContractNumber, Status, Suma_Fianzas__c FROM Contratos_Contratista__r ORDER BY CreatedDate DESC LIMIT 10),
                   (SELECT Id, Name FROM Precalificaciones__r ORDER BY CreatedDate DESC LIMIT 5)
            FROM Account
            WHERE RecordType.DeveloperName = 'Contratista'
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}