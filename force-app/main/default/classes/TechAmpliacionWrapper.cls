public class TechAmpliacionWrapper {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public String fianza { get; set; }
    @AuraEnabled public Decimal monto { get; set; }
    @AuraEnabled public Date fecha { get; set; }
    @AuraEnabled public String estatus { get; set; }
    @AuraEnabled public String estatusClass { get; set; }

    public TechAmpliacionWrapper(Endoso__c e) {
        this.id = e.Id;
        this.name = e.Name;
        this.fianza = 'N/A';
        this.monto = 0;
        this.fecha = null;
        this.estatus = 'N/A';
        this.estatusClass = 'airtable-badge-gray';
    }
}
