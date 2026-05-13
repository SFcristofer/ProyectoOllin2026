import { LightningElement, api, track, wire } from 'lwc';
import crearOportunidad              from '@salesforce/apex/TechVentasController.crearOportunidad';
import crearOportunidadDesdeLeadId   from '@salesforce/apex/TechVentasController.crearOportunidadDesdeLeadId';
import crearLead                     from '@salesforce/apex/TechVentasController.crearLead';
import actualizarOportunidad         from '@salesforce/apex/TechVentasController.actualizarOportunidad';
import actualizarLead                from '@salesforce/apex/TechVentasController.actualizarLead';
import searchAccounts                from '@salesforce/apex/TechVentasController.searchAccounts';
import searchSeguros                 from '@salesforce/apex/TechVentasController.searchSeguros';
import searchVendedores              from '@salesforce/apex/TechVentasController.searchVendedores';
import searchProducts                from '@salesforce/apex/TechVentasController.searchProducts';
import getLeadRecordTypes            from '@salesforce/apex/TechVentasController.getLeadRecordTypes';
import getOppRecordTypes             from '@salesforce/apex/TechVentasController.getOppRecordTypes';
import tienePrecalificacionProspecto from '@salesforce/apex/TechPrecalificacionController.tienePrecalificacionProspecto';

const RAMO_MAP = {
    'Seguros de auto': 'Auto',
    'Vida':            'Vida',
    'Gastos Médicos':  'GMM',
    'Daños':           'Danos',
    'Fianzas':         'Fianzas',
};

// Lead RT dev name → Tipo_de_seguro__c value
const LEAD_RT_TO_TIPO = {
    'Auto':           'Seguros de auto',
    'GMM':            'Gastos Médicos',
    'Vida_PPR':       'Vida',
    'Danos':          'Daños',
    'Fianzas':        'Fianzas',
    'Membresia_Ollin': '',
};

const EMPTY_OPP = () => ({
    Name: '', StageName: 'Oportunidad creada', CloseDate: '',
    Type: '', LeadSource: '',
    Ramo__c: '', Subproducto__c: '', Amount: null, PctComisionOllin__c: null,
    Tipo_Originador__c: '',
    Motivo_Perdida__c: '', Aseguradora_Competidora__c: '',
    Puede_Reactivarse__c: false, Notas_Vendedor__c: '', NextStep: '', Description: '',
    Metodo_Pago__c: '', Periodo_Pago__c: '',
    Fecha_Inicio_Vigencia__c: '', Vigencia__c: null,
    Fecha_Fin_Vigencia__c: '', Numero_Pagos__c: null,
    Poliza_Renovar__c: '',
    Cotizacion_Externa_Id__c: '', Ano_vehiculo__c: null, Modelo__c: '',
    URL_Poliza__c: ''
});

const EMPTY_LEAD = () => ({
    FirstName: '', LastName: '', Company: '', Title: '',
    Email: '', Phone: '', MobilePhone: '',
    LeadSource: '', Status: 'Nuevo',
    Tipo_de_seguro__c: '',
    Genero__c: '', Fecha_de_nacimiento__c: '', Fuma__c: false,
    RFC__c: '', CURP__c: '', CP__c: '',
    Rating: '', Industry: '',
    Regimenes_Fiscales__c: '', tipos_de_contribuyentes__c: '',
    Score__c: null, NumeroProspecto__c: null, Edad_Calculada__c: null,
    Monto__c: null, Suma_asegurada__c: null,
    Aportacion_Estimada__c: null, Presupuesto__c: null,
    Marca__c: '', Modelo__c: '', Anho__c: null, Version__c: '',
    Uso__c: '', Tipo_de_cobertura__c: '',
    ObjetivoPlan__c: '', Plazo_Plan__c: '',
    PadecimientosExistentes__c: '', HospitalesReferencias__c: '',
    TipoFianza__c: '', Porcentaje_de_afianzar__c: null, Monto_del_contrato__c: null,
    Contrato__c: false,
    Motivo_No_Calificacion__c: '', Puede_Reactivarse__c: false,
    Quote_ID_Externo__c: '', Giro_Actividad__c: '',
    Ubicacion_Riesgo__c: '', Documento_Fuente_Recibido__c: false
});

export default class TechVentasCreateModal extends LightningElement {

