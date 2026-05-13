import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import getContratosList          from '@salesforce/apex/TechContratoController.getContratosList';
import getConveniosByContrato    from '@salesforce/apex/TechConvenioController.getConveniosByContrato';
import getFianzasByContrato      from '@salesforce/apex/TechContratoController.getFianzasByContrato';

const MONEY = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN', maximumFractionDigits: 0 });
function fmt(v)  { return v == null ? '—' : MONEY.format(v); }
function fmtD(s) { if (!s) return '—'; const p = s.split('-'); return p.length === 3 ? `${p[2]}/${p[1]}/${p[0]}` : s; }
function fmtDate(d) { if (!d) return '—'; const s = typeof d === 'string' ? d : d.format?.() || String(d); return fmtD(s); }

const TEXT_OPS = [{ v: 'contains', l: 'contiene' }, { v: 'eq', l: 'es igual a' }, { v: 'ne', l: 'no es igual a' }];
const EQ_OPS   = [{ v: 'eq', l: 'es igual a' }, { v: 'ne', l: 'es diferente a' }];
function getOps(type) { return type === 'text' ? TEXT_OPS : EQ_OPS; }

const ESTATUS_FIANZA = { 'Vigente': 'vf-badge vf-badge-green', 'Emitida': 'vf-badge vf-badge-blue', 'Cancelada': 'vf-badge vf-badge-gray', 'Vencida': 'vf-badge vf-badge-red' };
const ESTATUS_CONTRATO = { 'Activated': 'vf-badge vf-badge-green', 'Draft': 'vf-badge vf-badge-amber', 'Expired': 'vf-badge vf-badge-red' };
const TIPO_CONVENIO = { 'Ampliación de monto': 'vf-badge vf-badge-blue', 'Ampliación de plazo': 'vf-badge vf-badge-teal', 'Cambio de alcance': 'vf-badge vf-badge-purple', 'Reducción': 'vf-badge vf-badge-amber' };

const FILTER_DEFS = {
    contrato: [{ value: 'name', label: 'No. Contrato', type: 'text' }, { value: 'contratista', label: 'Contratista', type: 'text' }, { value: 'estatus', label: 'Estatus', type: 'text' }],
};

export default class TechVentasFianzas extends LightningElement {
    @track activeSubTab      = 'contrato';
    @track rows              = [];
    @track selectedId        = null;
    @track panelTab          = 'detalles';
    @track isLoading         = false;
    @track error             = null;
    @track sortField         = '';
    @track sortDir           = 'asc';
    @track showFilters       = false;
    @track filterRules       = [];
    @track showWizardContrato    = false;
    @track showWizardConvenio    = false;
    @track isEditing             = false;
    @track isSavingEdit          = false;
    @track editData              = {};
    @track editContratoForWizard  = null;
    @track editFianzasForWizard   = [];
    @track convenioWizardContrato = null;
    @track panelConvenioEdit      = null;
    _wizardIsEdit = false;

    // Panel sub-data (loaded on demand)
    @track panelFianzas    = [];
    @track panelConvenios  = [];

    _ruleCounter = 0;
    _cache       = {};

    connectedCallback() { this._load(); }

    // ── Sub-tab navigation ──────────────────────────────────────────────────────

    handleSubTab(e) {
        const tab = e.currentTarget.dataset.tab;
        if (tab === this.activeSubTab) return;
        this.activeSubTab = tab;
        this.selectedId   = null;
        this.filterRules  = [];
        this.sortField    = '';
        this.sortDir      = 'asc';
        this._load();
    }

    get isTabFianza()   { return this.activeSubTab === 'fianza'; }
    get isTabContrato() { return this.activeSubTab === 'contrato'; }

    get stClassContrato() { return 'vf-subtab vf-subtab-contrato' + (this.isTabContrato ? ' vf-subtab-active vf-subtab-contrato-active' : ''); }
    get stClassFianza()   { return 'vf-subtab vf-subtab-fianza'   + (this.isTabFianza   ? ' vf-subtab-active vf-subtab-fianza-active'   : ''); }

    get tableClass() { return 'vf-table' + (this.isTabContrato ? ' vf-table-contrato' : ''); }

    // ── Load data ───────────────────────────────────────────────────────────────

