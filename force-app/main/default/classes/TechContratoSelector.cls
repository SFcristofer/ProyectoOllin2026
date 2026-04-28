public with sharing class TechContratoSelector {
    public static List<Contract> getRecentContratos() {
        return [
            SELECT Id, ContractNumber,
                   Contratista__c, Contratista__r.Name,
                   Beneficiario__c, Beneficiario__r.Name,
                   Institucion__c, Institucion__r.Name,
                   Suma_Fianzas__c, Exposicion_del__c,
                   Status, StartDate, EndDate
            FROM Contract
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}