public class TechGestionWrapper {

    @AuraEnabled public KpiBlock           kpis               { get; set; }
    @AuraEnabled public List<ReciboRow>    recibosVencidos    { get; set; }
    @AuraEnabled public List<ReciboRow>    recibosPorCobrar   { get; set; }
    @AuraEnabled public List<ReciboRow>    recibosCobradosMes { get; set; }
    @AuraEnabled public List<ReciboRow>    recibosPendientesMes { get; set; }
    @AuraEnabled public RenovacionesBlock  renovaciones       { get; set; }

    public class KpiBlock {
        @AuraEnabled public Integer vencidosCount        { get; set; }
        @AuraEnabled public String  vencidosAmountFmt    { get; set; }
        @AuraEnabled public Integer porCobrarCount       { get; set; }
        @AuraEnabled public String  porCobrarAmountFmt   { get; set; }
        @AuraEnabled public Integer cobradoMesCount      { get; set; }
        @AuraEnabled public String  cobradoMesAmountFmt  { get; set; }
        @AuraEnabled public Integer pendienteMesCount    { get; set; }
        @AuraEnabled public String  pendienteMesAmountFmt { get; set; }
        @AuraEnabled public Integer atrasadasCount       { get; set; }
        @AuraEnabled public String  atrasadasAmountFmt   { get; set; }
        @AuraEnabled public Integer renovMesActualCount  { get; set; }
        @AuraEnabled public String  renovMesActualAmountFmt { get; set; }
        @AuraEnabled public Integer renovMesSigCount     { get; set; }
    }

    public class ReciboRow {
        @AuraEnabled public String  id            { get; set; }
        @AuraEnabled public String  tipo          { get; set; } // 'seguro' | 'fianza'
        @AuraEnabled public String  ramo          { get; set; }
        @AuraEnabled public String  numero        { get; set; }
        @AuraEnabled public String  poliza        { get; set; }
        @AuraEnabled public String  cliente       { get; set; }
        @AuraEnabled public String  fechaFmt      { get; set; }
        @AuraEnabled public String  montoFmt      { get; set; }
        @AuraEnabled public Integer diasMora      { get; set; }
        @AuraEnabled public String  semaforoClass { get; set; }
    }

    public class RenovacionesBlock {
        @AuraEnabled public List<SeguroRow> atrasadas    { get; set; }
        @AuraEnabled public List<SeguroRow> mesActual    { get; set; }
        @AuraEnabled public List<SeguroRow> mesSiguiente { get; set; }
    }

    public class SeguroRow {
        @AuraEnabled public String  id           { get; set; }
        @AuraEnabled public String  tipo         { get; set; } // 'seguro' | 'fianza'
        @AuraEnabled public String  numeroPoliza { get; set; }
        @AuraEnabled public String  cliente      { get; set; }
        @AuraEnabled public String  ramo         { get; set; }
        @AuraEnabled public String  finVigencia  { get; set; }
        @AuraEnabled public String  diasTexto    { get; set; }
        @AuraEnabled public String  primaFmt     { get; set; }
    }

    public static String fmtMxn(Decimal d) {
        if (d == null || d == 0) return '$0';
        return '$' + d.setScale(0, RoundingMode.HALF_UP).format();
    }
}