    async _load() {
        const tab = this.activeSubTab;
        if (tab === 'fianza') return;
        if (this._cache[tab]) { this.rows = this._cache[tab]; return; }
        this.isLoading = true;
        this.error     = null;
        try {
            const raw = tab === 'contrato' ? await getContratosList() : [];
            this.rows = this._mapRows(raw || []);
            this._cache[tab] = this.rows;
        } catch (e) {
            this.error = e?.body?.message || 'Error al cargar datos';
        } finally {
            this.isLoading = false;
        }
    }

    _mapRows(raw) {
        return raw.map(r => {
            if (this.activeSubTab === 'contrato') return {
                id: r.id, name: r.name || '—',
                contratista: r.contratista || '—', beneficiario: r.beneficiario || '—', institucion: r.institucion || '—',
                montoOriginalFmt: fmt(r.monto), valorVigenteFmt: fmt(r.valorVigente),
                valorVigente: r.valorVigente,
                montoFmt: fmt(r.monto), exposicionFmt: r.exposicion != null ? r.exposicion.toFixed(1) + '%' : '—',
                fechaInicio: fmtDate(r.fechaInicio), fechaFin: fmtDate(r.fechaFin),
                fechaFinRaw: r.fechaFin || '',
                estatus: r.estatus || '—',
                estatusClass: ESTATUS_CONTRATO[r.estatus] || 'vf-badge vf-badge-gray',
                proyecto: r.proyecto || '—',
                trClass: 'vf-row vf-row-contrato',
                _e: {
                    Proyecto__c: r.proyecto || '',
                    Valor_Contrato_Vigente__c: r.valorVigente != null ? String(r.valorVigente) : '',
                    Fin_Contrato_Vigente__c: r.fechaFinVigente || r.fechaFin || '',
                    contratistaId:     r.contratistaId  || '',
                    contratistaNombre: r.contratista    || '',
                    institucionId:     r.institucionId  || '',
                    institucionNombre: r.institucion    || '',
                    beneficiarioId:    r.beneficiarioId || '',
                    beneficiarioNombre: r.beneficiario  || '',
                    startDate:     r.fechaInicio     || '',
                    endDate:       r.fechaFinVigente || r.fechaFin || '',
                    valorContrato: r.valorVigente != null ? String(r.valorVigente) : '',
                },
            };
            return { ...r, trClass: 'vf-row' };
        });
    }

    // ── Row click / panel ───────────────────────────────────────────────────────

    handleRowClick(e) {
        const id = e.currentTarget.dataset.id;
        if (!id) return;
        if (this.selectedId === id) { this.selectedId = null; return; }
        this.selectedId = id;
        this.panelTab   = 'detalles';
        this._clearPanelData();
    }

    handleClosePanel() { this.selectedId = null; this._clearPanelData(); this.isEditing = false; }

    _clearPanelData() {
        this.panelFianzas = []; this.panelConvenios = [];
    }

    get showPanel() { return !!this.selectedId; }

    get panelRecord() {
        return this.filteredRows.find(r => r.id === this.selectedId) || null;
    }

    // ── Edit panel ──────────────────────────────────────────────────────────────

    get editFields() {
        const r = this.panelRecord;
        if (!r) return [];
        const tab = this.activeSubTab;
        const ed  = this.editData;
        const mk = (key, label, type, val, opts) => {
            const isSelect   = type === 'select';
            const isTextarea = type === 'textarea';
            const isInput    = !isSelect && !isTextarea;
            const curVal     = ed[key] !== undefined ? ed[key] : val;
            return {
                key, label, type, val, isInput, isSelect, isTextarea, currentVal: curVal,
                options: isSelect ? opts.map(o => ({ value: o, label: o, isSelected: curVal === o })) : [],
            };
        };
        if (tab === 'contrato') return [
            mk('Proyecto__c',              'Proyecto',      'text',   r._e.Proyecto__c || ''),
            mk('Valor_Contrato_Vigente__c', 'Valor vigente','number', r._e.Valor_Contrato_Vigente__c || ''),
            mk('Fin_Contrato_Vigente__c',   'Fin vigente',  'date',   r._e.Fin_Contrato_Vigente__c || ''),
        ];
        return [];
    }

