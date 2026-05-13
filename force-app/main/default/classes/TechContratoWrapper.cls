public class TechContratoWrapper {
    @AuraEnabled public String  id                { get; set; }
    @AuraEnabled public String  name              { get; set; }
    @AuraEnabled public String  contratista       { get; set; }
    @AuraEnabled public String  contratistaId     { get; set; }
    @AuraEnabled public String  beneficiario      { get; set; }
    @AuraEnabled public String  beneficiarioId    { get; set; }
    @AuraEnabled public String  institucion       { get; set; }
    @AuraEnabled public String  institucionId     { get; set; }
    @AuraEnabled public Decimal monto             { get; set; }
    @AuraEnabled public Decimal valorVigente      { get; set; }
    @AuraEnabled public Decimal exposicion        { get; set; }
    @AuraEnabled public String  proyecto          { get; set; }
    @AuraEnabled public Date    fechaInicio       { get; set; }
    @AuraEnabled public Date    fechaFin          { get; set; }
    @AuraEnabled public Date    fechaFinVigente   { get; set; }
    @AuraEnabled public String  estatus           { get; set; }
    @AuraEnabled public String  estatusClass      { get; set; }

    public TechContratoWrapper(Contract c) {
        this.id              = c.Id;
        this.name            = c.ContractNumber;
        this.contratista     = c.Contratista__r  != null ? c.Contratista__r.Name  : null;
        this.contratistaId   = c.Contratista__c;
        this.beneficiario    = c.Beneficiario__r != null ? c.Beneficiario__r.Name : null;
        this.beneficiarioId  = c.Beneficiario__c;
        this.institucion     = c.Institucion__r  != null ? c.Institucion__r.Name  : null;
        this.institucionId   = c.Institucion__c;
        this.monto           = c.Suma_Fianzas__c;
        this.valorVigente    = c.Valor_Contrato_Vigente__c;
        this.exposicion      = c.Exposicion_del__c;
        this.proyecto        = c.Proyecto__c;
        this.fechaInicio     = c.StartDate;
        this.fechaFin        = c.EndDate;
        this.fechaFinVigente = c.Fin_Contrato_Vigente__c;
        this.estatus         = c.Status;
        if      (c.Status == 'Activated') this.estatusClass = 'airtable-badge-green';
        else if (c.Status == 'Draft')     this.estatusClass = 'airtable-badge-orange';
        else                              this.estatusClass = 'airtable-badge-gray';
    }
}