    @wire(getLeadRecordTypes) leadRecordTypes;
    @wire(getOppRecordTypes)  oppRecordTypes;

    // Setters para que _populate() se dispare sin importar el orden de asignación LWC
    @api
    set editRecord(val) {
        this._editRecord = val;
        if (this._isOpen) this._populate();
    }
    get editRecord() { return this._editRecord; }
    _editRecord = null;

    @api
    set editLeadRecord(val) {
        this._editLeadRecord = val;
        if (this._isOpen) this._populate();
    }
    get editLeadRecord() { return this._editLeadRecord; }
    _editLeadRecord = null;

    @api
    set prefillLeadData(val) {
        this._prefillLeadData = val;
        if (this._isOpen && val) this._populateFromLead(val);
    }
    get prefillLeadData() { return this._prefillLeadData; }
    _prefillLeadData = null;

    @api   initialType  = 'opp';
    @track type                 = 'opp';
    @track isSaving             = false;
    @track oppData              = EMPTY_OPP();
    @track polizaRenovarNombre  = '';

    // Lookup póliza a renovar
    @track selectedPolizaRenovar = { id: '', name: '' };
    @track seguroSearch          = '';
    @track seguroResults         = [];
    @track leadData     = EMPTY_LEAD();
    @track formErrors   = [];

    // RT seleccionado
    @track selectedLeadRT = { id: '', dev: '', name: '' };
    @track selectedOppRT  = { id: '', dev: '', name: '' };

    // Lookups compartidos
    @track selectedAccount     = { id: '', name: '' };
    @track selectedVendedor    = { id: '', name: '' };
    @track selectedInstitucion = { id: '', name: '' };
    @track selectedContratista  = { id: '', name: '' };
    @track selectedBeneficiario = { id: '', name: '' };
    @track selectedProspecto    = { id: '', name: '' };
    @track selectedAseguradora  = { id: '', name: '' };
    @track selectedProducto     = { id: '', name: '' };

    @track accountSearch       = '';
    @track vendedorSearch      = '';
    @track institucionSearch   = '';
    @track contratistaSearch   = '';
    @track beneficiarioSearch  = '';
    @track aseguradoraSearch   = '';
    @track productoSearch      = '';

    @track accountResults      = [];
    @track vendedorResults     = [];
    @track institucionResults  = [];
    @track contratistaResults  = [];
    @track beneficiarioResults = [];
    @track aseguradoraResults  = [];
    @track productoResults     = [];

    _searchTimers = {};

    connectedCallback() { this._populate(); }

    renderedCallback() {
        if (this.isLead) {
            this._setSelect('Status',                    this.leadData.Status);
            this._setSelect('LeadSource',                this.leadData.LeadSource);
            this._setSelect('Tipo_de_seguro__c',         this.leadData.Tipo_de_seguro__c);
            this._setSelect('Genero__c',                 this.leadData.Genero__c);
            this._setSelect('Rating',                    this.leadData.Rating);
            this._setSelect('Industry',                  this.leadData.Industry);
            this._setSelect('Regimenes_Fiscales__c',     this.leadData.Regimenes_Fiscales__c);
            this._setSelect('tipos_de_contribuyentes__c', this.leadData.tipos_de_contribuyentes__c);
            this._setSelect('Uso__c',                    this.leadData.Uso__c);
            this._setSelect('Tipo_de_cobertura__c',      this.leadData.Tipo_de_cobertura__c);
            this._setSelect('ObjetivoPlan__c',           this.leadData.ObjetivoPlan__c);
            this._setSelect('Plazo_Plan__c',             this.leadData.Plazo_Plan__c);
            this._setSelect('Motivo_No_Calificacion__c', this.leadData.Motivo_No_Calificacion__c);
        } else {
            this._setSelect('Type',               this.oppData.Type);
            this._setSelect('Ramo__c',            this.oppData.Ramo__c);
            this._setSelect('StageName',          this.oppData.StageName);
            this._setSelect('LeadSource',         this.oppData.LeadSource);
            this._setSelect('Tipo_Originador__c', this.oppData.Tipo_Originador__c);
            this._setSelect('Motivo_Perdida__c',  this.oppData.Motivo_Perdida__c);
            this._setSelect('Metodo_Pago__c',     this.oppData.Metodo_Pago__c);
            this._setSelect('Periodo_Pago__c',    this.oppData.Periodo_Pago__c);
        }
    }

