import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOportunidades      from '@salesforce/apex/TechVentasController.getOportunidades';
import actualizarStageOpp    from '@salesforce/apex/TechVentasController.actualizarStageOpp';
import actualizarOportunidad from '@salesforce/apex/TechVentasController.actualizarOportunidad';

const STAGES = [
    { value: 'Cotización',        headerClass: 'vp-col-badge vp-col-gray'   },
    { value: 'Propuesta enviada', headerClass: 'vp-col-badge vp-col-blue'   },
    { value: 'Negociación',       headerClass: 'vp-col-badge vp-col-orange' },
    { value: 'Cierre ganado',     headerClass: 'vp-col-badge vp-col-green'  },
    { value: 'Cierre perdido',    headerClass: 'vp-col-badge vp-col-red'    },
];

const RAMOS         = ['Seguros de auto', 'Vida', 'Gastos Médicos', 'Daños', 'Fianzas'];
const METODOS_PAGO  = ['Efectivo', 'Transferencia', 'Cheque', 'Tarjeta de Crédito', 'Tarjeta de Débito', 'Cargo Automático'];
const PERIODOS_PAGO = ['Anual', 'Semestral', 'Trimestral', 'Mensual'];

const FIELD_API = {
    stageName:   { api: 'StageName',          isNum: false, isDate: false },
    amount:      { api: 'Amount',             isNum: true,  isDate: false },
    comision:    { api: 'PctComisionOllin__c', isNum: true,  isDate: false },
    ramo:        { api: 'Ramo__c',            isNum: false, isDate: false },
    closeDate:   { api: 'CloseDate',          isNum: false, isDate: true  },
    vigencia:      { api: 'Vigencia__c',             isNum: true,  isDate: false },
    numeroPagos:   { api: 'Numero_Pagos__c',         isNum: true,  isDate: false },
    fechaInicioVig:{ api: 'Fecha_Inicio_Vigencia__c', isNum: false, isDate: true  },
    fechaFinVig:   { api: 'Fecha_Fin_Vigencia__c',    isNum: false, isDate: true  },
    metodoPago:    { api: 'Metodo_Pago__c',           isNum: false, isDate: false },
    periodoPago:   { api: 'Periodo_Pago__c',          isNum: false, isDate: false },
};

// ── Filtros server-side ───────────────────────────────────────────────────────

const TEXT_OPS = [
    { v: 'contains', l: 'contiene' },
    { v: 'eq',       l: 'es igual a' },
    { v: 'ne',       l: 'no es igual a' },
];
const EQ_OPS = [
    { v: 'eq', l: 'es igual a' },
    { v: 'ne', l: 'es diferente a' },
];
const NUM_OPS = [
    { v: 'eq',  l: '= igual a' },
    { v: 'ne',  l: '≠ diferente de' },
    { v: 'gt',  l: '> mayor que' },
    { v: 'lt',  l: '< menor que' },
    { v: 'gte', l: '>= mayor o igual' },
    { v: 'lte', l: '<= menor o igual' },
];
const DATE_OPS = [
    { v: 'gt',  l: 'después de' },
    { v: 'lt',  l: 'antes de' },
    { v: 'gte', l: 'desde (inclusive)' },
    { v: 'lte', l: 'hasta (inclusive)' },
    { v: 'eq',  l: 'igual a' },
];

const FILTER_FIELD_DEFS = [
    { value: 'name',        label: 'Nombre',       type: 'text'     },
    { value: 'accountName', label: 'Cliente',       type: 'text'     },
    { value: 'ramo',        label: 'Ramo',          type: 'picklist', options: RAMOS },
    { value: 'stageName',   label: 'Etapa',         type: 'picklist', options: STAGES.map(s => s.value) },
    { value: 'amount',      label: 'Importe',       type: 'number'   },
    { value: 'vigencia',    label: 'Vigencia',      type: 'number'   },
    { value: 'closeDate',   label: 'Fecha Cierre',  type: 'date'     },
    { value: 'metodoPago',  label: 'Método Pago',   type: 'picklist', options: METODOS_PAGO },
    { value: 'periodoPago', label: 'Período Pago',  type: 'picklist', options: PERIODOS_PAGO },
];

function getOpsForType(type) {
    if (type === 'text')   return TEXT_OPS;
    if (type === 'number') return NUM_OPS;
    if (type === 'date')   return DATE_OPS;
    return EQ_OPS;
}

// ─────────────────────────────────────────────────────────────────────────────

export default class TechVentasPipeline extends LightningElement {
    @track searchTerm     = '';
    @track selectedRamo   = '';
    @track selectedOpp    = null;
    @track _opps          = [];
    @track _dragOverStage = null;
    @track viewMode       = 'lista';
    @track sortField      = '';
    @track sortDir        = 'asc';

