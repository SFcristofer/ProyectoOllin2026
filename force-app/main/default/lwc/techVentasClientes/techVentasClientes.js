import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getClientes from '@salesforce/apex/TechVentasController.getClientes';

const TEXT_OPS = [
    { v: 'contains', l: 'contiene' },
    { v: 'eq',       l: 'es igual a' },
    { v: 'ne',       l: 'no es igual a' },
];
const EQ_OPS  = [{ v: 'eq', l: 'es igual a' }, { v: 'ne', l: 'es diferente a' }];
const NUM_OPS = [
    { v: 'eq',  l: '= igual a' }, { v: 'ne',  l: '≠ diferente' },
    { v: 'gt',  l: '> mayor' },   { v: 'lt',  l: '< menor' },
    { v: 'gte', l: '>= mayor/igual' }, { v: 'lte', l: '<= menor/igual' },
];

const FILTER_FIELD_DEFS_C = [
    { value: 'name',         label: 'Nombre',          type: 'text' },
    { value: 'recordType',   label: 'Tipo',             type: 'picklist', options: ['Cuenta personal','Cuenta negocio','Contratista','Beneficiario'] },
    { value: 'email',        label: 'Email',            type: 'text' },
    { value: 'ciudad',       label: 'Ciudad',           type: 'text' },
    { value: 'numPolizas',   label: 'Núm. Pólizas',     type: 'number' },
    { value: 'numOpps',      label: 'Núm. Oportunidades', type: 'number' },
];

function getOpsForTypeC(type) {
    if (type === 'text')     return TEXT_OPS;
    if (type === 'number')   return NUM_OPS;
    return EQ_OPS;
}

function matchRulesC(item, rules) {
    return rules.every(r => {
        if (!r.value && r.value !== 0) return true;
        const iv = item[r.field];
        const v  = String(r.value).toLowerCase().trim();
        if (r.op === 'contains') return String(iv || '').toLowerCase().includes(v);
        if (r.op === 'eq')       return String(iv || '').toLowerCase() === v;
        if (r.op === 'ne')       return String(iv || '').toLowerCase() !== v;
        const n = parseFloat(iv); const nv = parseFloat(r.value);
        if (r.op === 'gt')  return n > nv;
        if (r.op === 'lt')  return n < nv;
        if (r.op === 'gte') return n >= nv;
        if (r.op === 'lte') return n <= nv;
        return true;
    });
}

const GRID_HEADERS = [
    { key: 'name',         field: 'name',         label: 'Nombre',       sortable: true  },
    { key: 'recordType',   field: 'recordType',   label: 'Tipo',         sortable: true  },
    { key: 'email',        field: 'email',        label: 'Email / Tel',  sortable: false },
    { key: 'ciudad',       field: 'ciudad',       label: 'Ciudad',       sortable: true  },
    { key: 'numPolizas',   field: 'numPolizas',   label: 'Pólizas',      sortable: true  },
    { key: 'numOpps',      field: 'numOpps',      label: 'Oports.',      sortable: true  },
    { key: 'fechaRegistro', field: 'fechaRegistro', label: 'Registrado', sortable: true  },
];

const KANBAN_TYPES = ['Cuenta personal', 'Cuenta negocio', 'Contratista', 'Beneficiario', 'Otro'];

const TYPE_BADGE_MAP = {
    'Cuenta personal': 'vc-type-badge vc-badge-purple',
    'Cuenta negocio':  'vc-type-badge vc-badge-blue',
    'Contratista':     'vc-type-badge vc-badge-teal',
    'Beneficiario':    'vc-type-badge vc-badge-orange',
};

export default class TechVentasClientes extends LightningElement {
    @track _clientes       = [];
    @track searchTerm      = '';
    @track selectedTipo    = '';
    @track viewMode        = 'lista';
    @track sortField       = 'name';
    @track sortDir         = 'asc';
    @track selectedCliente = null;
    @track isLoading       = true;

    @track showFilters       = false;
    @track filterRules       = [];
    _filterRuleCounter       = 0;

    connectedCallback() { this._load(); }

