public class TechPrecalificacionWrapper {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public String contratistaId { get; set; }
    @AuraEnabled public String contratistaName { get; set; }
    @AuraEnabled public String estado { get; set; }
    @AuraEnabled public String estadoAutomatico { get; set; }
    @AuraEnabled public String estatusClass { get; set; }
    @AuraEnabled public Date fechaEstadosFinancieros { get; set; }
    @AuraEnabled public Decimal capitalContable { get; set; }
    @AuraEnabled public String capacidadAfianzamiento { get; set; }
    @AuraEnabled public Decimal lineaAfianzamiento { get; set; }
    @AuraEnabled public Decimal resultadoAfianzamiento { get; set; }
    @AuraEnabled public Decimal scoreICP { get; set; }
    @AuraEnabled public Decimal importeTotalContrato { get; set; }
    @AuraEnabled public Decimal totalAfianzar { get; set; }
    @AuraEnabled public Decimal ventasNetas { get; set; }
    @AuraEnabled public Decimal apalancamiento { get; set; }
    @AuraEnabled public Decimal liquidez { get; set; }
    @AuraEnabled public Decimal capitalTrabajo { get; set; }
    @AuraEnabled public Decimal activoTotal { get; set; }
    @AuraEnabled public Decimal pasivoTotal { get; set; }
    @AuraEnabled public String comentarios { get; set; }

    public TechPrecalificacionWrapper(Precalificacion__c p) {
        this.id = p.Id;
        this.name = p.Name;
        this.contratistaId = p.Contratista__c;
        this.contratistaName = p.Contratista__r != null ? p.Contratista__r.Name : null;
        this.estado = p.Estado__c;
        this.estadoAutomatico = p.Estado_autom_tico__c;
        this.fechaEstadosFinancieros = p.Fecha_Estados_Financieros__c;
        this.capitalContable = p.Capital_Contable__c;
        this.capacidadAfianzamiento = p.Capacidad_Afianzamiento_Calc__c != null
            ? p.Capacidad_Afianzamiento_Calc__c
            : p.Capacidad_de_Afianzamiento__c;
        this.lineaAfianzamiento = p.Linea_Afianzamiento_Calc__c;
        this.resultadoAfianzamiento = p.Resultado_Afianzamiento_Calc__c;
        this.scoreICP = p.Score_ICP__c;
        this.importeTotalContrato = p.Importe_Total_Contrato__c;
        this.totalAfianzar = p.Total_a_Afianzar__c;
        this.ventasNetas = p.Ventas_Netas__c;
        this.apalancamiento = p.Apalancamiento__c;
        this.liquidez = p.Liquidez__c;
        this.capitalTrabajo = p.Capital_de_Trabajo__c;
        this.activoTotal = p.Activo_total__c;
        this.pasivoTotal  = p.Pasivo_Total__c;
        this.comentarios  = p.Comentarios__c;

        String estadoEval = String.isNotBlank(p.Estado_autom_tico__c) ? p.Estado_autom_tico__c : p.Estado__c;
        if (estadoEval == 'Aprobado') {
            this.estatusClass = 'airtable-badge-green';
        } else if (estadoEval == 'Rechazado') {
            this.estatusClass = 'airtable-badge-red';
        } else {
            this.estatusClass = 'airtable-badge-yellow';
        }
    }
}