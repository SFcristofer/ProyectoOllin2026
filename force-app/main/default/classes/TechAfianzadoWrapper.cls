public class TechAfianzadoWrapper {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public String rfc { get; set; }
    @AuraEnabled public String tipo { get; set; }
    @AuraEnabled public String telefono { get; set; }
    @AuraEnabled public String website { get; set; }
    @AuraEnabled public String industria { get; set; }
    @AuraEnabled public String estatus { get; set; }
    @AuraEnabled public String estatusClass { get; set; }

    public TechAfianzadoWrapper(Account a) {
        this.id = a.Id;
        this.name = a.Name;
        this.rfc = a.RFC__c;
        this.tipo = 'N/A';
        this.telefono = 'N/A';
        this.website = 'N/A';
        this.industria = 'N/A';
        this.estatus = 'Activo';
        this.estatusClass = 'airtable-badge-green';
    }
}