    _setSelect(field, value) {
        if (value == null || value === '') return;
        const el = this.template.querySelector(`[data-field="${field}"]`);
        if (el && el.tagName === 'SELECT') el.value = value;
    }

    @api
    set isOpen(val) {
        this._isOpen = val;
        if (val) this._populate();
    }
    get isOpen() { return this._isOpen; }
    _isOpen = false;

    _populateFromLead(lead) {
        this.type = 'opp';
        this.oppData = {
            ...EMPTY_OPP(),
            Name:      `${lead.name || lead.firstName || ''} - ${lead.tipoSeguro || 'Oportunidad'}`,
            Ramo__c:   RAMO_MAP[lead.tipoSeguro] || '',
            Amount:    lead.monto   || null,
            LeadSource: lead.leadSource || '',
        };
        if (lead.vendedorId) this.selectedVendedor  = { id: lead.vendedorId, name: lead.vendedor || '' };
        if (lead.id)         this.selectedProspecto = { id: lead.id, name: lead.name || '' };
    }

    _populate() {
        if (this._prefillLeadData) {
            this._populateFromLead(this._prefillLeadData);
        } else if (this._editLeadRecord) {
            const l = this._editLeadRecord;
            this.type = 'lead';
            this.leadData = {
                FirstName:                  l.firstName          || '',
                LastName:                   l.lastName           || '',
                Company:                    l.company            || '',
                Title:                      l.title              || '',
                Email:                      l.email              || '',
                Phone:                      l.phone              || '',
                MobilePhone:                l.mobilePhone        || '',
                LeadSource:                 l.leadSource         || '',
                Status:                     l.status             || 'Nuevo',
                Tipo_de_seguro__c:          l.tipoSeguro         || '',
                Monto__c:                   l.monto              || null,
                Suma_asegurada__c:          l.sumaAsegurada      || null,
                Aportacion_Estimada__c:     l.aportacionEstimada || null,
                Presupuesto__c:             l.presupuesto        || null,
                Genero__c:                  l.genero             || '',
                Fecha_de_nacimiento__c:     l.fechaNacimiento    || '',
                Fuma__c:                    l.fuma               || false,
                RFC__c:                     l.rfc                || '',
                CURP__c:                    l.curp               || '',
                CP__c:                      l.cp                 || '',
                Rating:                     l.rating             || '',
                Industry:                   l.industry           || '',
                Regimenes_Fiscales__c:      l.regimenesFiscales  || '',
                tipos_de_contribuyentes__c: l.tiposContribuyentes || '',
                Score__c:                   l.score              || null,
                NumeroProspecto__c:         l.numeroProspecto    || null,
                Edad_Calculada__c:          l.edadCalculada      || null,
                Contrato__c:                l.contratoFlag       || false,
                Marca__c:                   l.marca              || '',
                Modelo__c:                  l.modelo             || '',
                Anho__c:                    l.anho               || null,
                Version__c:                 l.version            || '',
                Uso__c:                     l.uso                || '',
                Tipo_de_cobertura__c:       l.tipoCobertura      || '',
                ObjetivoPlan__c:            l.objetivoPlan       || '',
                Plazo_Plan__c:              l.plazoPlan          || '',
                PadecimientosExistentes__c: l.padecimientos      || '',
                HospitalesReferencias__c:   l.hospitales         || '',
                TipoFianza__c:              l.tipoFianza         || '',
                Porcentaje_de_afianzar__c:  l.pctAfianzar        || null,
                Monto_del_contrato__c:      l.montoContrato      || null,
                Motivo_No_Calificacion__c:  l.motivoNoCalif      || '',
                Puede_Reactivarse__c:       l.puedeReactivarse   || false,
                Quote_ID_Externo__c:        l.quoteIdExterno     || '',
                Giro_Actividad__c:          l.giroActividad      || '',
                Ubicacion_Riesgo__c:        l.ubicacionRiesgo    || '',
                Documento_Fuente_Recibido__c: l.documentoFuente  || false
            };
            if (l.techVendedorId) this.selectedVendedor   = { id: l.techVendedorId, name: l.techVendedor || '' };
            if (l.aseguradoraId)  this.selectedAseguradora = { id: l.aseguradoraId,  name: l.aseguradora  || '' };
            if (l.recordTypeId)   this.selectedLeadRT = { id: l.recordTypeId, dev: l.recordTypeName || '', name: l.recordTypeName || '' };
        } else if (this._editRecord) {
            const o = this._editRecord;
            this.type = 'opp';
            this.oppData = {
                Name:                       o.name              || '',
                StageName:                  o.stageName         || 'Oportunidad creada',
                CloseDate:                  o.closeDate         || '',
                Type:                       o.oppType           || '',
                LeadSource:                 o.leadSource        || '',
                Ramo__c:                    o.ramo              || '',
                Subproducto__c:             o.subproducto       || '',
                Amount:                     o.amount            || null,
                PctComisionOllin__c:        o.comision          || null,
                Tipo_Originador__c:         o.tipoOriginador    || '',
                Motivo_Perdida__c:          o.motivoPerdidaEs   || '',
                Aseguradora_Competidora__c: o.aseguradora       || '',
                Puede_Reactivarse__c:       o.puedeReactivarse  || false,
                Notas_Vendedor__c:          o.notasVendedor     || '',
                NextStep:                   o.nextStep          || '',
                Description:                o.description       || '',
                Metodo_Pago__c:             o.metodoPago        || '',
                Periodo_Pago__c:            o.periodoPago       || '',
                Fecha_Inicio_Vigencia__c:   o.fechaInicioVig    || '',
                Fecha_Fin_Vigencia__c:      o.fechaFinVig       || '',
                Vigencia__c:                o.vigencia          || null,
                Numero_Pagos__c:            o.numeroPagos       || null,
                Poliza_Renovar__c:          o.polizaRenovar     || '',
                Cotizacion_Externa_Id__c:   o.cotizacionExterna || '',
                Ano_vehiculo__c:            o.anoVehiculo       || null,
                Modelo__c:                  o.modeloVehiculo    || '',
                URL_Poliza__c:              o.urlPoliza         || ''
            };
            this.polizaRenovarNombre = o.polizaRenovarNombre || '';
            if (o.polizaRenovar) this.selectedPolizaRenovar = { id: o.polizaRenovar, name: o.polizaRenovarNombre || o.polizaRenovar };
            if (o.accountId)      this.selectedAccount    = { id: o.accountId,      name: o.clientName      || '' };
            if (o.vendedorId)     this.selectedVendedor   = { id: o.vendedorId,     name: o.vendedor        || '' };
            if (o.productoId)     this.selectedProducto   = { id: o.productoId,     name: o.productoName    || '' };
            if (o.institucionId)  this.selectedInstitucion = { id: o.institucionId, name: o.institucionName || '' };
            if (o.contratistaId)  this.selectedContratista  = { id: o.contratistaId,  name: o.contratistaNombre  || o.contratistaId,  sub: o.contratistaEmail  || '' };
            if (o.beneficiarioId) this.selectedBeneficiario = { id: o.beneficiarioId, name: o.beneficiarioNombre || o.beneficiarioId, sub: o.beneficiarioEmail || '' };
            if (o.prospectoId)    this.selectedProspecto  = { id: o.prospectoId,    name: o.prospectoName || '' };
            if (o.recordTypeId)   this.selectedOppRT = { id: o.recordTypeId, dev: o.recordTypeName || '', name: o.recordTypeName || '' };
        } else {
            this._reset();
        }
    }

