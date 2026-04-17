public class TechFianzaWrapper {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public String contratista { get; set; }
    @AuraEnabled public String estatus { get; set; }
    @AuraEnabled public String estatusClass { get; set; }
    @AuraEnabled public Decimal monto { get; set; }
    @AuraEnabled public Date fechaEmision { get; set; }
    @AuraEnabled public String afianzadora { get; set; }

    public TechFianzaWrapper(Fianza__c f) {
        this.id = f.Id;
        this.name = f.Name;
        this.contratista = f.Contratista__r != null ? f.Contratista__r.Name : 'Sin Contratista';
        this.estatus = f.Estatus__c;
        this.monto = f.Monto_Afianzado__c;
        this.fechaEmision = f.Fecha_de_Emisi_n__c;
        this.afianzadora = f.Afianzadora__c;
        
        if (f.Estatus__c == 'Activa') {
            this.estatusClass = 'airtable-badge-green';
        } else if (f.Estatus__c == 'Pendiente') {
            this.estatusClass = 'airtable-badge-orange';
        } else {
            this.estatusClass = 'airtable-badge-gray';
        }
    }
}
