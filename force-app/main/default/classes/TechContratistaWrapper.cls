public class TechContratistaWrapper {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public String rfc { get; set; }
    @AuraEnabled public String cliente { get; set; }
    @AuraEnabled public List<String>             fianzas       { get; set; }
    @AuraEnabled public List<String>             contratos     { get; set; }
    @AuraEnabled public List<Map<String,String>> fianzasData   { get; set; }
    @AuraEnabled public List<Map<String,String>> contratosData { get; set; }
    @AuraEnabled public List<Map<String,String>> precalificaciones { get; set; }
    @AuraEnabled public String billingCity  { get; set; }
    @AuraEnabled public String billingState { get; set; }
    @AuraEnabled public String phone        { get; set; }
    @AuraEnabled public String estatus { get; set; }
    @AuraEnabled public String estatusClass { get; set; }

    public TechContratistaWrapper(Account a) {
        this.id               = a.Id;
        this.name             = a.Name;
        this.rfc              = a.RFC__c;
        this.billingCity      = a.BillingCity;
        this.billingState     = a.BillingState;
        this.phone            = a.Phone;
        this.fianzas          = new List<String>();
        this.contratos        = new List<String>();
        this.fianzasData      = new List<Map<String,String>>();
        this.contratosData    = new List<Map<String,String>>();
        this.precalificaciones = new List<Map<String,String>>();

        String ciudad = a.BillingCity != null ? a.BillingCity : '';
        String estado = a.BillingState != null ? a.BillingState : '';
        this.cliente = String.isNotBlank(ciudad) && String.isNotBlank(estado)
            ? ciudad + ', ' + estado
            : String.isNotBlank(ciudad) ? ciudad : estado;

        for (Contract c : a.Contratos_Contratista__r) {
            this.contratos.add(c.ContractNumber);
            String cEstatusClass = c.Status == 'Activated' ? 'airtable-badge-green' : c.Status == 'Draft' ? 'airtable-badge-orange' : 'airtable-badge-gray';
            this.contratosData.add(new Map<String,String>{
                'id'          => c.Id,
                'name'        => c.ContractNumber,
                'estatus'     => c.Status != null ? c.Status : '—',
                'estatusClass'=> cEstatusClass,
                'montoFmt'    => c.Suma_Fianzas__c != null ? '$' + c.Suma_Fianzas__c.format() : '—'
            });
        }

        for (Tech_Fianza__c f : a.Fianzas3__r) {
            this.fianzas.add(f.Name);
            String fEstatusClass = f.Estatus__c == 'Vigente' ? 'airtable-badge-green' : f.Estatus__c == 'Emitida' ? 'airtable-badge-orange' : 'airtable-badge-gray';
            this.fianzasData.add(new Map<String,String>{
                'id'          => f.Id,
                'name'        => f.Name,
                'estatus'     => f.Estatus__c != null ? f.Estatus__c : '—',
                'estatusClass'=> fEstatusClass,
                'montoFmt'    => f.Monto_Afianzado__c != null ? '$' + f.Monto_Afianzado__c.format() : '—',
                'vencimiento' => f.Fecha_de_Vencimiento__c != null ? String.valueOf(f.Fecha_de_Vencimiento__c) : '—'
            });
        }

        for (Precalificacion__c p : a.Precalificaciones__r) {
            this.precalificaciones.add(new Map<String,String>{
                'id'   => p.Id,
                'name' => p.Name
            });
        }

        this.estatus      = 'Activo';
        this.estatusClass = 'airtable-badge-green';
    }
}