    /* ── Getters ── */
    get isFromLead()      { return !!this._prefillLeadData; }
    get isEdit()          { return !!(this._editRecord || this._editLeadRecord); }
    get isLeadEdit()      { return !!this._editLeadRecord; }
    get isOppEdit()       { return !!this._editRecord; }
    get isLead()          { return this.type === 'lead'; }
    get modalTitle() {
        if (this.isFromLead) return 'Crear Oportunidad desde Lead';
        if (this.isLeadEdit) return 'Editar Lead';
        if (this.isOppEdit)  return 'Editar Oportunidad';
        return this.isLead ? 'Nuevo Lead' : 'Nueva Oportunidad';
    }
    get typeLabel()  { return (this.isOppEdit || this.isFromLead || !this.isLead) ? 'Opportunity' : 'Lead'; }
    get headerIcon() { return (this.isEdit || this.isFromLead) ? 'utility:opportunity' : 'utility:add'; }
    get saveLabel()  { return this.isEdit ? 'Guardar cambios' : 'Guardar'; }
    get isCierrePerdido() { return this.oppData.StageName === 'Cierre perdido'; }
    get isLeadNoCalif()   { return this.leadData.Status === 'No Calificado'; }

    // Secciones Lead por tipo de seguro
    get isLeadAuto()    { return this.leadData.Tipo_de_seguro__c === 'Seguros de auto'; }
    get isLeadVida()    { return this.leadData.Tipo_de_seguro__c === 'Vida'; }
    get isLeadGMM()     { return this.leadData.Tipo_de_seguro__c === 'Gastos Médicos'; }
    get isLeadFianzas() { return this.leadData.Tipo_de_seguro__c === 'Fianzas'; }
    get isLeadDanos()   { return this.leadData.Tipo_de_seguro__c === 'Daños'; }
    get isLeadMembresia() { return this.selectedLeadRT.dev === 'Membresia_Ollin'; }

