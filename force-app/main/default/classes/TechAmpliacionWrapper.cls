public class TechAmpliacionWrapper {
    @AuraEnabled public String       id               { get; set; }
    @AuraEnabled public String       name             { get; set; }
    @AuraEnabled public List<String> fianzas          { get; set; }
    @AuraEnabled public String       tipo             { get; set; }
    @AuraEnabled public Date         fecha            { get; set; }
    @AuraEnabled public String       estatus          { get; set; }
    @AuraEnabled public String       estatusClass     { get; set; }
    @AuraEnabled public String       fianzaId         { get; set; }
    @AuraEnabled public String       fianzaName       { get; set; }
    @AuraEnabled public String       fianzaEstatus    { get; set; }
    @AuraEnabled public String       fianzaEstatusClass { get; set; }
    @AuraEnabled public String       fianzaMontoFmt   { get; set; }

    public TechAmpliacionWrapper(Tech_Endoso__c e) {
        this.id      = e.Id;
        this.name    = e.Name;
        this.fianzas = new List<String>();
        this.tipo    = e.Tipo_endoso__c;
        this.fecha   = e.Fecha_efectiva__c;

        if (e.Fianza__r != null) {
            this.fianzas.add(e.Fianza__r.Name);
            this.fianzaId   = e.Fianza__c;
            this.fianzaName = e.Fianza__r.Name;
            this.fianzaEstatus = e.Fianza__r.Estatus__c;
            this.fianzaMontoFmt = e.Fianza__r.Monto_Afianzado__c != null
                ? '$' + e.Fianza__r.Monto_Afianzado__c.format() : '';
            if      (e.Fianza__r.Estatus__c == 'Vigente') this.fianzaEstatusClass = 'airtable-badge-green';
            else if (e.Fianza__r.Estatus__c == 'Emitida') this.fianzaEstatusClass = 'airtable-badge-orange';
            else                                          this.fianzaEstatusClass = 'airtable-badge-gray';
        }

        this.estatus = e.Estado__c != null ? e.Estado__c : 'Activo';
        if      (this.estatus == 'Vigente' || this.estatus == 'Activo') this.estatusClass = 'airtable-badge-green';
        else if (this.estatus == 'Pendiente')                           this.estatusClass = 'airtable-badge-orange';
        else                                                            this.estatusClass = 'airtable-badge-gray';
    }
}