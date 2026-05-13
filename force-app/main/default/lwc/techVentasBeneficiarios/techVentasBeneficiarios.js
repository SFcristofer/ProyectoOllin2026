import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import getBeneficiarioList from '@salesforce/apex/TechBeneficiarioController.getBeneficiarioList';
import getFianzasList      from '@salesforce/apex/TechFianzaController.getFianzasList';

const MONEY = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN', maximumFractionDigits: 0 });
function fmt(v)  { return v == null ? '—' : MONEY.format(v); }
function fmtD(s) { if (!s) return '—'; const p = s.split('-'); return p.length === 3 ? `${p[2]}/${p[1]}/${p[0]}` : s; }

const ESTATUS_FIANZA = {
    'Vigente':   'vb-badge vb-badge-green',
    'Emitida':   'vb-badge vb-badge-green',
    'Cancelada': 'vb-badge vb-badge-gray',
    'Vencida':   'vb-badge vb-badge-red',
};

const TEXT_OPS = [{ v: 'contains', l: 'contiene' }, { v: 'eq', l: 'es igual a' }, { v: 'ne', l: 'no es igual a' }];
const FILTER_DEFS = [
    { value: 'name', label: 'Nombre', type: 'text' },
    { value: 'rfc',  label: 'RFC',    type: 'text' },
];

export default class TechVentasBeneficiarios extends LightningElement {
    @track rows          = [];
    @track selectedId    = null;
    @track panelTab      = 'detalles';
    @track isLoading     = false;
    @track error         = null;
    @track sortField     = '';
    @track sortDir       = 'asc';
    @track showFilters   = false;
    @track filterRules   = [];
    @track isEditing     = false;
    @track isSavingEdit  = false;
    @track editData      = {};
    @track panelFianzas  = [];
    _ruleCounter = 0;
    _cache = {};

    connectedCallback() { this._load(); }

    async _load() {
        if (this._cache.beneficiario) { this.rows = this._cache.beneficiario; return; }
        this.isLoading = true; this.error = null;
        try {
            const raw = await getBeneficiarioList();
            this.rows = (raw || []).map(r => ({
                id: r.id, name: r.name || '—', rfc: r.rfc || '—',
                billingCity: r.billingCity || '—', billingState: r.billingState || '—',
                phone: r.phone || '—',
                fianzasCount: r.fianzas?.length || 0,
                estatus: 'Activo', estatusClass: 'vb-badge vb-badge-green',
                trClass: 'vb-row',
                _e: { Name: r.name || '', RFC__c: r.rfc || '', BillingCity: r.billingCity || '', BillingState: r.billingState || '', Phone: r.phone || '' },
            }));
            this._cache.beneficiario = this.rows;
        } catch (e) {
            this.error = e?.body?.message || 'Error al cargar datos';
        } finally {
            this.isLoading = false;
        }
    }

    // ── Row / Panel ─────────────────────────────────────────────────────────────

    handleRowClick(e) {
        const id = e.currentTarget.dataset.id;
        if (!id) return;
        if (this.selectedId === id) { this.selectedId = null; return; }
        this.selectedId  = id;
        this.panelTab    = 'detalles';
        this.panelFianzas = [];
    }

    handleClosePanel() { this.selectedId = null; this.panelFianzas = []; this.isEditing = false; }

    get showPanel()   { return !!this.selectedId; }
    get panelRecord() { return this.filteredRows.find(r => r.id === this.selectedId) || null; }

    handlePanelPrev() {
        const rows = this.filteredRows;
        const idx  = rows.findIndex(r => r.id === this.selectedId);
        if (idx > 0) { this.selectedId = rows[idx - 1].id; this.panelTab = 'detalles'; this.panelFianzas = []; }
    }
    handlePanelNext() {
        const rows = this.filteredRows;
        const idx  = rows.findIndex(r => r.id === this.selectedId);
        if (idx < rows.length - 1) { this.selectedId = rows[idx + 1].id; this.panelTab = 'detalles'; this.panelFianzas = []; }
    }

    // ── Panel tabs ───────────────────────────────────────────────────────────────

