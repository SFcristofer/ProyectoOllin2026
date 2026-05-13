public with sharing class TechFianzaSelector {
    public static List<Tech_Fianza__c> getAllFianzas() {
        return [
            SELECT Id, Name,
                   Tipo_de_Riesgo__c, Prima_neta__c,
                   Monto_Afianzado__c, Monto_Afianzado_Vigente__c,
                   Prima_Vigente__c, Fecha_Vencimiento_Vigente__c,
                   Contratistas__c, Contratistas__r.Name,
                   Beneficiarios__c, Beneficiarios__r.Name,
                   Institucion__c, Institucion__r.Name,
                   Vendedor__c, Vendedor__r.Name,
                   Estatus__c,
                   Fecha_de_Emision__c, Fecha_de_Vencimiento__c,
                   DiasReclamaci_n__c,
                   Contrato__c, Contrato__r.ContractNumber, Contrato__r.Status, Contrato__r.Suma_Fianzas__c,
                   (SELECT Id, Tipo__c,
                           Account__c, Account__r.Name, Account__r.RFC__c, Account__r.BillingCity,
                           Vendedor__c, Vendedor__r.Name, Vendedor__r.CorreoElectronico__c, Vendedor__r.Rol__c
                    FROM TechRelaciones__r
                    ORDER BY CreatedDate ASC)
            FROM Tech_Fianza__c
            ORDER BY CreatedDate DESC
            LIMIT 2000
        ];
    }
}