    // Secciones Opp por RT
    get isOppSeguroNuevo()        { return this.selectedOppRT.dev === 'Seguro_Nuevo'; }
    get isOppFianzaNueva()        { return this.selectedOppRT.dev === 'Fianza_Nueva'; }
    get isOppRenovacion()         { return this.selectedOppRT.dev === 'Renovacion_Seguro'; }
    get isOppClienteExistente()   { return this.selectedOppRT.dev === 'Cliente_Existente_Nuevo_Producto'; }
    get showOppExtraFields()      { return !!(this.selectedOppRT.dev); }

    // Computed lists for RT chips
    get leadRTList() {
        return (this.leadRecordTypes?.data || []).map(rt => ({
            ...rt,
            chipClass: 'vm-rt-chip' + (this.selectedLeadRT.id === rt.id ? ' vm-rt-chip-active' : '')
        }));
    }
    get oppRTList() {
        return (this.oppRecordTypes?.data || []).map(rt => ({
            ...rt,
            chipClass: 'vm-rt-chip' + (this.selectedOppRT.id === rt.id ? ' vm-rt-chip-active' : '')
        }));
    }

    get btnLeadClass() { return 'vm-type-btn' + (this.isLead  ? ' vm-type-active' : ''); }
    get btnOppClass()  { return 'vm-type-btn' + (!this.isLead ? ' vm-type-active' : ''); }

    get hasProspecto()           { return !!this.selectedProspecto.id; }
    get hasFormErrors()          { return this.formErrors.length > 0; }
    get isOppAuto()              { return this.oppData.Ramo__c === 'Auto'; }

    get hasAccountResults()      { return this.accountResults.length     > 0; }
    get hasVendedorResults()     { return this.vendedorResults.length    > 0; }
    get hasInstitucionResults()  { return this.institucionResults.length  > 0; }
    get hasContratistaResults()  { return this.contratistaResults.length  > 0; }
    get hasBeneficiarioResults() { return this.beneficiarioResults.length > 0; }
    get hasAseguradoraResults()  { return this.aseguradoraResults.length  > 0; }
    get hasProductoResults()     { return this.productoResults.length     > 0; }
    get hasSeguroResults()       { return this.seguroResults.length       > 0; }

    /* ── Type toggle ── */
    handleTypeChange(e) { this.type = e.currentTarget.dataset.type; }

    /* ── RT chip selection ── */
    handleLeadRTSelect(e) {
        const id   = e.currentTarget.dataset.id;
        const dev  = e.currentTarget.dataset.dev;
        const name = e.currentTarget.dataset.name;
        this.selectedLeadRT = { id, dev, name };
        // Auto-sync Tipo_de_seguro__c
        const tipo = LEAD_RT_TO_TIPO[dev] ?? '';
        this.leadData = { ...this.leadData, Tipo_de_seguro__c: tipo };
    }

    handleOppRTSelect(e) {
        const id   = e.currentTarget.dataset.id;
        const dev  = e.currentTarget.dataset.dev;
        const name = e.currentTarget.dataset.name;
        this.selectedOppRT = { id, dev, name };
        // Sincronizar Ramo__c según el tipo de oportunidad
        if (dev === 'Fianza_Nueva') {
            this.oppData = { ...this.oppData, Ramo__c: 'Fianzas' };
        } else if (this.oppData.Ramo__c === 'Fianzas') {
            this.oppData = { ...this.oppData, Ramo__c: '' };
        }
    }