    // Inline edit
    @track inlineId    = null;
    @track inlineField = null;
    @track inlineVal   = '';
    @track errorId     = null;
    _errorTimer        = null;

    // Filtros server-side
    @track showFilters  = false;
    @track filterRules  = [];
    @track isApplying   = false;
    _filterRuleCounter  = 0;

    _draggingId  = null;
    _dragCounter = {};
    _didDrag     = false;

    connectedCallback() { this._load(); }

    renderedCallback() {
        if (this.inlineId && this.inlineVal) {
            const sel = this.template.querySelector('.vp-inline-select');
            if (sel && sel.value !== this.inlineVal) sel.value = this.inlineVal;
        }
        const focusFields = ['amount', 'comision', 'vigencia', 'numeroPagos', 'closeDate', 'fechaInicioVig', 'fechaFinVig'];
        if (this.inlineId && focusFields.includes(this.inlineField)) {
            const inp = this.template.querySelector('.vp-inline-input');
            if (inp && document.activeElement !== inp) { inp.focus(); if (inp.select && this.inlineField !== 'closeDate') inp.select(); }
        }
    }

    _load() {
        const validRules = this.filterRules.filter(r => r.value && String(r.value).trim());
        const filtersJson = validRules.length > 0
            ? JSON.stringify(validRules.map(r => ({ field: r.field, op: r.op, value: String(r.value) })))
            : null;
        getOportunidades({ filtersJson })
            .then(data => { this._opps = data || []; })
            .catch(() => {});
    }

    /* ── View mode ── */
    get isLista()  { return this.viewMode === 'lista'; }
    get isKanban() { return this.viewMode === 'kanban'; }

    get btnListaClass()  { return 'vp-view-btn' + (this.isLista  ? ' vp-view-active' : ''); }
    get btnKanbanClass() { return 'vp-view-btn' + (this.isKanban ? ' vp-view-active' : ''); }

    handleViewLista()  { this.viewMode = 'lista';  this._clearInline(); }
    handleViewKanban() { this.viewMode = 'kanban'; this._clearInline(); }

    /* ── Inline options ── */
    get stageInlineOptions() { return STAGES.map(s => ({ key: s.value, value: s.value, label: s.value })); }
    get ramoInlineOptions()  { return RAMOS.map(r => ({ key: r, value: r, label: r })); }
    get metPagoOptions()     { return METODOS_PAGO.map(m => ({ key: m, value: m, label: m })); }
    get perPagoOptions()     { return PERIODOS_PAGO.map(p => ({ key: p, value: p, label: p })); }

    /* ── Inline open ── */
    handleInlineOpen(e) {
        e.stopPropagation();
        const id    = e.currentTarget.dataset.id;
        const field = e.currentTarget.dataset.field;
        const val   = e.currentTarget.dataset.val || '';
        if (this.inlineId === id && this.inlineField === field) { this._clearInline(); return; }
        this.inlineId    = id;
        this.inlineField = field;
        this.inlineVal   = val;
    }

    handleInlineSelectChange(e) { e.stopPropagation(); this._commitInline(e.target.value); }
    handleInlineInputChange(e)  { this.inlineVal = e.target.value; }

    handleInlineInputKey(e) {
        e.stopPropagation();
        if (e.key === 'Enter')  { this._commitInline(e.target.value); }
        if (e.key === 'Escape') { this._clearInline(); }
    }

    handleInlineInputBlur(e) { if (this.inlineId) this._commitInline(e.target.value); }
    handleInlineCancel(e)    { e.stopPropagation(); this._clearInline(); }
    handleSelectClick(e)     { e.stopPropagation(); }

    _commitInline(rawVal) {
        const id    = this.inlineId;
        const field = this.inlineField;
        if (!id || !field) return;
        const def = FIELD_API[field];
        if (!def) { this._clearInline(); return; }

        const val = def.isNum ? (parseFloat(rawVal) || 0) : rawVal;

        this._opps = this._opps.map(o => {
            if (o.id !== id) return o;
            const patch = { [field]: val };
            if (field === 'amount')    patch.amountFmt  = val ? '$' + Number(val).toLocaleString('es-MX') : null;
            if (field === 'stageName') patch.stageClass = this._stageBadge(val);
            return { ...o, ...patch };
        });
        this._clearInline();

        actualizarOportunidad({ opp: { sobjectType: 'Opportunity', Id: id, [def.api]: val || null } })
            .catch(err => { this._load(); this._showError(err, id); });
    }

