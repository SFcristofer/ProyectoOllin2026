import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import getVendedoresList   from '@salesforce/apex/TechFianzaController.getVendedoresList';
import getFianzasList      from '@salesforce/apex/TechFianzaController.getFianzasList';
import getSubmodulosFianza from '@salesforce/apex/TechFianzaController.getSubmodulosFianza';

const MONEY = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN', maximumFractionDigits: 0 });
function fmt(v)  { return v == null ? '—' : MONEY.format(v); }
function fmtD(s) { if (!s) return '—'; const p = s.split('-'); return p.length === 3 ? `${p[2]}/${p[1]}/${p[0]}` : s; }

const ESTATUS_FIANZA = {
    'Vigente':   'vv-badge vv-badge-green',
    'Emitida':   'vv-badge vv-badge-green',
    'Cancelada': 'vv-badge vv-badge-gray',
    'Vencida':   'vv-badge vv-badge-red',
};

const TEXT_OPS = [{ v: 'contains', l: 'contiene' }, { v: 'eq', l: 'es igual a' }, { v: 'ne', l: 'no es igual a' }];
const FILTER_DEFS = [
    { value: 'name',  label: 'Nombre', type: 'text' },
    { value: 'email', label: 'Email',  type: 'text' },
];

export default class TechVentasVendedores extends LightningElement {
    @track rows           = [];
    @track selectedId     = null;
    @track panelTab       = 'detalles';
    @track isLoading      = false;
    @track error          = null;
    @track sortField      = '';
    @track sortDir        = 'asc';
    @track showFilters    = false;
    @track filterRules    = [];
    @track isEditing      = false;
    @track isSavingEdit   = false;
    @track editData       = {};
    @track panelFianzas   = [];
    @track panelComisiones = [];
    _ruleCounter = 0;
    _cache = {};

    connectedCallback() { this._load(); }

    async _load() {
        if (this._cache.vendedores) { this.rows = this._cache.vendedores; return; }
        this.isLoading = true; this.error = null;
        try {
            const raw = await getVendedoresList();
            this.rows = (raw || []).map(r => ({
                id: r.id, name: r.name || '—', email: r.email || '—',
                tipo: r.tipo || '—', telefono: r.telefono || '—', tipoAgente: r.tipoAgente || '—',
                fianzasCount: 0, montoVigenteFmt: '—', comisionDevenga: '—',
                trClass: 'vv-row',
                _e: { Name: r.name || '', CorreoElectronico__c: r.email || '', Rol__c: r.tipo || '', Telefono__c: r.telefono || '', Tipo_Agente__c: r.tipoAgente || '' },
            }));
            this._cache.vendedores = this.rows;
        } catch (e) {
            this.error = e?.body?.message || 'Error al cargar datos';
        } finally {
            this.isLoading = false;
        }
    }

    // ── Row / Panel ──────────────────────────────────────────────────────────────

    handleRowClick(e) {
        const id = e.currentTarget.dataset.id;
        if (!id) return;
        if (this.selectedId === id) { this.selectedId = null; return; }
        this.selectedId    = id;
        this.panelTab      = 'detalles';
        this.panelFianzas  = [];
        this.panelComisiones = [];
    }

    handleClosePanel() {
        this.selectedId = null; this.panelFianzas = []; this.panelComisiones = []; this.isEditing = false;
    }

    get showPanel()   { return !!this.selectedId; }
    get panelRecord() { return this.filteredRows.find(r => r.id === this.selectedId) || null; }

    handlePanelPrev() {
        const rows = this.filteredRows; const idx = rows.findIndex(r => r.id === this.selectedId);
        if (idx > 0) { this.selectedId = rows[idx - 1].id; this.panelTab = 'detalles'; this.panelFianzas = []; this.panelComisiones = []; }
    }
    handlePanelNext() {
        const rows = this.filteredRows; const idx = rows.findIndex(r => r.id === this.selectedId);
        if (idx < rows.length - 1) { this.selectedId = rows[idx + 1].id; this.panelTab = 'detalles'; this.panelFianzas = []; this.panelComisiones = []; }
    }

    // ── Panel tabs ───────────────────────────────────────────────────────────────

