public class TechContratistaInterfacesWrapper {
    @AuraEnabled public Decimal totalAfianzado       { get; set; }
    @AuraEnabled public Integer contratosCount       { get; set; }
    @AuraEnabled public Integer fianzasVencidasCount { get; set; }

    @AuraEnabled public List<ContratoItem>      contratos       { get; set; }
    @AuraEnabled public List<FianzaItem>        fianzas         { get; set; }
    @AuraEnabled public List<FianzaVencidaItem> fianzasVencidas { get; set; }

    public class ContratoItem {
        @AuraEnabled public String  id          { get; set; }
        @AuraEnabled public String  name        { get; set; }
        @AuraEnabled public String  contratista { get; set; }
        @AuraEnabled public Decimal monto       { get; set; }
        @AuraEnabled public String  proyecto    { get; set; }
    }

    public class FianzaItem {
        @AuraEnabled public String  id          { get; set; }
        @AuraEnabled public String  name        { get; set; }
        @AuraEnabled public String  contratista { get; set; }
        @AuraEnabled public String  contrato    { get; set; }
        @AuraEnabled public Decimal monto       { get; set; }
        @AuraEnabled public String  estatus     { get; set; }
    }

    public class FianzaVencidaItem {
        @AuraEnabled public String  id             { get; set; }
        @AuraEnabled public String  name           { get; set; }
        @AuraEnabled public String  contrato       { get; set; }
        @AuraEnabled public String  contratista    { get; set; }
        @AuraEnabled public Decimal montoAfianzado { get; set; }
        @AuraEnabled public String  fechaFin       { get; set; }
        @AuraEnabled public Integer diasVigencia   { get; set; }
        @AuraEnabled public Integer diasReclamo    { get; set; }
        @AuraEnabled public String  finReclamo     { get; set; }
        @AuraEnabled public String  estatus        { get; set; }
    }
}