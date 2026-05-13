public class TechAfianzadoWrapper {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public String rfc { get; set; }
    @AuraEnabled public List<String> fianzas { get; set; }
    @AuraEnabled public String estatus { get; set; }
    @AuraEnabled public String estatusClass { get; set; }

    public TechAfianzadoWrapper(Account a) {
        this.id      = a.Id;
        this.name    = a.Name;
        this.rfc     = a.RFC__c;
        this.fianzas = new List<String>();

        for (Tech_Fianza__c f : a.Fianzas1__r) this.fianzas.add(f.Name);
        for (Tech_Fianza__c f : a.Fianzas2__r) { if (!this.fianzas.contains(f.Name)) this.fianzas.add(f.Name); }
        for (Tech_Fianza__c f : a.Fianzas3__r) { if (!this.fianzas.contains(f.Name)) this.fianzas.add(f.Name); }

        this.estatus      = 'Activo';
        this.estatusClass = 'airtable-badge-green';
    }
}