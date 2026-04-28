public class TechFianzaWrapper {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public List<String> contratistas { get; set; }
    @AuraEnabled public List<String> vendedores { get; set; }
    @AuraEnabled public List<String> contratos { get; set; }
    @AuraEnabled public List<Map<String,String>> contratistaRels { get; set; }
    @AuraEnabled public List<Map<String,String>> vendedorRels    { get; set; }
    @AuraEnabled public List<Map<String,String>> contratoRels    { get; set; }
    @AuraEnabled public String  estatus            { get; set; }
    @AuraEnabled public String  estatusClass       { get; set; }
    @AuraEnabled public Decimal monto              { get; set; }
    @AuraEnabled public Date    fechaEmision       { get; set; }
    @AuraEnabled public String  beneficiario       { get; set; }
    @AuraEnabled public Date    fechaVencimiento   { get; set; }
    @AuraEnabled public Decimal diasReclamacion    { get; set; }

    public TechFianzaWrapper(Tech_Fianza__c f) {
        this.id               = f.Id;
        this.name             = f.Name;
        this.estatus          = f.Estatus__c;
        this.monto            = f.Monto_Afianzado__c;
        this.fechaEmision     = f.Fecha_de_Emision__c;
        this.beneficiario     = f.Beneficiarios__r != null ? f.Beneficiarios__r.Name : null;
        this.fechaVencimiento = f.Fecha_de_Vencimiento__c;
        this.diasReclamacion  = f.DiasReclamaci_n__c;

        this.contratistas    = new List<String>();
        this.vendedores      = new List<String>();
        this.contratos       = new List<String>();
        this.contratistaRels = new List<Map<String,String>>();
        this.vendedorRels    = new List<Map<String,String>>();
        this.contratoRels    = new List<Map<String,String>>();

        if (f.Contratistas__r != null) this.contratistas.add(f.Contratistas__r.Name);
        if (f.Vendedor__r     != null) this.vendedores.add(f.Vendedor__r.Name);
        if (f.Contrato__r     != null) this.contratos.add(f.Contrato__r.Name);

        if      (f.Estatus__c == 'Vigente') this.estatusClass = 'airtable-badge-green';
        else if (f.Estatus__c == 'Emitida') this.estatusClass = 'airtable-badge-orange';
        else                                this.estatusClass = 'airtable-badge-gray';
    }
}