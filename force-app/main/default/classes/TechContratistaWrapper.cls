public class TechContratistaWrapper {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public String rfc { get; set; }
    @AuraEnabled public String cliente { get; set; }
    @AuraEnabled public List<String> fianzas { get; set; }
    @AuraEnabled public List<String> contratos { get; set; }
    @AuraEnabled public List<Map<String,String>> precalificaciones { get; set; }
    @AuraEnabled public String estatus { get; set; }
    @AuraEnabled public String estatusClass { get; set; }

    public TechContratistaWrapper(Account a) {
        this.id               = a.Id;
        this.name             = a.Name;
        this.rfc              = a.RFC__c;
        this.cliente          = '';
        this.fianzas          = new List<String>();
        this.contratos        = new List<String>();
        this.precalificaciones = new List<Map<String,String>>();

        for (Tech_Fianza__c f : a.Fianzas3__r) {
            this.fianzas.add(f.Name);
            if (f.Contrato__r != null && !this.contratos.contains(f.Contrato__r.Name)) {
                this.contratos.add(f.Contrato__r.Name);
            }
        }

        this.estatus      = 'Activo';
        this.estatusClass = 'airtable-badge-green';
    }
}