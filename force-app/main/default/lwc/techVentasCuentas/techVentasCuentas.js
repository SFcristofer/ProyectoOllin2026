import { LightningElement, track } from 'lwc';
import getClientes from '@salesforce/apex/TechVentasController.getClientes';

const FILTER_DEFS = [
    { value: 'name',       label: 'Nombre',   type: 'text' },
    { value: 'recordType', label: 'Tipo',     type: 'text' },
    { value: 'ciudad',     label: 'Ciudad',   type: 'text' },
    { value: 'vendedor',   label: 'Vendedor', type: 'text' },
];

const TEXT_OPS = [{ v: 'contains', l: 'contiene' }, { v: 'eq', l: 'es igual a' }, { v: 'ne', l: 'no es igual a' }];

const RT_BADGE = {
    'Contratista':  'vcu-badge vcu-badge-blue',
    'Beneficiario': 'vcu-badge vcu-badge-teal',
    'Institución':  'vcu-badge vcu-badge-purple',
    'Afianzadora':  'vcu-badge vcu-badge-purple',
};

export default class TechVentasCuentas extends LightningElement {
    @track rows       = [];
    @track selectedId = null;
    @track isLoading  = false;
    @track error      = null;
    @track sortField  = '';
    @track sortDir    = 'asc';
    @track showFilters  = false;
    @track filterRules  = [];
    _ruleCounter = 0;
    _cache = null;

    connectedCallback() { this._load(); }

    async _load() {
        if (this._cache) { this.rows = this._cache; return; }
        this.isLoading = true;
        this.error = null;
        try {
            const raw = await getClientes();
            this.rows = (raw || []).map(r => ({
                id:         r.id,
                name:       r.name || '—',
                recordType: r.recordType || '—',
                rtClass:    RT_BADGE[r.recordType] || 'vcu-badge vcu-badge-gray',
                ciudad:     r.ciudad || '—',
                phone:      r.phone  || '—',
                email:      r.email  || '—',
                numOpps:    r.numOpps != null ? String(r.numOpps) : '0',
                vendedor:   r.vendedor || '—',
                fechaRegistro: r.fechaRegistro || '—',
                trClass: 'vcu-row',
            }));
            this._cache = this.rows;
        } catch (e) {
            this.error = e?.body?.message || 'Error al cargar cuentas';
        } finally {
            this.isLoading = false;
        }
    }

    handleRowClick(e) {
        const id = e.currentTarget.dataset.id;
        if (!id) return;
        this.selectedId = this.selectedId === id ? null : id;
    }

    handleClosePanel() { this.selectedId = null; }

    get showPanel()   { return !!this.selectedId; }
    get panelRecord() { return this.filteredRows.find(r => r.id === this.selectedId) || null; }

    handlePanelPrev() {
        const rows = this.filteredRows;
        const idx  = rows.findIndex(r => r.id === this.selectedId);
        if (idx > 0) this.selectedId = rows[idx - 1].id;
    }

    handlePanelNext() {
        const rows = this.filteredRows;
        const idx  = rows.findIndex(r => r.id === this.selectedId);
        if (idx < rows.length - 1) this.selectedId = rows[idx + 1].id;
    }

    get panelFields() {
        const r = this.panelRecord;
        if (!r) return [];
        return [
            { key: 'name',       label: 'Nombre',          value: r.name },
            { key: 'type',       label: 'Tipo',            value: r.recordType, isBadge: true, badgeClass: r.rtClass },
            { key: 'email',      label: 'Email',           value: r.email },
            { key: 'phone',      label: 'Teléfono',        value: r.phone },
            { key: 'ciudad',     label: 'Ciudad',          value: r.ciudad },
            { key: 'vendedor',   label: 'Vendedor',        value: r.vendedor },
            { key: 'numOpps',    label: 'Oportunidades',   value: r.numOpps },
            { key: 'fecha',      label: 'Fecha registro',  value: r.fechaRegistro },
        ];
    }

    // ── Sort ────────────────────────────────────────────────────────────────────

    handleSort(e) {
        const field = e.currentTarget.dataset.field;
        if (!field) return;
        this.sortDir   = this.sortField === field && this.sortDir === 'asc' ? 'desc' : 'asc';
        this.sortField = field;
    }

    get headers() {
        const defs = [
            { key: 'name',   field: 'name',       label: 'Nombre' },
            { key: 'type',   field: 'recordType',  label: 'Tipo' },
            { key: 'ciudad', field: 'ciudad',      label: 'Ciudad' },
            { key: 'phone',  field: 'phone',       label: 'Teléfono' },
            { key: 'email',  field: 'email',       label: 'Email' },
            { key: 'opps',   field: '',            label: 'Opps' },
        ];
        return defs.map(h => ({
            ...h,
            thClass: 'vcu-th' + (h.field ? ' vcu-th-sort' : '') + (this.sortField === h.field && h.field ? ' vcu-th-sorted' : ''),
            icon: h.field ? (this.sortField !== h.field ? '↕' : this.sortDir === 'asc' ? '↑' : '↓') : '',
        }));
    }

    // ── Filters ─────────────────────────────────────────────────────────────────

    handleToggleFilters() { this.showFilters = !this.showFilters; }
    handleClearFilters()  { this.filterRules = []; }

    handleAddRule() {
        this.filterRules = [...this.filterRules, {
            id: ++this._ruleCounter,
            field: FILTER_DEFS[0].value,
            op: 'contains',
            value: '',
        }];
    }

    handleRemoveRule(e) {
        const id = parseInt(e.currentTarget.dataset.id, 10);
        this.filterRules = this.filterRules.filter(r => r.id !== id);
    }

    handleFilterField(e) {
        const id    = parseInt(e.currentTarget.dataset.id, 10);
        const field = e.target.value;
        this.filterRules = this.filterRules.map(r => r.id === id ? { ...r, field, op: 'contains', value: '' } : r);
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
        return 'vcu-btn-filters' + (active ? ' vcu-btn-filters-active' : '') + (this.showFilters ? ' vcu-btn-filters-open' : '');
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
        }));
    }

    get filteredRows() {
        const active = this.filterRules.filter(r => r.value?.trim());
        let result = active.length
            ? this.rows.filter(row => active.every(r => {
                const iv = String(row[r.field] || '').toLowerCase();
                const v  = r.value.toLowerCase().trim();
                return r.op === 'contains' ? iv.includes(v) : r.op === 'eq' ? iv === v : iv !== v;
              }))
            : this.rows;

        if (this.sortField) {
            const dir = this.sortDir === 'asc' ? 1 : -1;
            const f   = this.sortField;
            result = [...result].sort((a, b) => String(a[f] ?? '').localeCompare(String(b[f] ?? '')) * dir);
        }

        return result.map(r => ({
            ...r,
            trClass: 'vcu-row' + (this.selectedId === r.id ? ' vcu-row-selected' : ''),
        }));
    }

    get hasError() { return !this.isLoading && !!this.error; }
    get isEmpty()  { return !this.isLoading && !this.error && !this.rows.length; }
    get showTable(){ return !this.isLoading && !this.error && this.rows.length > 0; }
}