    /* ── Field handlers ── */
    handleLeadField(e) {
        const f = e.currentTarget.dataset.field;
        const numFields = ['Monto__c','Suma_asegurada__c','Aportacion_Estimada__c',
                           'Presupuesto__c','Anho__c','Porcentaje_de_afianzar__c','Monto_del_contrato__c','Score__c'];
        const v = numFields.includes(f)
            ? (e.target.value !== '' ? parseFloat(e.target.value) : null)
            : e.target.value;
        this.leadData = { ...this.leadData, [f]: v };
    }
    handleLeadCheckbox(e) {
        this.leadData = { ...this.leadData, [e.currentTarget.dataset.field]: e.target.checked };
    }
    handleOppField(e) {
        const f = e.currentTarget.dataset.field;
        const numFields = ['Amount', 'PctComisionOllin__c',
                           'Vigencia__c', 'Ano_vehiculo__c', 'Numero_Pagos__c'];
        const v = numFields.includes(f)
            ? (e.target.value !== '' ? parseFloat(e.target.value) : null)
            : e.target.value;
        this.oppData = { ...this.oppData, [f]: v };
    }
    handleOppCheckbox(e) {
        this.oppData = { ...this.oppData, [e.currentTarget.dataset.field]: e.target.checked };
    }

    /* ── Lookups ── */
    handleAccountSearch(e)      { this.accountSearch      = e.target.value; this._debounceSearch('account',      e.target.value); }
    handleSeguroSearch(e) {
        this.seguroSearch = e.target.value;
        clearTimeout(this._searchTimers['seguro']);
        if (!this.seguroSearch || this.seguroSearch.length < 2) { this.seguroResults = []; return; }
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._searchTimers['seguro'] = setTimeout(() => {
            searchSeguros({ term: this.seguroSearch }).then(r => { this.seguroResults = r; });
        }, 300);
    }
    handleVendedorSearch(e)     { this.vendedorSearch     = e.target.value; this._debounceSearch('vendedor',     e.target.value); }
    handleInstitucionSearch(e)  { this.institucionSearch  = e.target.value; this._debounceSearch('institucion',  e.target.value); }
    handleContratistaSearch(e)  { this.contratistaSearch  = e.target.value; this._debounceSearch('contratista',  e.target.value); }
    handleBeneficiarioSearch(e) { this.beneficiarioSearch = e.target.value; this._debounceSearch('beneficiario', e.target.value); }
    handleAseguradoraSearch(e)  { this.aseguradoraSearch  = e.target.value; this._debounceSearch('aseguradora',  e.target.value); }
    handleProductoSearch(e)     { this.productoSearch     = e.target.value; this._debounceSearch('producto',     e.target.value); }

    _debounceSearch(type, term) {
        clearTimeout(this._searchTimers[type]);
        if (!term || term.length < 2) {
            this[`${type}Results`] = [];
            return;
        }
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._searchTimers[type] = setTimeout(() => {
            if (type === 'vendedor') {
                searchVendedores({ term }).then(r => { this.vendedorResults = r; });
            } else if (type === 'producto') {
                searchProducts({
                    term,
                    ramo:        this.oppData.Ramo__c         || '',
                    institucionId: this.selectedInstitucion.id || ''
                }).then(r => { this.productoResults = r; });
            } else {
                searchAccounts({ term }).then(r => { this[`${type}Results`] = r; });
            }
        }, 300);
    }

    selectLookup(e) {
        const id   = e.currentTarget.dataset.id;
        const name = e.currentTarget.dataset.name;
        const type = e.currentTarget.dataset.type;
        this[`selected${type.charAt(0).toUpperCase() + type.slice(1)}`] = { id, name };
        this[`${type}Search`]   = '';
        this[`${type}Results`]  = [];
    }

