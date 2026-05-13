import { LightningElement, track } from 'lwc';
import getPrecalificacionList from '@salesforce/apex/TechPrecalificacionController.getPrecalificacionList';

const MONEY = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN', maximumFractionDigits: 0 });
function fmt(v) { return v == null ? '—' : MONEY.format(v); }
function fmtNum(v) { return v == null ? '—' : v.toFixed(1); }

const FILTER_DEFS = [
    { value: 'name',          label: 'Nombre',      type: 'text' },
    { value: 'contratistaName', label: 'Contratista', type: 'text' },
    { value: 'estadoLabel',   label: 'Estado',      type: 'text' },
];

const TEXT_OPS = [{ v: 'contains', l: 'contiene' }, { v: 'eq', l: 'es igual a' }, { v: 'ne', l: 'no es igual a' }];

const RT_CLASS = {
    'Aprobado':  'vpf-badge vpf-badge-green',
    'Rechazado': 'vpf-badge vpf-badge-red',
};

export default class TechVentasPrecalificaciones extends LightningElement {
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
            const raw = await getPrecalificacionList();
            this.rows = (raw || []).map(r => ({
                id:            r.id,
                name:          r.name || '—',
                contratistaName: r.contratistaName || '—',
                estadoLabel:   r.estadoAutomatico || r.estado || '—',
                estatusClass:  RT_CLASS[r.estadoAutomatico || r.estado] || 'vpf-badge vpf-badge-amber',
                scoreICP:      r.scoreICP != null ? fmtNum(r.scoreICP) : '—',
                lineaFmt:      fmt(r.lineaAfianzamiento),
                capitalFmt:    fmt(r.capitalContable),
                _raw: r,
                trClass: 'vpf-row',
            }));
            this._cache = this.rows;
        } catch (e) {
            this.error = e?.body?.message || 'Error al cargar precalificaciones';
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
        const raw = r._raw;
        return [
            { key: 'name',          label: 'Nombre',             value: r.name },
            { key: 'contratista',   label: 'Contratista',        value: r.contratistaName },
            { key: 'estado',        label: 'Estado',             value: r.estadoLabel, isBadge: true, badgeClass: r.estatusClass },
            { key: 'scoreICP',      label: 'Score ICP',          value: r.scoreICP },
            { key: 'linea',         label: 'Línea afianzamiento',value: r.lineaFmt, isMoney: true },
            { key: 'capital',       label: 'Capital contable',   value: r.capitalFmt, isMoney: true },
            { key: 'ventas',        label: 'Ventas netas',       value: fmt(raw.ventasNetas), isMoney: true },
            { key: 'liquidez',      label: 'Liquidez',           value: raw.liquidez != null ? fmtNum(raw.liquidez) : '—' },
            { key: 'apalancamiento',label: 'Apalancamiento',     value: raw.apalancamiento != null ? fmtNum(raw.apalancamiento) : '—' },
            { key: 'resultado',     label: 'Resultado afianz.',  value: fmt(raw.resultadoAfianzamiento), isMoney: true },
            { key: 'capacidad',     label: 'Capacidad afianz.',  value: raw.capacidadAfianzamiento || '—' },
            { key: 'comentarios',   label: 'Comentarios',        value: raw.comentarios || '—' },
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
            { key: 'name',          field: 'name',           label: 'Nombre' },
            { key: 'contratista',   field: 'contratistaName',label: 'Contratista' },
            { key: 'estado',        field: 'estadoLabel',    label: 'Estado' },
            { key: 'scoreICP',      field: '',               label: 'Score ICP' },
            { key: 'linea',         field: '',               label: 'Línea afianz.' },
            { key: 'capital',       field: '',               label: 'Capital contable' },
        ];
        return defs.map(h => ({
            ...h,
            thClass: 'vpf-th' + (h.field ? ' vpf-th-sort' : '') + (this.sortField === h.field && h.field ? ' vpf-th-sorted' : ''),
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
        return 'vpf-btn-filters' + (active ? ' vpf-btn-filters-active' : '') + (this.showFilters ? ' vpf-btn-filters-open' : '');
    }

    get filterBtnLabel() {
        const n = this.filterRules.filter(r => r.value?.trim()).length;
        return n > 0 ? `Filtros (${n})` : 'Filtros';
    }

    get hasFilterRules() { return this.filterRules.length > 0; }

    get filterRulesView() {
        return this.filterRules.map(r => {
            const def = FILTER_DEFS.find(f => f.value === r.field) || FILTER_DEFS[0];
            return {
                id: r.id, field: r.field, op: r.op, value: r.value,
                fieldOptions: FILTER_DEFS.map(f => ({ value: f.value, label: f.label, selected: f.value === r.field })),
                opOptions:    TEXT_OPS.map(o => ({ value: o.v, label: o.l, selected: o.v === r.op })),
            };
        });
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
            trClass: 'vpf-row' + (this.selectedId === r.id ? ' vpf-row-selected' : ''),
        }));
    }

    get hasError() { return !this.isLoading && !!this.error; }
    get isEmpty()  { return !this.isLoading && !this.error && !this.rows.length; }
    get showTable(){ return !this.isLoading && !this.error && this.rows.length > 0; }
}
