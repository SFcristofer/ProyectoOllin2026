public class TechAmpliacionWrapper {
    @AuraEnabled public String       id          { get; set; }
    @AuraEnabled public String       name        { get; set; }
    @AuraEnabled public List<String> fianzas     { get; set; }
    @AuraEnabled public String       estatus     { get; set; }
    @AuraEnabled public String       estatusClass { get; set; }

    public TechAmpliacionWrapper(Tech_Endoso__c e) {
        this.id      = e.Id;
        this.name    = e.Name;
        this.fianzas = new List<String>();

        if (e.Fianza__r != null) this.fianzas.add(e.Fianza__r.Name);

        this.estatus = e.Estado__c != null ? e.Estado__c : 'Activo';
        if      (this.estatus == 'Vigente' || this.estatus == 'Activo') this.estatusClass = 'airtable-badge-green';
        else if (this.estatus == 'Pendiente')                           this.estatusClass = 'airtable-badge-orange';
        else                                                            this.estatusClass = 'airtable-badge-gray';
    }
}