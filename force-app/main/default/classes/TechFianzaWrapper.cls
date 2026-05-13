public class TechFianzaWrapper {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public List<String> contratistas { get; set; }
    @AuraEnabled public List<String> vendedores { get; set; }
    @AuraEnabled public List<String> contratos { get; set; }
    @AuraEnabled public List<Map<String,String>> contratistaRels { get; set; }
    @AuraEnabled public List<Map<String,String>> vendedorRels    { get; set; }
    @AuraEnabled public List<Map<String,String>> contratoRels    { get; set; }
    @AuraEnabled public String  estatus              { get; set; }
    @AuraEnabled public String  estatusClass         { get; set; }
    @AuraEnabled public String  tipoRiesgo           { get; set; }
    @AuraEnabled public Decimal monto                { get; set; }
    @AuraEnabled public Decimal primaNeta            { get; set; }
    @AuraEnabled public Decimal montoVigente         { get; set; }
    @AuraEnabled public Decimal primaVigente         { get; set; }
    @AuraEnabled public Date    fechaEmision         { get; set; }
    @AuraEnabled public String  beneficiario         { get; set; }
    @AuraEnabled public String  institucion          { get; set; }
    @AuraEnabled public Date    fechaVencimiento     { get; set; }
    @AuraEnabled public Date    fechaVencimientoVig  { get; set; }
    @AuraEnabled public Decimal diasReclamacion      { get; set; }

    public TechFianzaWrapper(Tech_Fianza__c f) {
        this.id                  = f.Id;
        this.name                = f.Name;
        this.estatus             = f.Estatus__c;
        this.tipoRiesgo          = f.Tipo_de_Riesgo__c;
        this.monto               = f.Monto_Afianzado__c;
        this.primaNeta           = f.Prima_neta__c;
        this.montoVigente        = f.Monto_Afianzado_Vigente__c;
        this.primaVigente        = f.Prima_Vigente__c;
        this.fechaEmision        = f.Fecha_de_Emision__c;
        this.beneficiario        = f.Beneficiarios__r != null ? f.Beneficiarios__r.Name : null;
        this.institucion         = f.Institucion__r   != null ? f.Institucion__r.Name   : null;
        this.fechaVencimiento    = f.Fecha_de_Vencimiento__c;
        this.fechaVencimientoVig = f.Fecha_Vencimiento_Vigente__c;
        this.diasReclamacion     = f.DiasReclamaci_n__c;

        this.contratistas    = new List<String>();
        this.vendedores      = new List<String>();
        this.contratos       = new List<String>();
        this.contratistaRels = new List<Map<String,String>>();
        this.vendedorRels    = new List<Map<String,String>>();
        this.contratoRels    = new List<Map<String,String>>();

        // Contrato directo (lookup simple) → siempre aparece en la sección
        if (f.Contrato__r != null) {
            String cNum    = f.Contrato__r.ContractNumber != null ? f.Contrato__r.ContractNumber : String.valueOf(f.Contrato__c);
            String cStatus = f.Contrato__r.Status != null ? f.Contrato__r.Status : '';
            String cMonto  = f.Contrato__r.Suma_Fianzas__c != null ? '$' + f.Contrato__r.Suma_Fianzas__c.format() : '';
            String cSub    = cStatus;
            if (String.isNotBlank(cMonto)) cSub += (String.isNotBlank(cSub) ? ' · ' : '') + cMonto;
            this.contratos.add(cNum);
            this.contratoRels.add(new Map<String,String>{ 'relId' => f.Contrato__c, 'name' => cNum, 'sub' => cSub });
        }

        // Relaciones múltiples vía Tech_Relacion__c
        for (Tech_Relacion__c rel : f.TechRelaciones__r) {
            if (rel.Tipo__c == 'Contratista' && rel.Account__r != null) {
                String sub = '';
                if (rel.Account__r.RFC__c      != null) sub += rel.Account__r.RFC__c;
                if (rel.Account__r.BillingCity != null) sub += (sub.length() > 0 ? ' · ' : '') + rel.Account__r.BillingCity;
                this.contratistas.add(rel.Account__r.Name);
                this.contratistaRels.add(new Map<String,String>{ 'relId' => rel.Id, 'name' => rel.Account__r.Name, 'sub' => sub });

            } else if (rel.Tipo__c == 'Vendedor' && rel.Vendedor__r != null) {
                String sub = '';
                if (rel.Vendedor__r.Rol__c               != null) sub += rel.Vendedor__r.Rol__c;
                if (rel.Vendedor__r.CorreoElectronico__c != null) sub += (sub.length() > 0 ? ' · ' : '') + rel.Vendedor__r.CorreoElectronico__c;
                this.vendedores.add(rel.Vendedor__r.Name);
                this.vendedorRels.add(new Map<String,String>{ 'relId' => rel.Id, 'name' => rel.Vendedor__r.Name, 'sub' => sub });
            }
        }

        if      (f.Estatus__c == 'Vigente') this.estatusClass = 'airtable-badge-green';
        else if (f.Estatus__c == 'Emitida') this.estatusClass = 'airtable-badge-orange';
        else                                this.estatusClass = 'airtable-badge-gray';
    }
}