public class TechReciboCobroWrapper {
    @AuraEnabled public String  id              { get; set; }
    @AuraEnabled public String  name            { get; set; }
    @AuraEnabled public String  plan            { get; set; }
    @AuraEnabled public String  estatus         { get; set; }
    @AuraEnabled public String  estatusClass    { get; set; }
    @AuraEnabled public Decimal montoProgramado { get; set; }
    @AuraEnabled public String  montoProgramadoFmt { get; set; }
    @AuraEnabled public Decimal montoCobrado    { get; set; }
    @AuraEnabled public String  montoCobradoFmt { get; set; }
    @AuraEnabled public Date    fechaProgramada { get; set; }
    @AuraEnabled public Date    fechaPago       { get; set; }
    @AuraEnabled public String  metodoPago      { get; set; }
    @AuraEnabled public Decimal saldo           { get; set; }
    @AuraEnabled public String  saldoFmt        { get; set; }

    public TechReciboCobroWrapper(Tech_Recibo_Pago__c r) {
        this.id              = r.Id;
        this.name            = r.Name;
        this.plan            = r.Plan_de_Pagos__r != null ? r.Plan_de_Pagos__r.Name : null;
        this.estatus         = r.Estado__c;
        this.montoProgramado = r.Monto_programado__c;
        this.montoProgramadoFmt = r.Monto_programado__c != null ? '$' + r.Monto_programado__c.setScale(2, System.RoundingMode.HALF_UP).format() : '—';
        this.montoCobrado    = r.Monto_cobrado__c;
        this.montoCobradoFmt = r.Monto_cobrado__c != null ? '$' + r.Monto_cobrado__c.setScale(2, System.RoundingMode.HALF_UP).format() : '—';
        this.fechaProgramada = r.Fecha_programada__c;
        this.fechaPago       = r.Fecha_pago__c;
        this.metodoPago      = r.Metodo_pago__c;
        this.saldo           = r.Saldo__c;
        this.saldoFmt        = r.Saldo__c != null ? '$' + r.Saldo__c.setScale(2, System.RoundingMode.HALF_UP).format() : '—';

        if      (r.Estado__c == 'Pagado'    || r.Estado__c == 'Cobrado')   this.estatusClass = 'at-badge at-badge-green';
        else if (r.Estado__c == 'Pendiente' || r.Estado__c == 'Programado') this.estatusClass = 'at-badge at-badge-orange';
        else if (r.Estado__c == 'Vencido'   || r.Estado__c == 'No Pagado') this.estatusClass = 'at-badge at-badge-red';
        else if (r.Estado__c == 'En Proceso')                               this.estatusClass = 'at-badge at-badge-blue';
        else                                                                 this.estatusClass = 'at-badge at-badge-gray';
    }
}