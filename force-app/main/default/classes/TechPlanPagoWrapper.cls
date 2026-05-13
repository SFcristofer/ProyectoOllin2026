public class TechPlanPagoWrapper {
    @AuraEnabled public String  id           { get; set; }
    @AuraEnabled public String  name         { get; set; }
    @AuraEnabled public String  fianza       { get; set; }
    @AuraEnabled public String  seguro       { get; set; }
    @AuraEnabled public String  estatus      { get; set; }
    @AuraEnabled public String  estatusClass { get; set; }
    @AuraEnabled public Decimal montoTotal   { get; set; }
    @AuraEnabled public String  montoFmt     { get; set; }
    @AuraEnabled public Integer numRecibos   { get; set; }
    @AuraEnabled public String  periodo      { get; set; }
    @AuraEnabled public Date    fechaInicio  { get; set; }
    @AuraEnabled public String  metodoPago   { get; set; }

    public TechPlanPagoWrapper(Tech_Plan_de_Pago__c p) {
        this.id         = p.Id;
        this.name       = p.Name;
        this.fianza     = p.Fianzas__r != null ? p.Fianzas__r.Name : null;
        this.seguro     = p.Seguro__r != null ? p.Seguro__r.Name : null;
        this.estatus    = p.Estado__c;
        this.montoTotal = p.Monto_total__c;
        this.montoFmt   = p.Monto_total__c != null ? '$' + p.Monto_total__c.format() : '—';
        this.numRecibos = p.Num_recibos__c != null ? Integer.valueOf(p.Num_recibos__c) : null;
        this.periodo    = p.Periodo_Pago__c;
        this.fechaInicio = p.Fecha_inicio__c;
        this.metodoPago  = p.Metodo_Pago__c;

        if      (p.Estado__c == 'Activo'     || p.Estado__c == 'Activa')    this.estatusClass = 'at-badge at-badge-green';
        else if (p.Estado__c == 'Pendiente')                                  this.estatusClass = 'at-badge at-badge-orange';
        else if (p.Estado__c == 'Cancelado'  || p.Estado__c == 'Cancelada')  this.estatusClass = 'at-badge at-badge-red';
        else if (p.Estado__c == 'Completado')                                 this.estatusClass = 'at-badge at-badge-blue';
        else                                                                   this.estatusClass = 'at-badge at-badge-gray';
    }
}