    async handleEditPanel() {
        const r = this.panelRecord;
        this.isLoading = true;
        try {
            const raw = await getFianzasByContrato({ contratoId: r.id });
            this.editFianzasForWizard = (raw || []).map(f => ({
                id:              f.id,
                tipoRiesgo:      f.tipoRiesgo      || '',
                monto:           f.monto,
                primaNeta:       f.primaNeta,
                fechaEmision:    f.fechaEmision    || '',
                fechaVencimiento: f.fechaVencimiento || '',
            }));
        } catch (e) {
            this.editFianzasForWizard = [];
        } finally {
            this.isLoading = false;
        }
        this.editContratoForWizard = {
            id:                r.id,
            contratistaId:     r._e.contratistaId     || '',
            contratistaNombre: r._e.contratistaNombre || '',
            institucionId:     r._e.institucionId     || '',
            institucionNombre: r._e.institucionNombre || '',
            beneficiarioId:    r._e.beneficiarioId    || '',
            beneficiarioNombre: r._e.beneficiarioNombre || '',
            valorContrato:     r._e.valorContrato     || '',
            startDate:         r._e.startDate         || '',
            endDate:           r._e.endDate           || '',
            proyecto:          r._e.Proyecto__c       || '',
        };
        this._wizardIsEdit      = true;
        this.showWizardContrato = true;
    }

    handleCancelEdit() { this.isEditing = false; this.editData = {}; }

    handleEditInput(e) {
        const key = e.currentTarget.dataset.key;
        this.editData = { ...this.editData, [key]: e.target.value };
    }

