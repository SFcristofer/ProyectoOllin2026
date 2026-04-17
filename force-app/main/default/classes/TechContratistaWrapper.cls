public class TechContratistaWrapper {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public String rfc { get; set; }
    @AuraEnabled public String email { get; set; }
    @AuraEnabled public String telefono { get; set; }
    @AuraEnabled public String estatus { get; set; }
    @AuraEnabled public String estatusClass { get; set; }

    public TechContratistaWrapper(Contratista__c c) {
        this.id = c.Id;
        this.name = c.Name;
        this.rfc = 'N/A';
        this.email = 'N/A';
        this.telefono = 'N/A';
        this.estatus = 'N/A';
        this.estatusClass = 'airtable-badge-gray';
    }
}
