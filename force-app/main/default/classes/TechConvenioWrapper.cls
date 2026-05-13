public class TechConvenioWrapper {
    @AuraEnabled public String  id           { get; set; }
    @AuraEnabled public String  name         { get; set; }
    @AuraEnabled public String  numero       { get; set; }
    @AuraEnabled public String  contrato     { get; set; }
    @AuraEnabled public String  tipo         { get; set; }
    @AuraEnabled public Date    fecha        { get; set; }
    @AuraEnabled public Decimal nuevoValor   { get; set; }
    @AuraEnabled public Decimal diferencia    { get; set; }
    @AuraEnabled public Date    nuevaFechaFin { get; set; }
    @AuraEnabled public String  descripcion   { get; set; }
    @AuraEnabled public String  motivo        { get; set; }
    @AuraEnabled public String  estatusClass  { get; set; }

    public TechConvenioWrapper(Tech_Convenio_Modificatorio__c c) {
        this.id           = c.Id;
        this.name         = c.Name;
        this.numero       = c.Numero_Convenio__c;
        this.contrato     = c.Contract__r != null ? c.Contract__r.ContractNumber : null;
        this.tipo         = c.Tipo_de_Modificacion__c;
        this.fecha        = c.Fecha_del_Convenio__c;
        this.nuevoValor   = c.Nuevo_Valor_Contrato__c;
        this.diferencia   = c.Diferencia_Monto__c;
        this.nuevaFechaFin = c.Nueva_Fecha_Fin__c;
        this.descripcion  = c.Descripcion__c;
        this.motivo       = c.Motivo__c;

        if      (c.Tipo_de_Modificacion__c == 'Monto')  this.estatusClass = 'airtable-badge-blue';
        else if (c.Tipo_de_Modificacion__c == 'Plazo')  this.estatusClass = 'airtable-badge-orange';
        else                                             this.estatusClass = 'airtable-badge-gray';
    }
}