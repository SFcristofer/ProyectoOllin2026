public class TechFianzaWrapper {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public List<String> contratistas { get; set; }
    @AuraEnabled public List<String> vendedores { get; set; }
    @AuraEnabled public List<String> contratos { get; set; }
    @AuraEnabled public String estatus { get; set; }
    @AuraEnabled public String estatusClass { get; set; }
    @AuraEnabled public Decimal monto { get; set; }
    @AuraEnabled public Date fechaEmision { get; set; }

    public TechFianzaWrapper(Fianza__c f) {
        this.id = f.Id;
        this.name = f.Name;
        this.estatus = f.Estatus__c;
        this.monto = f.Monto_Afianzado__c;
        this.fechaEmision = f.Fecha_de_Emisi_n__c;
        
        this.contratistas = new List<String>();
        this.vendedores = new List<String>();
        this.contratos = new List<String>();

        // 1. Agregar el registro principal primero si existe
        if (f.Contratista__r != null) this.contratistas.add(f.Contratista__r.Name);
        if (f.Vendedor__r != null) this.vendedores.add(f.Vendedor__r.Name);

        // 2. Procesar las relaciones múltiples adicionales (evitando duplicar el principal)
        for (Tech_Relacion__c rel : f.Relaciones_Tecnicas_Fianza__r) {
            if (rel.Tipo__c == 'Contratista' && rel.Account__r.Name != null) {
                if (!this.contratistas.contains(rel.Account__r.Name)) {
                    this.contratistas.add(rel.Account__r.Name);
                }
            } else if (rel.Tipo__c == 'Vendedor' && rel.Vendedor__r.Name != null) {
                if (!this.vendedores.contains(rel.Vendedor__r.Name)) {
                    this.vendedores.add(rel.Vendedor__r.Name);
                }
            } else if (rel.Tipo__c == 'Contrato' && rel.Contrato__r.Name != null) {
                if (!this.contratos.contains(rel.Contrato__r.Name)) {
                    this.contratos.add(rel.Contrato__r.Name);
                }
            }
        }

        if (f.Estatus__c == 'Activa') this.estatusClass = 'airtable-badge-green';
        else if (f.Estatus__c == 'Pendiente') this.estatusClass = 'airtable-badge-orange';
        else this.estatusClass = 'airtable-badge-gray';
    }
}
