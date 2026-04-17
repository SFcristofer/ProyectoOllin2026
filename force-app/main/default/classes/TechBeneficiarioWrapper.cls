public class TechBeneficiarioWrapper {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public String rfc { get; set; }
    @AuraEnabled public String tipo { get; set; }
    @AuraEnabled public String estatus { get; set; }
    @AuraEnabled public String estatusClass { get; set; }

    public TechBeneficiarioWrapper(Beneficiario__c b) {
        this.id = b.Id;
        this.name = b.Name;
        this.rfc = 'N/A';
        this.tipo = 'N/A';
        this.estatus = 'N/A';
        this.estatusClass = 'airtable-badge-gray';
    }
}