    clearAccount()      { this.selectedAccount     = { id: '', name: '' }; this.accountSearch      = ''; this.accountResults      = []; }
    clearVendedor()     { this.selectedVendedor    = { id: '', name: '' }; this.vendedorSearch     = ''; this.vendedorResults     = []; }
    clearInstitucion()  { this.selectedInstitucion = { id: '', name: '' }; this.institucionSearch  = ''; this.institucionResults  = []; }
    clearContratista()  { this.selectedContratista = { id: '', name: '' }; this.contratistaSearch  = ''; this.contratistaResults  = []; }
    clearBeneficiario() { this.selectedBeneficiario = { id: '', name: '' }; this.beneficiarioSearch = ''; this.beneficiarioResults = []; }
    clearAseguradora()  { this.selectedAseguradora  = { id: '', name: '' }; this.aseguradoraSearch  = ''; this.aseguradoraResults  = []; }
    clearProducto()     { this.selectedProducto     = { id: '', name: '' }; this.productoSearch     = ''; this.productoResults     = []; }
    clearPolizaRenovar() { this.selectedPolizaRenovar = { id: '', name: '' }; this.seguroSearch = ''; this.seguroResults = []; }
    selectSeguro(e) {
        const id   = e.currentTarget.dataset.id;
        const name = e.currentTarget.dataset.name;
        this.selectedPolizaRenovar = { id, name };
        this.seguroSearch  = '';
        this.seguroResults = [];
    }

    /* ── Validation ── */
    _validate() {
        const errors = [];
        if (this.isLead) {
            if (!this.selectedLeadRT.id)          errors.push('Debes seleccionar un tipo de registro (Lead)');
            if (!this.leadData.LastName?.trim())  errors.push('Apellido es requerido');
            if (!this.leadData.Status)            errors.push('Estatus es requerido');
        } else {
            if (!this.oppData.Name?.trim())       errors.push('Nombre de la oportunidad es requerido');
            if (!this.oppData.CloseDate)          errors.push('Fecha de cierre es requerida');
            if (!this.oppData.StageName)          errors.push('Etapa es requerida');
            if (this.isCierrePerdido && !this.oppData.Motivo_Perdida__c)
                errors.push('Motivo de pérdida es requerido para cierre perdido');
        }
        return errors;
    }

    /* ── Save ── */
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    async handleSave() {
        const errors = this._validate();
        if (errors.length > 0) { this.formErrors = errors; return; }

        // Fianza + Prospecto → verificar precalificación antes de guardar
        if (!this.isLead && this.isOppFianzaNueva && this.selectedProspecto.id) {
            this.isSaving = true;
            let tienePrecal = false;
            try {
                tienePrecal = await tienePrecalificacionProspecto({ prospectoId: this.selectedProspecto.id });
            } catch (e) {
                tienePrecal = false;
            }
            this.isSaving = false;
            if (!tienePrecal) {
                this.formErrors = ['El prospecto no tiene ninguna precalificación registrada. Precalifica al prospecto antes de crear una fianza.'];
                return;
            }
        }

        this.formErrors = [];
        if (this.isLead) { this._saveLead(); } else { this._saveOpp(); }
    }

    _saveLead() {
        this.isSaving = true;
        // eslint-disable-next-line no-unused-vars
        const { NumeroProspecto__c, Edad_Calculada__c, ...saveableLeadData } = this.leadData;
        const record = {
            sobjectType: 'Lead',
            ...saveableLeadData,
            Tech_Vendedor__c: this.selectedVendedor.id    || null,
            Aseguradora__c:   this.selectedAseguradora.id  || null,
            ...(this.selectedLeadRT.id ? { RecordTypeId: this.selectedLeadRT.id } : {})
        };
        const action = this.isLeadEdit
            ? actualizarLead({ lead: { ...record, Id: this._editLeadRecord.id } })
            : crearLead({ lead: record });
        action
            .then(() => this._onSaved())
            .catch(e => { this._toast(e.body?.message || 'Error al guardar lead'); this.isSaving = false; });
    }

