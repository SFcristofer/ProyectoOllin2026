public class TechContratoWrapper {
    @AuraEnabled public String  id          { get; set; }
    @AuraEnabled public String  name        { get; set; }
    @AuraEnabled public String  contratista { get; set; }
    @AuraEnabled public Decimal monto       { get; set; }
    @AuraEnabled public Date    fechaInicio { get; set; }
    @AuraEnabled public Date    fechaFin    { get; set; }
    @AuraEnabled public String  estatus     { get; set; }
    @AuraEnabled public String  estatusClass { get; set; }

    public TechContratoWrapper(Contract c) {
        this.id          = c.Id;
        this.name        = c.ContractNumber;
        this.contratista = c.Contratista__r != null ? c.Contratista__r.Name : 'N/A';
        this.monto       = c.Suma_Fianzas__c != null ? c.Suma_Fianzas__c : 0;
        this.fechaInicio = c.StartDate;
        this.fechaFin    = c.EndDate;
        this.estatus     = c.Status;
        if      (c.Status == 'Activated') this.estatusClass = 'airtable-badge-green';
        else if (c.Status == 'Draft')     this.estatusClass = 'airtable-badge-orange';
        else                              this.estatusClass = 'airtable-badge-gray';
    }
}