    _clearInline() { this.inlineId = null; this.inlineField = null; this.inlineVal = ''; }

    _stageBadge(s) {
        if (s == null)                     return 'vt-badge-gray';
        if (s === 'Cierre ganado')         return 'vt-badge-green';
        if (s === 'Cierre perdido')        return 'vt-badge-red';
        if (s === 'Negociación')           return 'vt-badge-orange';
        if (s === 'Propuesta enviada')     return 'vt-badge-blue';
        return 'vt-badge-gray';
    }

    /* ── List headers ── */
    get listHeaders() {
        const sf = this.sortField;
        const sd = this.sortDir;
        const req = ' vp-hdr-required';
        const s = (field, label, required = false) => ({
            key: field, field, label, sortable: true,
            cellClass: 'vp-list-cell vp-list-hdr vp-hdr-sort' + (sf === field ? ' vp-sorted' : '') + (required ? req : ''),
            icon: sf === field ? (sd === 'asc' ? '↑' : '↓') : '⇅',
        });
        const n = (key, label, required = false) => ({
            key, field: '', label, sortable: false,
            cellClass: 'vp-list-cell vp-list-hdr' + (required ? req : ''),
            icon: '',
        });
        return [
            n('edit',          ''),
            s('name',          'Nombre'),
            s('prospectoName', 'Prospecto'),
            s('clientName',    'Cliente'),
            s('ramo',          'Ramo ✎',          true),
            s('amount',        'Importe ✎',        true),
            s('comision',      '% Comisión ✎'),
            n('productoName',  'Producto',          true),
            s('vendedor',      'Vendedor',          true),
            s('stageName',     'Etapa ✎'),
            s('closeDate',     'Cierre ✎'),
            s('vigencia',      'Vigencia ✎',       true),
            s('numeroPagos',   'Núm. Pagos ✎',     true),
            s('fechaInicioVig','Inicio Vig. ✎',    true),
            s('fechaFinVig',   'Fin Vig. ✎',       true),
            s('metodoPago',    'Método Pago ✎',    true),
            s('periodoPago',   'Período Pago ✎',   true),
            n('polizaRenovarNombre', 'Póliza a renovar'),
        ];
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

    /* ── Ramo filter (client) ── */
    get ramoOptions() {
        const ramos = [...new Set(this._opps.map(o => o.ramo).filter(Boolean))].sort();
        return [{ value: '', label: 'Todos los ramos', selected: !this.selectedRamo },
                ...ramos.map(r => ({ value: r, label: r, selected: this.selectedRamo === r }))];
    }

    handleRamoFilter(e) { this.selectedRamo = e.target.value; }

    /* ── Filtered + sorted ── */
    get filtered() {
        let result = this._opps;
        if (this.selectedRamo) result = result.filter(o => o.ramo === this.selectedRamo);
        if (this.searchTerm) {
            const q = this.searchTerm.toLowerCase();
            result = result.filter(o =>
                (o.name          && o.name.toLowerCase().includes(q))          ||
                (o.clientName    && o.clientName.toLowerCase().includes(q))    ||
                (o.ramo          && o.ramo.toLowerCase().includes(q))          ||
                (o.prospectoName && o.prospectoName.toLowerCase().includes(q)) ||
                (o.productoName  && o.productoName.toLowerCase().includes(q))
            );
        }
        return result;
    }

    get filteredSorted() {
        const rows = [...this.filtered].map((o, i) => ({
            ...o,
            rowNum:            i + 1,
            comisionFmt:       o.comision != null ? o.comision + '%' : null,
            isEditingStage:    this.inlineId === o.id && this.inlineField === 'stageName',
            isEditingAmount:   this.inlineId === o.id && this.inlineField === 'amount',
            isEditingComision: this.inlineId === o.id && this.inlineField === 'comision',
            isEditingRamo:     this.inlineId === o.id && this.inlineField === 'ramo',
            isEditingClose:    this.inlineId === o.id && this.inlineField === 'closeDate',
            isEditingVigencia:   this.inlineId === o.id && this.inlineField === 'vigencia',
            isEditingNumPagos:   this.inlineId === o.id && this.inlineField === 'numeroPagos',
            isEditingFechaIni:   this.inlineId === o.id && this.inlineField === 'fechaInicioVig',
            isEditingFechaFin:   this.inlineId === o.id && this.inlineField === 'fechaFinVig',
            isEditingMetPago:    this.inlineId === o.id && this.inlineField === 'metodoPago',
            rowClass: 'vp-list-row vp-list-data' + (this.errorId === o.id ? ' vp-row-error' : ''),
            isEditingPerPago:  this.inlineId === o.id && this.inlineField === 'periodoPago',
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

    get hasFiltered() { return this.filteredSorted.length > 0; }

    /* ── Kanban columns ── */
    get columns() {
        const opps = this.filtered;
        return STAGES.map(s => {
            const cards = opps.filter(o => o.stageName === s.value);
            const total = cards.reduce((acc, o) => acc + (o.amount || 0), 0);
            const isDragOver = this._dragOverStage === s.value;
            return {
                stage:       s.value,
                headerClass: s.headerClass,
                columnClass: 'vp-column' + (isDragOver ? ' vp-column-dragover' : ''),
                isDragOver,
                count:       cards.length,
                hasCards:    cards.length > 0,
                totalFmt:    total > 0 ? '$' + total.toLocaleString('es-MX', { maximumFractionDigits: 0 }) : null,
                cards: cards.map(o => ({
                    ...o,
                    cardClass: 'vp-card' + (o.id === this._draggingId ? ' vp-card-dragging' : '')
                }))
            };
        });
    }

    get stageOptions() {
        return STAGES.map(s => ({
            value:    s.value,
            label:    s.value,
            btnClass: 'vp-stage-btn' + (this.selectedOpp && this.selectedOpp.stageName === s.value ? ' vp-stage-btn-active' : '')
        }));
    }

    /* ── Filtros server-side ── */

    get filterBtnClass() {
        const active = this.filterRules.some(r => r.value && String(r.value).trim());
        return 'vp-btn-filters' + (active ? ' vp-btn-filters-active' : '') + (this.showFilters ? ' vp-btn-filters-open' : '');
    }

    get filterBtnLabel() {
        const count = this.filterRules.filter(r => r.value && String(r.value).trim()).length;
        return count > 0 ? `Filtros (${count})` : 'Filtros';
    }

    get hasFilterRules()  { return this.filterRules.length > 0; }
    get applyBtnLabel()   { return this.isApplying ? 'Aplicando...' : 'Aplicar filtros'; }

    get filterRulesView() {
        return this.filterRules.map(r => {
            const def  = FILTER_FIELD_DEFS.find(f => f.value === r.field) || FILTER_FIELD_DEFS[0];
            const ops  = getOpsForType(def.type);
            return {
                id:             r.id,
                field:          r.field,
                op:             r.op,
                value:          r.value,
                fieldOptions:   FILTER_FIELD_DEFS.map(f => ({ value: f.value, label: f.label, selected: f.value === r.field })),
                opOptions:      ops.map(o => ({ value: o.v, label: o.l, selected: o.v === r.op })),
                isText:         def.type === 'text' || def.type === 'number',
                isDate:         def.type === 'date',
                isPicklist:     def.type === 'picklist',
                inputType:      def.type === 'number' ? 'number' : 'text',
                picklistOptions: def.type === 'picklist'
                    ? (def.options || []).map(o => ({ value: o, label: o, selected: o === r.value }))
                    : [],
            };
        });
    }

    handleToggleFilters() { this.showFilters = !this.showFilters; }

    handleAddRule() {
        const def = FILTER_FIELD_DEFS[0];
        const ops = getOpsForType(def.type);
        this.filterRules = [...this.filterRules, {
            id:    ++this._filterRuleCounter,
            field: def.value,
            op:    ops[0].v,
            value: '',
        }];
    }

    handleRemoveRule(e) {
        const id = parseInt(e.currentTarget.dataset.id, 10);
        this.filterRules = this.filterRules.filter(r => r.id !== id);
    }

    handleFilterFieldChange(e) {
        const id    = parseInt(e.currentTarget.dataset.id, 10);
        const field = e.target.value;
        const def   = FILTER_FIELD_DEFS.find(f => f.value === field) || FILTER_FIELD_DEFS[0];
        const ops   = getOpsForType(def.type);
        this.filterRules = this.filterRules.map(r =>
            r.id === id ? { ...r, field, op: ops[0].v, value: '' } : r
        );
    }

    handleFilterOpChange(e) {
        const id = parseInt(e.currentTarget.dataset.id, 10);
        const op = e.target.value;
        this.filterRules = this.filterRules.map(r => r.id === id ? { ...r, op } : r);
    }

    handleFilterValueChange(e) {
        const id    = parseInt(e.currentTarget.dataset.id, 10);
        const value = e.target.value;
        this.filterRules = this.filterRules.map(r => r.id === id ? { ...r, value } : r);
    }

    handleApplyFilters()  { this._applyFilters(); }

    handleClearFilters() {
        this.filterRules = [];
        this._applyFilters();
    }

    _applyFilters() {
        this.isApplying = true;
        const validRules = this.filterRules.filter(r => r.value && String(r.value).trim());
        const filtersJson = validRules.length > 0
            ? JSON.stringify(validRules.map(r => ({ field: r.field, op: r.op, value: String(r.value) })))
            : null;
        getOportunidades({ filtersJson })
            .then(data => { this._opps = data || []; this.isApplying = false; })
            .catch(() => { this.isApplying = false; });
    }

    /* ── Search & selection ── */
    handleSearch(e)     { this.searchTerm = e.target.value; }
    handleCloseDetail() { this.selectedOpp = null; }

    handleRowClick(e) {
        if (this.inlineId) { this._clearInline(); return; }
        const id = e.currentTarget.dataset.id;
        this.selectedOpp = this._opps.find(o => o.id === id) || null;
    }

    handleRowEditBtn(e) {
        e.stopPropagation();
        const id  = e.currentTarget.dataset.id;
        const opp = this._opps.find(o => o.id === id);
        if (opp) this.dispatchEvent(new CustomEvent('editopen', { detail: opp, bubbles: true, composed: true }));
    }

    handleCardClick(e) {
        if (this._didDrag) { this._didDrag = false; return; }
        const id = e.currentTarget.dataset.id;
        this.selectedOpp = this._opps.find(o => o.id === id) || null;
    }

    handleNuevaOpp() { this.dispatchEvent(new CustomEvent('nuevaopp')); }

    handleEditOpen() {
        this.dispatchEvent(new CustomEvent('editopen', { detail: this.selectedOpp, bubbles: true, composed: true }));
        this.selectedOpp = null;
    }

    /* ── Stage change from detail panel ── */
    handleChangeStage(e) {
        const stage = e.currentTarget.dataset.stage;
        if (!this.selectedOpp || this.selectedOpp.stageName === stage) return;
        this._updateStage(this.selectedOpp.id, stage);
        this.selectedOpp = { ...this.selectedOpp, stageName: stage };
    }

    /* ── Drag & Drop ── */
    handleDragStart(e) {
        this._draggingId = e.currentTarget.dataset.id;
        this._didDrag    = true;
        e.dataTransfer.effectAllowed = 'move';
        e.dataTransfer.setData('text/plain', this._draggingId);
    }

    handleDragEnd() {
        this._draggingId    = null;
        this._dragOverStage = null;
        this._dragCounter   = {};
    }

    handleDragEnter(e) {
        e.preventDefault();
        const stage = e.currentTarget.dataset.stage;
        if (!stage) return;
        this._dragCounter[stage] = (this._dragCounter[stage] || 0) + 1;
        this._dragOverStage = stage;
    }

    handleDragLeave(e) {
        const stage = e.currentTarget.dataset.stage;
        if (!stage) return;
        this._dragCounter[stage] = (this._dragCounter[stage] || 1) - 1;
        if (this._dragCounter[stage] <= 0) {
            this._dragCounter[stage] = 0;
            if (this._dragOverStage === stage) this._dragOverStage = null;
        }
    }

    handleDragOver(e) {
        e.preventDefault();
        e.dataTransfer.dropEffect = 'move';
    }

    handleDrop(e) {
        e.preventDefault();
        const targetStage = e.currentTarget.dataset.stage;
        const oppId = this._draggingId || e.dataTransfer.getData('text/plain');
        this._dragOverStage = null;
        this._dragCounter   = {};
        this._draggingId    = null;
        if (!oppId || !targetStage) return;
        const opp = this._opps.find(o => o.id === oppId);
        if (!opp || opp.stageName === targetStage) return;
        this._updateStage(oppId, targetStage);
    }

    _showError(err, id) {
        const raw = err?.body?.message || err?.message || '';
        const match = raw.match(/[A-Z_]+_EXCEPTION[,:\s]+(.+?)(?:\.\s*\[\])?\s*$/);
        const msg   = match ? match[1].trim() : (raw || 'No fue posible guardar el cambio');
        this.dispatchEvent(new ShowToastEvent({
            title:   'No fue posible guardar',
            message: msg,
            variant: 'error',
            mode:    'sticky'
        }));
        if (id) {
            this.errorId = id;
            if (this._errorTimer) clearTimeout(this._errorTimer);
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this._errorTimer = setTimeout(() => { this.errorId = null; }, 5000);
        }
    }

    _updateStage(oppId, stage) {
        this._opps = this._opps.map(o => o.id === oppId ? { ...o, stageName: stage, stageClass: this._stageBadge(stage) } : o);
        actualizarStageOpp({ oppId, stage }).catch(err => { this._load(); this._showError(err, oppId); });
    }

    @api refresh() { this._load(); }
}
