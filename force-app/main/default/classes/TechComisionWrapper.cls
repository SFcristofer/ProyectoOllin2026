public class TechComisionWrapper {
    @AuraEnabled public String  id             { get; set; }
    @AuraEnabled public String  name           { get; set; }
    @AuraEnabled public String  fianza         { get; set; }
    @AuraEnabled public String  vendedor       { get; set; }
    @AuraEnabled public String  seguro         { get; set; }
    @AuraEnabled public String  tablaComision  { get; set; }
    @AuraEnabled public String  estatus        { get; set; }
    @AuraEnabled public String  estatusClass   { get; set; }
    @AuraEnabled public Decimal pctAplicado    { get; set; }
    @AuraEnabled public Decimal montoOllin     { get; set; }
    @AuraEnabled public String  montoOllinFmt  { get; set; }
    @AuraEnabled public Decimal montoVendedor  { get; set; }
    @AuraEnabled public String  montoVendedorFmt { get; set; }

    public TechComisionWrapper(Tech_Comision__c c) {
        this.id            = c.Id;
        this.name          = c.Name;
        this.fianza        = c.Fianza__r       != null ? c.Fianza__r.Name       : null;
        this.vendedor      = c.Vendedor__r     != null ? c.Vendedor__r.Name     : null;
        this.seguro        = c.Seguro__r       != null ? c.Seguro__r.Name       : null;
        this.tablaComision = c.Tabla_Comision__r != null ? c.Tabla_Comision__r.Name : null;
        this.estatus       = c.Estatus__c;
        this.pctAplicado   = c.Pct_Aplicado__c;
        this.montoOllin    = c.Monto_Ollin__c;
        this.montoOllinFmt = c.Monto_Ollin__c   != null ? '$' + c.Monto_Ollin__c.format()   : '—';
        this.montoVendedor    = c.Monto_Vendedor__c;
        this.montoVendedorFmt = c.Monto_Vendedor__c != null ? '$' + c.Monto_Vendedor__c.format() : '—';

        if      (c.Estatus__c == 'Pagado'    || c.Estatus__c == 'Aprobado')  this.estatusClass = 'at-badge at-badge-green';
        else if (c.Estatus__c == 'Pendiente' || c.Estatus__c == 'En Proceso') this.estatusClass = 'at-badge at-badge-orange';
        else if (c.Estatus__c == 'Rechazado' || c.Estatus__c == 'Cancelado') this.estatusClass = 'at-badge at-badge-red';
        else                                                                   this.estatusClass = 'at-badge at-badge-gray';
    }
}