    async handlePanelTab(e) {
        this.panelTab = e.currentTarget.dataset.ptab;
        const id = this.selectedId;
        try {
            if (this.panelTab === 'fianzas' && !this.panelFianzas.length) {
                const all = await getFianzasList();
                this.panelFianzas = (all || [])
                    .filter(f => (f.vendedorRels || []).some(v => v.relId === id))
                    .map(f => ({
                        id: f.id, name: f.name || '—', tipoRiesgo: f.tipoRiesgo || '—',
                        montoVigenteFmt: fmt(f.montoVigente),
                        fechaVencimiento: fmtD(f.fechaVencimiento),
                        estatus: f.estatus || '—',
                        estatusClass: ESTATUS_FIANZA[f.estatus] || 'vv-badge vv-badge-gray',
                    }));
            }
            if (this.panelTab === 'comisiones' && !this.panelComisiones.length) {
                const all = await getFianzasList();
                const fianzaIds = (all || [])
                    .filter(f => (f.vendedorRels || []).some(v => v.relId === id))
                    .map(f => f.id);
                const comisiones = [];
                for (const fid of fianzaIds) {
                    const sub = await getSubmodulosFianza({ fianzaId: fid });
                    for (const c of (sub.comisiones || [])) {
                        if (c.vendedorId === id || c.vendedor === this.panelRecord?.name) {
                            comisiones.push({
                                id: c.id, vendedor: c.vendedor || '—', estatus: c.estatus || '—',
                                estatusClass: c.estatus === 'Pagada' ? 'vv-badge vv-badge-green' : 'vv-badge vv-badge-amber',
                                pct: c.pct || '—', montoOllin: fmt(c.montoOllin), montoVendedor: fmt(c.montoVendedor),
                            });
                        }
                    }
                }
                this.panelComisiones = comisiones;
            }
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err?.body?.message || 'Error al cargar datos', variant: 'error' }));
        }
    }

    get ptClassDetalles()   { return 'vv-ptab' + (this.panelTab === 'detalles'   ? ' vv-ptab-active' : ''); }
    get ptClassFianzas()    { return 'vv-ptab' + (this.panelTab === 'fianzas'    ? ' vv-ptab-active' : ''); }
    get ptClassComisiones() { return 'vv-ptab' + (this.panelTab === 'comisiones' ? ' vv-ptab-active' : ''); }
    get showPtDetalles()    { return this.panelTab === 'detalles'; }
    get showPtFianzas()     { return this.panelTab === 'fianzas'; }
    get showPtComisiones()  { return this.panelTab === 'comisiones'; }

    get panelFields() {
        const r = this.panelRecord; if (!r) return [];
        return [
            { key: 'name',      label: 'Nombre',         value: r.name },
            { key: 'email',     label: 'Email',          value: r.email },
            { key: 'telefono',  label: 'Teléfono',       value: r.telefono },
            { key: 'tipo',      label: 'Rol',            value: r.tipo },
            { key: 'tipoAgente',label: 'Tipo de agente', value: r.tipoAgente },
        ];
    }

    // ── Edit ─────────────────────────────────────────────────────────────────────

    handleEditPanel() {
        this.isEditing = true; this.panelTab = 'detalles';
        const data = {}; this.editFields.forEach(f => { data[f.key] = f.val; }); this.editData = data;
    }
    handleCancelEdit() { this.isEditing = false; this.editData = {}; }
    handleEditInput(e) {
        const key = e.currentTarget.dataset.key;
        this.editData = { ...this.editData, [key]: e.target.value };
    }

    get editFields() {
        const r = this.panelRecord; if (!r) return [];
        const ed = this.editData;
        const mkIn = (key, label, type, val) => {
            const curVal = ed[key] !== undefined ? ed[key] : val;
            return { key, label, type, val: curVal, isInput: true, isSelect: false, options: [] };
        };
        const mkSel = (key, label, val, opts) => {
            const curVal = ed[key] !== undefined ? ed[key] : val;
            return { key, label, type: 'select', val: curVal, isInput: false, isSelect: true, options: opts.map(o => ({ value: o, label: o, isSelected: curVal === o })) };
        };
        return [
            mkIn('Name',                 'Nombre',         'text',  r._e.Name                 || ''),
            mkIn('CorreoElectronico__c', 'Email',          'email', r._e.CorreoElectronico__c  || ''),
            mkIn('Telefono__c',          'Teléfono',       'tel',   r._e.Telefono__c           || ''),
            mkIn('Rol__c',               'Rol',            'text',  r._e.Rol__c               || ''),
            mkSel('Tipo_Agente__c',      'Tipo de agente', r._e.Tipo_Agente__c || '', ['Agente AI', 'Agente Externo', 'Humano']),
        ];
    }

    async handleSaveEdit() {
        this.isSavingEdit = true;
        try {
            const fields = { Id: this.selectedId };
            this.editFields.forEach(f => { if (f.val !== undefined && f.val !== null) fields[f.key] = f.val; });
            await updateRecord({ fields });
            this.isEditing = false; this.editData = {};
            delete this._cache.vendedores;
            await this._load();
            this.dispatchEvent(new ShowToastEvent({ title: 'Guardado', variant: 'success' }));
        } catch (err) {
            const msg = err?.body?.output?.errors?.[0]?.message || err?.body?.message || 'Error al guardar';
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: msg, variant: 'error' }));
        } finally {
            this.isSavingEdit = false;
        }
    }

    // ── Sort ─────────────────────────────────────────────────────────────────────

    handleSort(e) {
        const field = e.currentTarget.dataset.field; if (!field) return;
        this.sortDir   = this.sortField === field && this.sortDir === 'asc' ? 'desc' : 'asc';
        this.sortField = field;
    }

    // ── Filters ──────────────────────────────────────────────────────────────────

    handleToggleFilters() { this.showFilters = !this.showFilters; }
    handleClearFilters()  { this.filterRules = []; }
    handleAddRule() {
        this.filterRules = [...this.filterRules, { id: ++this._ruleCounter, field: FILTER_DEFS[0].value, op: TEXT_OPS[0].v, value: '' }];
    }
    handleRemoveRule(e) {
        const id = parseInt(e.currentTarget.dataset.id, 10);
        this.filterRules = this.filterRules.filter(r => r.id !== id);
    }
    handleFilterField(e) {
        const id = parseInt(e.currentTarget.dataset.id, 10);
        this.filterRules = this.filterRules.map(r => r.id === id ? { ...r, field: e.target.value, op: TEXT_OPS[0].v, value: '' } : r);
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
        return 'vv-btn-filters' + (active ? ' vv-btn-filters-active' : '') + (this.showFilters ? ' vv-btn-filters-open' : '');
    }
    get filterBtnLabel() {
        const n = this.filterRules.filter(r => r.value?.trim()).length;
        return n > 0 ? `Filtros (${n})` : 'Filtros';
    }
    get hasFilterRules() { return this.filterRules.length > 0; }
    get filterRulesView() {
        return this.filterRules.map(r => ({
            id: r.id, field: r.field, op: r.op, value: r.value,
            fieldOptions: FILTER_DEFS.map(f => ({ value: f.value, label: f.label, selected: f.value === r.field })),
            opOptions:    TEXT_OPS.map(o => ({ value: o.v, label: o.l, selected: o.v === r.op })),
            isText: true,
        }));
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
            result = [...result].sort((a, b) => String(a[f] ?? '').localeCompare(String(b[f] ?? '')) * dir);
        }
        return result.map(r => ({ ...r, trClass: r.trClass + (this.selectedId === r.id ? ' vv-row-selected' : '') }));
    }

    get headers() {
        const defs = [
            { key: 'name',    field: 'name',  label: 'Nombre' },
            { key: 'email',   field: 'email', label: 'Email' },
            { key: 'fianzas', field: '',      label: 'Fianzas activas' },
            { key: 'monto',   field: '',      label: 'Monto vigente' },
            { key: 'comision',field: '',      label: 'Comisión devengada' },
        ];
        return defs.map(h => ({
            ...h,
            thClass: 'vv-th' + (h.field ? ' vv-th-sort' : '') + (this.sortField === h.field && h.field ? ' vv-th-sorted' : ''),
            icon: h.field ? (this.sortField !== h.field ? '↕' : this.sortDir === 'asc' ? '↑' : '↓') : '',
        }));
    }

    get hasError() { return !this.isLoading && !!this.error; }
    get isEmpty()  { return !this.isLoading && !this.error && !this.rows.length; }
    get showTable(){ return !this.isLoading && !this.error && this.rows.length > 0; }
}
