public with sharing class TechFianzaSelector {
    public static List<Tech_Fianza__c> getRecentFianzas() {
        return [
            SELECT Id, Name,
                   Contratistas__c, Contratistas__r.Name,
                   Beneficiarios__c, Beneficiarios__r.Name,
                   Afianzadoras__c, Afianzadoras__r.Name,
                   Vendedor__c, Vendedor__r.Name,
                   Estatus__c, Monto_Afianzado__c,
                   Fecha_de_Emision__c, Fecha_de_Vencimiento__c,
                   DiasReclamaci_n__c,
                   Contrato__c, Contrato__r.Name
            FROM Tech_Fianza__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}