    _saveOpp() {
        const record = {
            sobjectType:                'Opportunity',
            Name:                       this.oppData.Name,
            StageName:                  this.oppData.StageName,
            CloseDate:                  this.oppData.CloseDate,
            Type:                       this.oppData.Type                       || null,
            LeadSource:                 this.oppData.LeadSource                 || null,
            AccountId:                  this.selectedAccount.id                 || null,
            Vendedor_A__c:              this.selectedVendedor.id                || null,
            Institucion__c:             this.selectedInstitucion.id             || null,
            Contratista__c:             this.selectedContratista.id             || null,
            Beneficiario__c:            this.selectedBeneficiario.id            || null,
            Prospecto__c:               this.selectedProspecto.id               || null,
            RecordTypeId:               this.selectedOppRT.id                   || null,
            Ramo__c:                    this.oppData.Ramo__c                    || null,
            Subproducto__c:             this.oppData.Subproducto__c             || null,
            Amount:                     this.oppData.Amount,
            PctComisionOllin__c:        this.oppData.PctComisionOllin__c,
            Tipo_Originador__c:         this.oppData.Tipo_Originador__c         || null,
            Motivo_Perdida__c:          this.oppData.Motivo_Perdida__c          || null,
            Aseguradora_Competidora__c: this.oppData.Aseguradora_Competidora__c || null,
            Puede_Reactivarse__c:       this.oppData.Puede_Reactivarse__c,
            Notas_Vendedor__c:          this.oppData.Notas_Vendedor__c          || null,
            NextStep:                   this.oppData.NextStep                   || null,
            Description:                this.oppData.Description                || null,
            Producto__c:                this.selectedProducto.id                || null,
            Metodo_Pago__c:             this.oppData.Metodo_Pago__c             || null,
            Periodo_Pago__c:            this.oppData.Periodo_Pago__c            || null,
            Fecha_Inicio_Vigencia__c:   this.oppData.Fecha_Inicio_Vigencia__c   || null,
            Vigencia__c:                this.oppData.Vigencia__c,
            Vigencia_Inicio__c:         this.oppData.Fecha_Inicio_Vigencia__c   || null,
            Poliza_Renovar__c:          this.selectedPolizaRenovar.id           || null,
            Cotizacion_Externa_Id__c:   this.oppData.Cotizacion_Externa_Id__c   || null,
            Ano_vehiculo__c:            this.oppData.Ano_vehiculo__c,
            Modelo__c:                  this.oppData.Modelo__c                  || null,
            URL_Poliza__c:              this.oppData.URL_Poliza__c              || null
        };
        this.isSaving = true;
        let action;
        if (this.isOppEdit) {
            action = actualizarOportunidad({ opp: { ...record, Id: this._editRecord.id } });
        } else if (this.isFromLead) {
            action = crearOportunidadDesdeLeadId({ leadId: this._prefillLeadData.id, opp: record });
        } else {
            action = crearOportunidad({ opp: record });
        }
        action
            .then(() => this._onSaved())
            .catch(e => { this._toast(e.body?.message || 'Error al guardar oportunidad'); this.isSaving = false; });
    }

    _onSaved() {
        this.isSaving = false;
        this._reset();
        this.dispatchEvent(new CustomEvent('saved'));
    }

    handleOverlayClick(e) { if (e.target === e.currentTarget) this.handleClose(); }
    handleClose() { this._reset(); this.dispatchEvent(new CustomEvent('close')); }

    _reset() {
        this.formErrors          = [];
        this.type                = this.initialType || 'opp';
        this.oppData             = EMPTY_OPP();
        this.leadData            = EMPTY_LEAD();
        this._prefillLeadData    = null;
        this.selectedLeadRT      = { id: '', dev: '', name: '' };
        this.selectedOppRT       = { id: '', dev: '', name: '' };
        this.selectedAccount     = { id: '', name: '' };
        this.selectedVendedor    = { id: '', name: '' };
        this.selectedInstitucion = { id: '', name: '' };
        this.selectedContratista = { id: '', name: '' };
        this.selectedBeneficiario = { id: '', name: '' };
        this.selectedProspecto   = { id: '', name: '' };
        this.selectedAseguradora = { id: '', name: '' };
        this.selectedProducto      = { id: '', name: '' };
        this.selectedPolizaRenovar = { id: '', name: '' };
        this.polizaRenovarNombre   = '';
        this.accountSearch       = '';
        this.vendedorSearch      = '';
        this.institucionSearch   = '';
        this.contratistaSearch   = '';
        this.beneficiarioSearch  = '';
        this.aseguradoraSearch   = '';
        this.productoSearch      = '';
        this.accountResults      = [];
        this.vendedorResults     = [];
        this.institucionResults  = [];
        this.contratistaResults  = [];
        this.beneficiarioResults = [];
        this.aseguradoraResults  = [];
        this.productoResults     = [];
        this.seguroSearch        = '';
        this.seguroResults       = [];
    }

    _toast(msg) {
        this.formErrors = [msg];
        this.dispatchEvent(new CustomEvent('showerror', { detail: msg, bubbles: true }));
    }
}