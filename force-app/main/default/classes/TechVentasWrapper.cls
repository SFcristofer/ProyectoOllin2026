public class TechVentasWrapper {

    @AuraEnabled public Integer leadsActivos       { get; set; }
    @AuraEnabled public Integer oppsEnPipeline     { get; set; }
    @AuraEnabled public Integer cierresGanados     { get; set; }
    @AuraEnabled public Integer cierresPerdidos    { get; set; }
    @AuraEnabled public Decimal tasaCierre         { get; set; }
    @AuraEnabled public Decimal montoTotalPipeline { get; set; }

    public class LeadItem {
        @AuraEnabled public String  id                  { get; set; }
        @AuraEnabled public String  name                { get; set; }
        @AuraEnabled public String  firstName           { get; set; }
        @AuraEnabled public String  lastName            { get; set; }
        @AuraEnabled public String  leadSource          { get; set; }
        @AuraEnabled public String  status              { get; set; }
        @AuraEnabled public String  statusClass         { get; set; }
        @AuraEnabled public String  company             { get; set; }
        @AuraEnabled public String  email               { get; set; }
        @AuraEnabled public String  phone               { get; set; }
        @AuraEnabled public String  mobilePhone         { get; set; }
        @AuraEnabled public String  title               { get; set; }
        @AuraEnabled public String  owner               { get; set; }
        @AuraEnabled public String  createdDate         { get; set; }
        @AuraEnabled public Integer score               { get; set; }
        @AuraEnabled public String  scoreClass          { get; set; }
        @AuraEnabled public String  scoreBarStyle       { get; set; }
        @AuraEnabled public String  scoreLabel          { get; set; }
        @AuraEnabled public String  tipoSeguro          { get; set; }
        @AuraEnabled public Decimal monto               { get; set; }
        @AuraEnabled public String  montoFmt            { get; set; }
        @AuraEnabled public Decimal aportacionEstimada  { get; set; }
        @AuraEnabled public String  vendedor            { get; set; }
        @AuraEnabled public String  vendedorId          { get; set; }
        @AuraEnabled public String  motivoNoCalif       { get; set; }
        @AuraEnabled public Boolean puedeReactivarse    { get; set; }
        // Campos personales
        @AuraEnabled public String  genero              { get; set; }
        @AuraEnabled public String  sexo                { get; set; }
        @AuraEnabled public String  fechaNacimiento     { get; set; }
        @AuraEnabled public Decimal edadCalculada       { get; set; }
        @AuraEnabled public Boolean fuma                { get; set; }
        @AuraEnabled public String  curp                { get; set; }
        @AuraEnabled public String  cp                  { get; set; }
        @AuraEnabled public String  rating              { get; set; }
        @AuraEnabled public String  industry            { get; set; }
        @AuraEnabled public String  regimenesFiscales   { get; set; }
        @AuraEnabled public String  tiposContribuyentes { get; set; }
        @AuraEnabled public String  numeroProspecto     { get; set; }
        @AuraEnabled public String  techVendedorId      { get; set; }
        @AuraEnabled public String  techVendedor        { get; set; }
        @AuraEnabled public String  aseguradoraId       { get; set; }
        @AuraEnabled public String  aseguradora         { get; set; }
        @AuraEnabled public Boolean contratoFlag        { get; set; }
        // Auto
        @AuraEnabled public String  marca               { get; set; }
        @AuraEnabled public String  modelo              { get; set; }
        @AuraEnabled public Decimal anho                { get; set; }
        @AuraEnabled public String  version             { get; set; }
        @AuraEnabled public String  uso                 { get; set; }
        @AuraEnabled public String  tipoCobertura       { get; set; }
        @AuraEnabled public Decimal sumaAsegurada       { get; set; }
        @AuraEnabled public Decimal presupuesto         { get; set; }
        // Vida / PPR
        @AuraEnabled public String  objetivoPlan        { get; set; }
        @AuraEnabled public String  plazoPlan           { get; set; }
        // Salud / GMM
        @AuraEnabled public String  padecimientos       { get; set; }
        @AuraEnabled public String  hospitales          { get; set; }
        // Fianzas
        @AuraEnabled public String  tipoFianza          { get; set; }
        @AuraEnabled public Decimal pctAfianzar         { get; set; }
        @AuraEnabled public Decimal montoContrato       { get; set; }
        // Nuevos campos por RT
        @AuraEnabled public String  quoteIdExterno      { get; set; }
        @AuraEnabled public String  rfc                 { get; set; }
        @AuraEnabled public String  giroActividad       { get; set; }
        @AuraEnabled public String  ubicacionRiesgo     { get; set; }
        @AuraEnabled public Boolean documentoFuente     { get; set; }
        @AuraEnabled public String  recordTypeId        { get; set; }
        @AuraEnabled public String  recordTypeName      { get; set; }

        public LeadItem(Lead l) {
            this.id          = l.Id;
            this.name        = l.Name;
            this.firstName   = l.FirstName;
            this.lastName    = l.LastName;
            this.leadSource  = l.LeadSource;
            this.status      = l.Status;
            this.statusClass = statusBadge(l.Status);
            this.company     = l.Company;
            this.email       = l.Email;
            this.phone       = l.Phone;
            this.mobilePhone = l.MobilePhone;
            this.title       = l.Title;
            this.owner       = l.Owner != null ? l.Owner.Name : null;
            this.createdDate = l.CreatedDate != null ? String.valueOf(l.CreatedDate.date()) : null;
            this.tipoSeguro  = l.Tipo_de_seguro__c;
            this.monto       = l.Monto__c;
            this.montoFmt    = l.Monto__c != null ? '$' + l.Monto__c.format() : null;
            this.aportacionEstimada = l.Aportacion_Estimada__c;
            this.vendedor    = l.Owner != null ? l.Owner.Name : null;
            this.vendedorId  = l.OwnerId;
            this.motivoNoCalif    = l.Motivo_No_Calificacion__c;
            this.puedeReactivarse = l.Puede_Reactivarse__c;
            this.genero              = l.Genero__c;
            this.sexo                = l.Sexo__c;
            this.fechaNacimiento     = l.Fecha_de_nacimiento__c != null ? String.valueOf(l.Fecha_de_nacimiento__c) : null;
            this.edadCalculada       = l.Edad_Calculada__c;
            this.fuma                = l.Fuma__c;
            this.curp                = l.CURP__c;
            this.cp                  = l.CP__c;
            this.rating              = l.Rating;
            this.industry            = l.Industry;
            this.regimenesFiscales   = l.Regimenes_Fiscales__c;
            this.tiposContribuyentes = l.tipos_de_contribuyentes__c;
            this.numeroProspecto     = l.NumeroProspecto__c;
            this.techVendedorId      = l.Tech_Vendedor__c;
            this.techVendedor        = l.Tech_Vendedor__r != null ? l.Tech_Vendedor__r.Name : null;
            this.aseguradoraId       = l.Aseguradora__c;
            this.aseguradora         = l.Aseguradora__r  != null ? l.Aseguradora__r.Name  : null;
            this.contratoFlag        = l.Contrato__c;
            this.marca            = l.Marca__c;
            this.modelo           = l.Modelo__c;
            this.anho             = l.Anho__c;
            this.version          = l.Version__c;
            this.uso              = l.Uso__c;
            this.tipoCobertura    = l.Tipo_de_cobertura__c;
            this.sumaAsegurada    = l.Suma_asegurada__c;
            this.presupuesto      = l.Presupuesto__c;
            this.objetivoPlan     = l.ObjetivoPlan__c;
            this.plazoPlan        = l.Plazo_Plan__c;
            this.padecimientos    = l.PadecimientosExistentes__c;
            this.hospitales       = l.HospitalesReferencias__c;
            this.tipoFianza       = l.TipoFianza__c;
            this.pctAfianzar      = l.Porcentaje_de_afianzar__c;
            this.montoContrato    = l.Monto_del_contrato__c;
            this.quoteIdExterno   = l.Quote_ID_Externo__c;
            this.rfc              = l.RFC__c;
            this.giroActividad    = l.Giro_Actividad__c;
            this.ubicacionRiesgo  = l.Ubicacion_Riesgo__c;
            this.documentoFuente  = l.Documento_Fuente_Recibido__c;
            this.recordTypeId     = l.RecordTypeId;
            this.recordTypeName   = l.RecordType != null ? l.RecordType.DeveloperName : null;
            Integer s = l.Score__c != null ? (Integer) l.Score__c : null;
            this.score         = s;
            this.scoreLabel    = s != null ? String.valueOf(s) : '—';
            this.scoreClass    = scoreCss(s);
            this.scoreBarStyle = 'width:' + (s != null ? Math.min(s, 100) : 0) + '%;background:' + scoreColor(s);
        }

        private String statusBadge(String s) {
            if (s == null) return 'vt-badge-gray';
            if (s == 'Calificado')           return 'vt-badge-green';
            if (s == 'No Calificado')        return 'vt-badge-red';
            if (s == 'Transferido a agente') return 'vt-badge-orange';
            if (s == 'Precalificado')        return 'vt-badge-blue';
            return 'vt-badge-gray';
        }

        private String scoreCss(Integer s) {
            if (s == null)  return 'vl-score-none';
            if (s >= 71)    return 'vl-score-green';
            if (s >= 41)    return 'vl-score-orange';
            return 'vl-score-red';
        }

        private String scoreColor(Integer s) {
            if (s == null) return '#d1d5db';
            if (s >= 71)   return '#16a34a';
            if (s >= 41)   return '#d97706';
            return '#dc2626';
        }
    }

    public class AccountItem {
        @AuraEnabled public String  id           { get; set; }
        @AuraEnabled public String  name         { get; set; }
        @AuraEnabled public String  company      { get; set; }
        @AuraEnabled public String  email        { get; set; }
        @AuraEnabled public String  phone        { get; set; }
        @AuraEnabled public String  ciudad       { get; set; }
        @AuraEnabled public String  recordType   { get; set; }
        @AuraEnabled public String  vendedor     { get; set; }
        @AuraEnabled public String  fechaRegistro { get; set; }
        @AuraEnabled public Integer numOpps      { get; set; }

        public AccountItem(Account a) {
            this.id           = a.Id;
            this.name         = a.Name;
            this.email        = a.PersonEmail;
            this.phone        = a.Phone;
            this.ciudad       = a.BillingCity;
            this.recordType   = a.RecordType != null ? a.RecordType.Name : null;
            this.vendedor     = a.Vendedor__r != null ? a.Vendedor__r.Name : null;
            this.fechaRegistro = a.CreatedDate != null ? String.valueOf(a.CreatedDate.date()) : null;
            this.numOpps      = a.Opportunities != null ? a.Opportunities.size() : 0;
            // company: para Person Account el nombre de empresa va en Company (no existe en PA)
            // para cuentas de negocio usamos Name directamente
            this.company      = null;
        }
    }

    public class OppItem {
        @AuraEnabled public String  id               { get; set; }
        @AuraEnabled public String  name             { get; set; }
        @AuraEnabled public String  stageName        { get; set; }
        @AuraEnabled public String  stageClass       { get; set; }
        @AuraEnabled public Decimal amount           { get; set; }
        @AuraEnabled public String  amountFmt        { get; set; }
        @AuraEnabled public String  accountId        { get; set; }
        @AuraEnabled public String  clientName       { get; set; }
        @AuraEnabled public String  vendedorId       { get; set; }
        @AuraEnabled public String  ramo             { get; set; }
        @AuraEnabled public String  subproducto      { get; set; }
        @AuraEnabled public String  vendedor         { get; set; }
        @AuraEnabled public Decimal comision         { get; set; }
        @AuraEnabled public String  tipoOriginador   { get; set; }
        @AuraEnabled public String  closeDate        { get; set; }
        @AuraEnabled public Boolean puedeReactivarse { get; set; }
        @AuraEnabled public String  motivoPerdida    { get; set; }
        @AuraEnabled public String  aseguradora      { get; set; }
        @AuraEnabled public String  notasVendedor    { get; set; }
        @AuraEnabled public String  productoId       { get; set; }
        @AuraEnabled public String  productoName     { get; set; }
        @AuraEnabled public String  institucionId    { get; set; }
        @AuraEnabled public String  institucionName  { get; set; }
        @AuraEnabled public String  metodoPago       { get; set; }
        @AuraEnabled public String  periodoPago      { get; set; }
        @AuraEnabled public String  vigenciaInicio   { get; set; }
        @AuraEnabled public String  vigenciaFin      { get; set; }
        @AuraEnabled public String  polizaRenovar        { get; set; }
        @AuraEnabled public String  polizaRenovarNombre  { get; set; }
        @AuraEnabled public String  cotizacionExterna { get; set; }
        @AuraEnabled public String  contratistaId     { get; set; }
        @AuraEnabled public String  contratistaNombre { get; set; }
        @AuraEnabled public String  contratistaEmail  { get; set; }
        @AuraEnabled public String  beneficiarioId    { get; set; }
        @AuraEnabled public String  beneficiarioNombre { get; set; }
        @AuraEnabled public String  beneficiarioEmail  { get; set; }
        @AuraEnabled public String  prospectoId      { get; set; }
        @AuraEnabled public String  prospectoName    { get; set; }
        @AuraEnabled public String  recordTypeId     { get; set; }
        @AuraEnabled public String  recordTypeName   { get; set; }
        // Nuevos campos
        @AuraEnabled public String  oppType          { get; set; }
        @AuraEnabled public String  leadSource       { get; set; }
        @AuraEnabled public Decimal probability      { get; set; }
        @AuraEnabled public String  motivoPerdidaEs  { get; set; }
        @AuraEnabled public String  nextStep         { get; set; }
        @AuraEnabled public String  description      { get; set; }
        @AuraEnabled public String  fechaInicioVig   { get; set; }
        @AuraEnabled public String  fechaFinVig      { get; set; }
        @AuraEnabled public Decimal vigencia         { get; set; }
        @AuraEnabled public Decimal numeroPagos      { get; set; }
        @AuraEnabled public Decimal anoVehiculo      { get; set; }
        @AuraEnabled public String  modeloVehiculo   { get; set; }
        @AuraEnabled public String  urlPoliza        { get; set; }

        public OppItem(Opportunity o) {
            this.id               = o.Id;
            this.name             = o.Name;
            this.stageName        = o.StageName;
            this.stageClass       = stageBadge(o.StageName);
            this.amount           = o.Amount;
            this.amountFmt        = o.Amount != null ? '$' + o.Amount.format() : null;
            this.accountId        = o.AccountId;
            this.clientName       = o.Account != null ? o.Account.Name : null;
            this.vendedorId       = o.Vendedor_A__c;
            this.ramo             = o.Ramo__c;
            this.subproducto      = o.Subproducto__c;
            this.vendedor         = o.Vendedor_A__r != null ? (o.Vendedor_A__r.Name__c != null ? o.Vendedor_A__r.Name__c : o.Vendedor_A__r.Name) : null;
            this.comision         = o.PctComisionOllin__c;
            this.tipoOriginador   = o.Tipo_Originador__c;
            this.closeDate        = o.CloseDate != null ? String.valueOf(o.CloseDate) : null;
            this.puedeReactivarse  = o.Puede_Reactivarse__c;
            this.motivoPerdida     = o.Loss_Reason__c;
            this.aseguradora       = o.Aseguradora_Competidora__c;
            this.notasVendedor     = o.Notas_Vendedor__c;
            this.productoId        = o.Producto__c;
            this.productoName      = o.Producto__r != null ? o.Producto__r.Name : null;
            this.institucionId     = o.Institucion__c;
            this.institucionName   = o.Institucion__r != null ? o.Institucion__r.Name : null;
            this.metodoPago        = o.Metodo_Pago__c;
            this.periodoPago       = o.Periodo_Pago__c;
            this.vigenciaInicio    = o.Vigencia_Inicio__c != null ? String.valueOf(o.Vigencia_Inicio__c) : null;
            this.vigenciaFin       = o.Vigencia_Fin__c    != null ? String.valueOf(o.Vigencia_Fin__c)    : null;
            this.polizaRenovar        = o.Poliza_Renovar__c;
            this.polizaRenovarNombre  = o.Poliza_Renovar__r != null
                ? (String.isNotBlank(o.Poliza_Renovar__r.Numero_poliza__c) ? o.Poliza_Renovar__r.Numero_poliza__c : o.Poliza_Renovar__r.Name)
                : null;
            this.cotizacionExterna = o.Cotizacion_Externa_Id__c;
            this.contratistaId      = o.Contratista__c;
            this.contratistaNombre  = o.Contratista__r  != null ? o.Contratista__r.Name        : null;
            this.contratistaEmail   = o.Contratista__r  != null ? o.Contratista__r.PersonEmail : null;
            this.beneficiarioId     = o.Beneficiario__c;
            this.beneficiarioNombre = o.Beneficiario__r != null ? o.Beneficiario__r.Name        : null;
            this.beneficiarioEmail  = o.Beneficiario__r != null ? o.Beneficiario__r.PersonEmail : null;
            this.prospectoId       = o.Prospecto__c;
            this.prospectoName     = o.Prospecto__r != null ? o.Prospecto__r.Name : null;
            this.recordTypeId      = o.RecordTypeId;
            this.recordTypeName    = o.RecordType != null ? o.RecordType.DeveloperName : null;
            this.oppType           = o.Type;
            this.leadSource        = o.LeadSource;
            this.probability       = o.Probability;
            this.motivoPerdidaEs   = o.Motivo_Perdida__c;
            this.nextStep          = o.NextStep;
            this.description       = o.Description;
            this.fechaInicioVig    = o.Fecha_Inicio_Vigencia__c != null ? String.valueOf(o.Fecha_Inicio_Vigencia__c) : null;
            this.fechaFinVig       = o.Fecha_Fin_Vigencia__c    != null ? String.valueOf(o.Fecha_Fin_Vigencia__c)    : null;
            this.vigencia          = o.Vigencia__c;
            this.numeroPagos       = o.Numero_Pagos__c;
            this.anoVehiculo       = o.Ano_vehiculo__c;
            this.modeloVehiculo    = o.Modelo__c;
            this.urlPoliza         = o.URL_Poliza__c;
        }

        private String stageBadge(String s) {
            if (s == null) return 'vt-badge-gray';
            if (s == 'Cierre ganado')  return 'vt-badge-green';
            if (s == 'Cierre perdido') return 'vt-badge-red';
            if (s == 'Seguimiento' || s == 'Negociación') return 'vt-badge-orange';
            if (s == 'Propuesta enviada / presentada')    return 'vt-badge-blue';
            return 'vt-badge-gray';
        }
    }
}