    async handleSaveEdit() {
        this.isSavingEdit = true;
        try {
            const fields = { Id: this.selectedId };
            this.editFields.forEach(f => {
                const v = this.editData[f.key];
                if (v !== undefined && v !== null && v !== '') {
                    fields[f.key] = f.type === 'number' ? parseFloat(v) : v;
                }
            });
            await updateRecord({ fields });
            this.isEditing = false;
            this.editData  = {};
            delete this._cache[this.activeSubTab];
            await this._load();
            this.dispatchEvent(new ShowToastEvent({ title: 'Guardado', variant: 'success' }));
        } catch (err) {
            const msg = err?.body?.output?.errors?.[0]?.message || err?.body?.message || 'Error al guardar';
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: msg, variant: 'error' }));
        } finally {
            this.isSavingEdit = false;
        }
    }

    handlePanelPrev() {
        const rows = this.filteredRows;
        const idx  = rows.findIndex(r => r.id === this.selectedId);
        if (idx > 0) { this.selectedId = rows[idx - 1].id; this.panelTab = 'detalles'; this._clearPanelData(); }
    }

    handlePanelNext() {
        const rows = this.filteredRows;
        const idx  = rows.findIndex(r => r.id === this.selectedId);
        if (idx < rows.length - 1) { this.selectedId = rows[idx + 1].id; this.panelTab = 'detalles'; this._clearPanelData(); }
    }

    // ── Panel tabs ──────────────────────────────────────────────────────────────

    async handlePanelTab(e) {
        const ptab = e.currentTarget.dataset.ptab;
        this.panelTab = ptab;
        const id = this.selectedId;
        if (!id) return;
        try {
            if (ptab === 'convenios' && !this.panelConvenios.length) {
                await this._loadPanelConvenios(id);
            }
            if (ptab === 'fianzas' && !this.panelFianzas.length) {
                const raw = await getFianzasByContrato({ contratoId: id });
                this.panelFianzas = (raw || []).map(f => ({
                    id: f.id || f.Id, name: f.name || f.Name || '—',
                    tipoRiesgo: f.tipoRiesgo || f.Tipo_de_Riesgo__c || '—',
                    montoVigenteFmt: fmt(f.montoVigente ?? f.Monto_Afianzado_Vigente__c),
                    fechaVencimiento: fmtDate(f.fechaVencimiento ?? f.Fecha_de_Vencimiento__c),
                    estatus: f.estatus || f.Estatus__c || '—',
                    estatusClass: ESTATUS_FIANZA[f.estatus || f.Estatus__c] || 'vf-badge vf-badge-gray',
                }));
            }
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err?.body?.message || 'Error al cargar datos', variant: 'error' }));
        }
    }

    // ── Panel Convenios ─────────────────────────────────────────────────────────

    async _loadPanelConvenios(contratoId) {
        try {
            const raw = await getConveniosByContrato({ contratoId });
            this.panelConvenios = (raw || []).map(cv => ({
                id: cv.id, name: cv.name,
                tipo: cv.tipo || '—',
                tipoClass: TIPO_CONVENIO[cv.tipo] || 'vf-badge vf-badge-gray',
                fecha: fmtDate(cv.fecha),
                nuevoValorFmt: fmt(cv.nuevoValor),
                nuevaFechaFin: fmtDate(cv.nuevaFechaFin),
                descripcion: cv.descripcion || '',
                _raw: {
                    tipo:         cv.tipo           || '',
                    nuevoValor:   cv.nuevoValor  != null ? String(cv.nuevoValor)  : '',
                    nuevaFechaFin: cv.nuevaFechaFin != null ? String(cv.nuevaFechaFin) : '',
                    descripcion:  cv.descripcion    || '',
                    motivo:       cv.motivo         || '',
                },
            }));
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error al recargar convenios', message: err?.body?.message || String(err), variant: 'error' }));
        }
    }

    get panelConveniosView() {
        const editId = this.panelConvenioEdit?.id;
        return this.panelConvenios.map(cv => ({ ...cv, isEditing: cv.id === editId }));
    }

    get hasPanelConvenios() { return this.panelConvenios.length > 0; }

    get convenioEditTipoOptions() {
        const cur = this.panelConvenioEdit?.editData?.tipo || '';
        return ['Ampliación de monto', 'Ampliación de plazo', 'Cambio de alcance', 'Reducción']
            .map(o => ({ value: o, label: o, isSelected: cur === o }));
    }

    handleAddConvenioFromPanel(e) {
        e.stopPropagation();
        const r = this.panelRecord;
        if (!r) return;
        this.convenioWizardContrato = { id: r.id, name: r.name };
        this.showWizardConvenio = true;
    }

    handleEditConvenioCard(e) {
        e.stopPropagation();
        const id = e.currentTarget.dataset.id;
        const cv = this.panelConvenios.find(c => c.id === id);
        if (!cv) return;
        this.panelConvenioEdit = { id, editData: { ...cv._raw } };
    }

    handleCancelConvenioEdit(e) {
        e.stopPropagation();
        this.panelConvenioEdit = null;
    }

    handleConvenioEditField(e) {
        e.stopPropagation();
        const field = e.currentTarget.dataset.field;
        // lightning-textarea expone el valor en e.detail.value; inputs/selects nativos en e.target.value
        const value = e.detail?.value !== undefined ? e.detail.value : e.target.value;
        this.panelConvenioEdit = {
            ...this.panelConvenioEdit,
            editData: { ...this.panelConvenioEdit.editData, [field]: value },
        };
    }

    async handleSaveConvenioCard(e) {
        e.stopPropagation();
        const { id, editData } = this.panelConvenioEdit;
        try {
            const fields = { Id: id };
            if (editData.tipo)          fields['Tipo_de_Modificacion__c'] = editData.tipo;
            if (editData.nuevoValor)    fields['Nuevo_Valor_Contrato__c'] = parseFloat(editData.nuevoValor);
            if (editData.nuevaFechaFin) fields['Nueva_Fecha_Fin__c']      = editData.nuevaFechaFin;
            fields['Descripcion__c'] = editData.descripcion || '';
            fields['Motivo__c']      = editData.motivo      || '';
            await updateRecord({ fields });
            this.panelConvenioEdit = null;
            this.panelConvenios    = [];
            await this._loadPanelConvenios(this.selectedId);
            this.dispatchEvent(new ShowToastEvent({ title: 'Convenio actualizado', variant: 'success' }));
        } catch (err) {
            const msg = err?.body?.output?.errors?.[0]?.message || err?.body?.message || 'Error al guardar';
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: msg, variant: 'error' }));
        }
    }

    get ptClassDetalles()   { return 'vf-ptab' + (this.panelTab === 'detalles'   ? ' vf-ptab-active' : ''); }
    get ptClassFianzas()    { return 'vf-ptab' + (this.panelTab === 'fianzas'    ? ' vf-ptab-active' : ''); }
    get ptClassConvenios()  { return 'vf-ptab' + (this.panelTab === 'convenios'  ? ' vf-ptab-active' : ''); }
    get ptClassCalculados() { return 'vf-ptab' + (this.panelTab === 'calculados' ? ' vf-ptab-active' : ''); }

    get showPtDetalles()   { return this.panelTab === 'detalles'; }
    get showPtFianzas()    { return this.panelTab === 'fianzas'; }
    get showPtConvenios()  { return this.panelTab === 'convenios'; }
    get showPtCalculados() { return this.panelTab === 'calculados'; }

    get panelFields() {
        const r = this.panelRecord;
        if (!r) return [];
        return [
            { key: 'name',         label: 'No. Contrato', value: r.name },
            { key: 'contratista',  label: 'Contratista',  value: r.contratista },
            { key: 'beneficiario', label: 'Beneficiario', value: r.beneficiario },
            { key: 'institucion',  label: 'Institución',  value: r.institucion },
            { key: 'proyecto',     label: 'Proyecto',     value: r.proyecto },
            { key: 'estatus',      label: 'Estatus',      value: r.estatus, isBadge: true, badgeClass: r.estatusClass },
            { key: 'fechaInicio',  label: 'Inicio',       value: r.fechaInicio },
            { key: 'fechaFin',     label: 'Fin original', value: r.fechaFin },
        ];
    }

    // ── Sort ────────────────────────────────────────────────────────────────────

    handleSort(e) {
        const field = e.currentTarget.dataset.field;
        if (!field) return;
        this.sortDir   = this.sortField === field && this.sortDir === 'asc' ? 'desc' : 'asc';
        this.sortField = field;
    }

    // ── Filters ─────────────────────────────────────────────────────────────────

    get _filterDefs() { return FILTER_DEFS[this.activeSubTab] || []; }

    handleToggleFilters() { this.showFilters = !this.showFilters; }
    handleClearFilters()  { this.filterRules = []; }

    handleAddRule() {
        const defs = this._filterDefs;
        const ops  = getOps(defs[0]?.type || 'text');
        this.filterRules = [...this.filterRules, { id: ++this._ruleCounter, field: defs[0]?.value || 'name', op: ops[0].v, value: '' }];
    }

    handleRemoveRule(e) {
        const id = parseInt(e.currentTarget.dataset.id, 10);
        this.filterRules = this.filterRules.filter(r => r.id !== id);
    }

    handleFilterField(e) {
        const id = parseInt(e.currentTarget.dataset.id, 10);
        const field = e.target.value;
        const def = this._filterDefs.find(f => f.value === field) || this._filterDefs[0];
        const ops = getOps(def.type);
        this.filterRules = this.filterRules.map(r => r.id === id ? { ...r, field, op: ops[0].v, value: '' } : r);
    }

    handleFilterOp(e) {
        const id = parseInt(e.currentTarget.dataset.id, 10);
        this.filterRules = this.filterRules.map(r => r.id === id ? { ...r, op: e.target.value } : r);
    }

    handleFilterValue(e) {
        const id = parseInt(e.currentTarget.dataset.id, 10);
        this.filterRules = this.filterRules.map(r => r.id === id ? { ...r, value: e.target.value } : r);
    }

    get filterBtnClass() {
        const active = this.filterRules.some(r => r.value?.trim());
        return 'vf-btn-filters' + (active ? ' vf-btn-filters-active' : '') + (this.showFilters ? ' vf-btn-filters-open' : '');
    }

    get filterBtnLabel() {
        const n = this.filterRules.filter(r => r.value?.trim()).length;
        return n > 0 ? `Filtros (${n})` : 'Filtros';
    }

    get hasFilterRules() { return this.filterRules.length > 0; }

    get filterRulesView() {
        return this.filterRules.map(r => {
            const defs = this._filterDefs;
            const def  = defs.find(f => f.value === r.field) || defs[0] || {};
            const ops  = getOps(def.type);
            return {
                id: r.id, field: r.field, op: r.op, value: r.value,
                fieldOptions: defs.map(f => ({ value: f.value, label: f.label, selected: f.value === r.field })),
                opOptions:    ops.map(o => ({ value: o.v, label: o.l, selected: o.v === r.op })),
                isText:     def.type === 'text',
                isPicklist: def.type === 'picklist',
                picklistOptions: def.type === 'picklist' ? (def.options || []).map(o => ({ value: o, label: o, selected: o === r.value })) : [],
            };
        });
    }

    get filteredRows() {
        const active = this.filterRules.filter(r => r.value?.trim());
        let result = active.length
            ? this.rows.filter(row => active.every(r => {
                const iv = String(row[r.field] || '').toLowerCase();
                const v  = String(r.value).toLowerCase().trim();
                return r.op === 'contains' ? iv.includes(v) : r.op === 'eq' ? iv === v : iv !== v;
              }))
            : this.rows;

        if (this.sortField) {
            const dir = this.sortDir === 'asc' ? 1 : -1;
            const f   = this.sortField;
            result = [...result].sort((a, b) => {
                const av = a[f] ?? ''; const bv = b[f] ?? '';
                if (typeof av === 'number' && typeof bv === 'number') return (av - bv) * dir;
                return String(av).localeCompare(String(bv)) * dir;
            });
        }
        return result.map(r => ({
            ...r,
            trClass: r.trClass + (this.selectedId === r.id ? ' vf-row-selected' : ''),
        }));
    }

    // ── Headers ─────────────────────────────────────────────────────────────────

    get headers() {
        const defs = [
            { key: 'name',         field: 'name',        label: 'No. Contrato' },
            { key: 'contratista',  field: 'contratista', label: 'Cliente' },
            { key: 'institucion',  field: 'institucion', label: 'Institución' },
            { key: 'beneficiario', field: 'beneficiario',label: 'Beneficiario' },
            { key: 'montoOrig',    field: '',            label: 'Valor original' },
            { key: 'valorVig',     field: '',            label: 'Valor vigente' },
            { key: 'inicio',       field: 'fechaInicio', label: 'Inicio' },
            { key: 'fin',          field: 'fechaFin',    label: 'Fin' },
            { key: 'estatus',      field: 'estatus',     label: 'Estatus' },
        ];
        return defs.map(h => ({
            ...h,
            thClass: 'vf-th' + (h.field ? ' vf-th-sort' : '') + (this.sortField === h.field && h.field ? ' vf-th-sorted' : ''),
            icon: h.field ? (this.sortField !== h.field ? '↕' : this.sortDir === 'asc' ? '↑' : '↓') : '',
        }));
    }

    // ── State helpers ───────────────────────────────────────────────────────────

    get hasError()            { return !this.isLoading && !!this.error; }
    get isEmpty()             { return !this.isLoading && !this.error && !this.rows.length; }
    get showTable()           { return !this.isLoading && !this.error && this.rows.length > 0; }
    get showBtnNuevoContrato(){ return this.isTabContrato; }

    // ── Wizards ─────────────────────────────────────────────────────────────────

    handleOpenWizardContrato() {
        this.editContratoForWizard = null;
        this.editFianzasForWizard  = [];
        this._wizardIsEdit         = false;
        this.showWizardContrato    = true;
    }

    handleWizardClose() {
        this.showWizardContrato     = false;
        this.showWizardConvenio     = false;
        this.convenioWizardContrato = null;
    }

    async handleWizardSuccess() {
        this.showWizardContrato     = false;
        this.showWizardConvenio     = false;
        this.convenioWizardContrato = null;
        const title = this._wizardIsEdit ? 'Actualizado exitosamente' : 'Creado exitosamente';
        this._wizardIsEdit = false;
        delete this._cache[this.activeSubTab];
        await this._load();
        if (this.selectedId && this.isTabContrato) {
            if (this.panelTab === 'fianzas') {
                this.panelFianzas = [];
                const raw = await getFianzasByContrato({ contratoId: this.selectedId });
                this.panelFianzas = (raw || []).map(f => ({
                    id: f.id || f.Id, name: f.name || f.Name || '—',
                    tipoRiesgo: f.tipoRiesgo || '—',
                    montoVigenteFmt: fmt(f.montoVigente ?? f.Monto_Afianzado_Vigente__c),
                    fechaVencimiento: fmtDate(f.fechaVencimiento ?? f.Fecha_de_Vencimiento__c),
                    estatus: f.estatus || f.Estatus__c || '—',
                    estatusClass: ESTATUS_FIANZA[f.estatus || f.Estatus__c] || 'vf-badge vf-badge-gray',
                }));
            }
            if (this.panelTab === 'convenios') {
                this.panelConvenios = [];
                await this._loadPanelConvenios(this.selectedId);
            }
        }
        this.dispatchEvent(new ShowToastEvent({ title, variant: 'success' }));
    }
}