    _load() {
        this.isLoading = true;
        getClientes()
            .then(data => { this._clientes = data || []; })
            .catch(err => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error al cargar clientes',
                    message: err.body?.message,
                    variant: 'error'
                }));
            })
            .finally(() => { this.isLoading = false; });
    }

    /* ── View mode ── */
    get isLista()  { return this.viewMode === 'lista'; }
    get isKanban() { return this.viewMode === 'kanban'; }
    get btnListaClass()  { return 'vc-view-btn' + (this.isLista  ? ' vc-view-active' : ''); }
    get btnKanbanClass() { return 'vc-view-btn' + (this.isKanban ? ' vc-view-active' : ''); }
    handleViewLista()  { this.viewMode = 'lista';  }
    handleViewKanban() { this.viewMode = 'kanban'; }

    /* ── Grid headers with sort arrows ── */
    get gridHeaders() {
        return GRID_HEADERS.map(h => ({
            ...h,
            cellClass: 'vc-grid-cell vc-grid-hdr' +
                       (h.sortable ? ' vc-hdr-sort' : '') +
                       (this.sortField === h.field ? ' vc-sorted' : ''),
            icon: !h.sortable ? '' :
                  this.sortField !== h.field ? '↕' :
                  this.sortDir === 'asc' ? '↑' : '↓'
        }));
    }

    handleSort(e) {
        const field = e.currentTarget.dataset.field;
        if (!field) return;
        if (this.sortField === field) {
            this.sortDir = this.sortDir === 'asc' ? 'desc' : 'asc';
        } else {
            this.sortField = field;
            this.sortDir   = 'asc';
        }
    }

    /* ── Tipo dropdown options ── */
    get tipoOptions() {
        const tipos = [...new Set(this._clientes.map(c => c.recordType).filter(Boolean))].sort();
        return [{ value: '', label: 'Todos los tipos', selected: !this.selectedTipo },
                ...tipos.map(t => ({ value: t, label: t, selected: this.selectedTipo === t }))];
    }

    handleTipoFilter(e) { this.selectedTipo = e.target.value; }

    /* ── Filtered + sorted ── */
    get filtered() {
        let result = this._clientes;
        if (this.selectedTipo) result = result.filter(c => c.recordType === this.selectedTipo);
        if (this.searchTerm) {
            const q = this.searchTerm.toLowerCase();
            result = result.filter(c =>
                (c.name    && c.name.toLowerCase().includes(q)) ||
                (c.email   && c.email.toLowerCase().includes(q)) ||
                (c.ciudad  && c.ciudad.toLowerCase().includes(q)) ||
                (c.company && c.company.toLowerCase().includes(q))
            );
        }
        const active = this.filterRules.filter(r => r.value && String(r.value).trim());
        if (active.length) result = result.filter(item => matchRulesC(item, active));
        return result;
    }

    get filteredSorted() {
        const rows = this.filtered.map((c, i) => ({
            ...c,
            rowNum:         i + 1,
            typeBadge:      TYPE_BADGE_MAP[c.recordType] || 'vc-type-badge vc-badge-gray',
            numPolizasLabel: c.numPolizas != null ? String(c.numPolizas) : '—',
            numOppsLabel:   c.numOpps    != null ? String(c.numOpps)    : '—',
        }));
        if (!this.sortField) return rows;
        const dir = this.sortDir === 'asc' ? 1 : -1;
        const f   = this.sortField;
        return rows.sort((a, b) => {
            const av = a[f] ?? '';
            const bv = b[f] ?? '';
            if (typeof av === 'number' && typeof bv === 'number') return (av - bv) * dir;
            return String(av).localeCompare(String(bv)) * dir;
        });
    }

    get hasClientes() { return this.filteredSorted.length > 0; }

    /* ── Kanban groups ── */
    get kanbanGroups() {
        const all = this.filtered;
        const knownTypes = new Set(KANBAN_TYPES.slice(0, -1));
        return KANBAN_TYPES.map(type => {
            const cards = type === 'Otro'
                ? all.filter(c => !knownTypes.has(c.recordType))
                : all.filter(c => c.recordType === type);
            return {
                type,
                badgeClass: 'vc-kol-badge ' + (TYPE_BADGE_MAP[type] || 'vc-badge-gray'),
                count:    cards.length,
                hasCards: cards.length > 0,
                cards: cards.map(c => ({
                    ...c,
                    typeBadge: TYPE_BADGE_MAP[c.recordType] || 'vc-type-badge vc-badge-gray',
                }))
            };
        }).filter(g => g.hasCards);
    }

    /* ── Filtros avanzados ── */
    get filterBtnClass() {
        const active = this.filterRules.some(r => r.value && String(r.value).trim());
        return 'vc-btn-filters' + (active ? ' vc-btn-filters-active' : '') + (this.showFilters ? ' vc-btn-filters-open' : '');
    }
    get filterBtnLabel() {
        const count = this.filterRules.filter(r => r.value && String(r.value).trim()).length;
        return count > 0 ? `Filtros (${count})` : 'Filtros';
    }
    get hasFilterRules() { return this.filterRules.length > 0; }
    get filterRulesView() {
        return this.filterRules.map(r => {
            const def = FILTER_FIELD_DEFS_C.find(f => f.value === r.field) || FILTER_FIELD_DEFS_C[0];
            const ops = getOpsForTypeC(def.type);
            return {
                id: r.id, field: r.field, op: r.op, value: r.value,
                fieldOptions: FILTER_FIELD_DEFS_C.map(f => ({ value: f.value, label: f.label, selected: f.value === r.field })),
                opOptions:    ops.map(o => ({ value: o.v, label: o.l, selected: o.v === r.op })),
                isText:       def.type === 'text' || def.type === 'number',
                isPicklist:   def.type === 'picklist',
                inputType:    def.type === 'number' ? 'number' : 'text',
                picklistOptions: def.type === 'picklist'
                    ? (def.options || []).map(o => ({ value: o, label: o, selected: o === r.value }))
                    : [],
            };
        });
    }
    handleToggleFilters()      { this.showFilters = !this.showFilters; }
    handleClearFilters()       { this.filterRules = []; }
    handleAddRule() {
        const def = FILTER_FIELD_DEFS_C[0];
        const ops = getOpsForTypeC(def.type);
        this.filterRules = [...this.filterRules, { id: ++this._filterRuleCounter, field: def.value, op: ops[0].v, value: '' }];
    }
    handleRemoveRule(e) {
        const id = parseInt(e.currentTarget.dataset.id, 10);
        this.filterRules = this.filterRules.filter(r => r.id !== id);
    }
    handleFilterFieldChange(e) {
        const id    = parseInt(e.currentTarget.dataset.id, 10);
        const field = e.target.value;
        const def   = FILTER_FIELD_DEFS_C.find(f => f.value === field) || FILTER_FIELD_DEFS_C[0];
        const ops   = getOpsForTypeC(def.type);
        this.filterRules = this.filterRules.map(r => r.id === id ? { ...r, field, op: ops[0].v, value: '' } : r);
    }
    handleFilterOpChange(e) {
        const id = parseInt(e.currentTarget.dataset.id, 10);
        this.filterRules = this.filterRules.map(r => r.id === id ? { ...r, op: e.target.value } : r);
    }
    handleFilterValueChange(e) {
        const id = parseInt(e.currentTarget.dataset.id, 10);
        this.filterRules = this.filterRules.map(r => r.id === id ? { ...r, value: e.target.value } : r);
    }

    /* ── Events ── */
    handleSearch(e)    { this.searchTerm = e.target.value; }
    handleCloseDetail() { this.selectedCliente = null; }

    handleRowClick(e) {
        const id = e.currentTarget.dataset.id;
        const found = this._clientes.find(c => c.id === id);
        if (!found) return;
        this.selectedCliente = {
            ...found,
            typeBadge:      TYPE_BADGE_MAP[found.recordType] || 'vc-type-badge vc-badge-gray',
            numPolizasLabel: found.numPolizas != null ? String(found.numPolizas) : '0',
            numOppsLabel:   found.numOpps    != null ? String(found.numOpps)    : '0',
        };
    }

    handleNuevoCliente() {
        this.dispatchEvent(new CustomEvent('nuevocliente', { bubbles: true, composed: true }));
    }

    /* ── Public refresh ── */
    refresh() { this._load(); }
}