    async handlePanelTab(e) {
        this.panelTab = e.currentTarget.dataset.ptab;
        if (this.panelTab === 'fianzas' && !this.panelFianzas.length) {
            try {
                const all = await getFianzasList();
                this.panelFianzas = (all || [])
                    .filter(f => f.beneficiario === this.selectedId || f.beneficiarios === this.selectedId)
                    .map(f => ({
                        id: f.id, name: f.name || '—',
                        tipoRiesgo: f.tipoRiesgo || '—',
                        montoVigenteFmt: fmt(f.montoVigente),
                        fechaVencimiento: fmtD(f.fechaVencimiento),
                        estatus: f.estatus || '—',
                        estatusClass: ESTATUS_FIANZA[f.estatus] || 'vb-badge vb-badge-gray',
                    }));
            } catch (err) {
                this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err?.body?.message || 'Error al cargar fianzas', variant: 'error' }));
            }
        }
    }

    get ptClassDetalles() { return 'vb-ptab' + (this.panelTab === 'detalles' ? ' vb-ptab-active' : ''); }
    get ptClassFianzas()  { return 'vb-ptab' + (this.panelTab === 'fianzas'  ? ' vb-ptab-active' : ''); }
    get showPtDetalles()  { return this.panelTab === 'detalles'; }
    get showPtFianzas()   { return this.panelTab === 'fianzas'; }

    get panelFields() {
        const r = this.panelRecord;
        if (!r) return [];
        return [
            { key: 'name',         label: 'Nombre',   value: r.name },
            { key: 'rfc',          label: 'RFC',      value: r.rfc },
            { key: 'billingCity',  label: 'Ciudad',   value: r.billingCity },
            { key: 'billingState', label: 'Estado',   value: r.billingState },
            { key: 'phone',        label: 'Teléfono', value: r.phone },
            { key: 'estatus',      label: 'Estatus',  value: r.estatus, isBadge: true, badgeClass: r.estatusClass },
        ];
    }

    // ── Edit ─────────────────────────────────────────────────────────────────────

    handleEditPanel() {
        this.isEditing = true; this.panelTab = 'detalles';
        const data = {};
        this.editFields.forEach(f => { data[f.key] = f.val; });
        this.editData = data;
    }
    handleCancelEdit() { this.isEditing = false; this.editData = {}; }
    handleEditInput(e) {
        const key = e.currentTarget.dataset.key;
        this.editData = { ...this.editData, [key]: e.target.value };
    }

    get editFields() {
        const r = this.panelRecord;
        if (!r) return [];
        const ed = this.editData;
        const mk = (key, label, type, val) => {
            const curVal = ed[key] !== undefined ? ed[key] : val;
            return { key, label, type, val: curVal, isInput: true, isSelect: false, options: [] };
        };
        return [
            mk('Name',         'Nombre',   'text', r._e.Name         || ''),
            mk('RFC__c',       'RFC',      'text', r._e.RFC__c       || ''),
            mk('BillingCity',  'Ciudad',   'text', r._e.BillingCity  || ''),
            mk('BillingState', 'Estado',   'text', r._e.BillingState || ''),
            mk('Phone',        'Teléfono', 'tel',  r._e.Phone        || ''),
        ];
    }

    async handleSaveEdit() {
        this.isSavingEdit = true;
        try {
            const fields = { Id: this.selectedId };
            this.editFields.forEach(f => { if (f.val !== undefined && f.val !== null) fields[f.key] = f.val; });
            await updateRecord({ fields });
            this.isEditing = false; this.editData = {};
            delete this._cache.beneficiario;
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
        const field = e.currentTarget.dataset.field;
        if (!field) return;
        this.sortDir   = this.sortField === field && this.sortDir === 'asc' ? 'desc' : 'asc';
        this.sortField = field;
    }

    // ── Filters ──────────────────────────────────────────────────────────────────

    handleToggleFilters() { this.showFilters = !this.showFilters; }
    handleClearFilters()  { this.filterRules = []; }
    handleAddRule() {
        const ops = TEXT_OPS;
        this.filterRules = [...this.filterRules, { id: ++this._ruleCounter, field: FILTER_DEFS[0].value, op: ops[0].v, value: '' }];
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
        return 'vb-btn-filters' + (active ? ' vb-btn-filters-active' : '') + (this.showFilters ? ' vb-btn-filters-open' : '');
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
        return result.map(r => ({ ...r, trClass: r.trClass + (this.selectedId === r.id ? ' vb-row-selected' : '') }));
    }

    get headers() {
        const defs = [
            { key: 'name',    field: 'name',    label: 'Nombre' },
            { key: 'rfc',     field: 'rfc',     label: 'RFC' },
            { key: 'fianzas', field: '',         label: 'Fianzas' },
            { key: 'estatus', field: 'estatus', label: 'Estatus' },
        ];
        return defs.map(h => ({
            ...h,
            thClass: 'vb-th' + (h.field ? ' vb-th-sort' : '') + (this.sortField === h.field && h.field ? ' vb-th-sorted' : ''),
            icon: h.field ? (this.sortField !== h.field ? '↕' : this.sortDir === 'asc' ? '↑' : '↓') : '',
        }));
    }

    get hasError() { return !this.isLoading && !!this.error; }
    get isEmpty()  { return !this.isLoading && !this.error && !this.rows.length; }
    get showTable(){ return !this.isLoading && !this.error && this.rows.length > 0; }
}
