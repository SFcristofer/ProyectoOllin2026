import { LightningElement, api, track } from 'lwc';
import getLeads                       from '@salesforce/apex/TechVentasController.getLeads';
import actualizarScoreLead            from '@salesforce/apex/TechVentasController.actualizarScoreLead';
import actualizarLead                 from '@salesforce/apex/TechVentasController.actualizarLead';
import getPrecalificacionesByProspecto from '@salesforce/apex/TechPrecalificacionController.getPrecalificacionesByProspecto';

const STATUSES = [
    'Nuevo', 'Recopilando info', 'Precalificado',
    'Transferido a agente', 'Calificado', 'No Calificado'
];
const TIPOS_SEGURO  = ['Seguros de auto', 'Vida', 'Gastos Médicos', 'Daños', 'Fianzas'];
const LEAD_SOURCES  = ['ContactoReferido', 'Campaña', 'Whatsapp', 'Tienda en línea', 'Redes Sociales', 'Agentforce'];

const KANBAN_COLS = [
    { key: 'Nuevo',               label: 'Nuevo',         colStyle: 'border-top:3px solid #6b7280' },
    { key: 'Recopilando info',    label: 'Recopilando',   colStyle: 'border-top:3px solid #3b82f6' },
    { key: 'Precalificado',       label: 'Precalificado', colStyle: 'border-top:3px solid #8b5cf6' },
    { key: 'Transferido a agente', label: 'En agente',    colStyle: 'border-top:3px solid #f59e0b' },
    { key: 'Calificado',          label: 'Calificado',    colStyle: 'border-top:3px solid #16a34a' },
    { key: 'No Calificado',       label: 'No Calificado', colStyle: 'border-top:3px solid #dc2626' },
];

const FIELD_API = {
    status:        { api: 'Status',            isNum: false },
    tipoSeguro:    { api: 'Tipo_de_seguro__c',  isNum: false },
    leadSource:    { api: 'LeadSource',         isNum: false },
    monto:         { api: 'Monto__c',           isNum: true  },
    rating:        { api: 'Rating',             isNum: false },
    sumaAsegurada: { api: 'Suma_asegurada__c',  isNum: true  },
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
    { value: 'name',       label: 'Nombre',      type: 'text'     },
    { value: 'company',    label: 'Empresa',      type: 'text'     },
    { value: 'status',     label: 'Estatus',      type: 'picklist', options: STATUSES },
    { value: 'tipoSeguro', label: 'Tipo Seguro',  type: 'picklist', options: TIPOS_SEGURO },
    { value: 'score',      label: 'Score IA',     type: 'number'   },
    { value: 'rating',     label: 'Rating',       type: 'picklist', options: ['Hot', 'Warm', 'Cold'] },
    { value: 'leadSource', label: 'Origen',       type: 'picklist', options: LEAD_SOURCES },
    { value: 'createdDate',label: 'Fecha Captura',type: 'date'     },
];

function getOpsForType(type) {
    if (type === 'text')   return TEXT_OPS;
    if (type === 'number') return NUM_OPS;
    if (type === 'date')   return DATE_OPS;
    return EQ_OPS;
}

// ─────────────────────────────────────────────────────────────────────────────

export default class TechVentasLeads extends LightningElement {
    @track _leads       = [];
    @track searchTerm   = '';
    @track viewMode     = 'lista';
    @track sortField    = '';
    @track sortDir      = 'asc';
    @track selectedLead = null;
    @track editScore    = 0;
    @track isSavingScore = false;

    // Precalificaciones
    @track showPrecalModal        = false;
    @track editingPrecalId        = null;
    @track panelPrecalificaciones = [];

    // Inline edit
    @track inlineId    = null;
    @track inlineField = null;
    @track inlineVal   = '';

    // Kanban DnD
    _draggedId         = null;
    @track dragOverCol = null;

    // Filtros server-side
    @track showFilters  = false;
    @track filterRules  = [];
    @track isApplying   = false;
    _filterRuleCounter  = 0;

    connectedCallback() { this._load(); }

    renderedCallback() {
        if (this.inlineId && this.inlineVal) {
            const sel = this.template.querySelector('.vl-inline-select');
            if (sel && sel.value !== this.inlineVal) sel.value = this.inlineVal;
        }
        const numFields = ['monto', 'sumaAsegurada'];
        if (this.inlineId && numFields.includes(this.inlineField)) {
            const inp = this.template.querySelector('.vl-inline-input');
            if (inp && document.activeElement !== inp) { inp.focus(); inp.select(); }
        }
    }

    _load() {
        const validRules = this.filterRules.filter(r => r.value && String(r.value).trim());
        const filtersJson = validRules.length > 0
            ? JSON.stringify(validRules.map(r => ({ field: r.field, op: r.op, value: String(r.value) })))
            : null;
        getLeads({ filtersJson })
            .then(data => { this._leads = (data || []).map(l => ({ ...l })); })
            .catch(() => {});
    }

    /* ── View toggle ── */
    get isLista()        { return this.viewMode === 'lista'; }
    get isKanban()       { return this.viewMode === 'kanban'; }
    get btnListaClass()  { return 'vl-view-btn' + (this.isLista  ? ' vl-view-active' : ''); }
    get btnKanbanClass() { return 'vl-view-btn' + (this.isKanban ? ' vl-view-active' : ''); }
    handleViewLista()    { this.viewMode = 'lista';  this._clearInline(); }
    handleViewKanban()   { this.viewMode = 'kanban'; this._clearInline(); }

    /* ── Filtered + sorted leads ── */
    get filteredLeads() {
        const q = (this.searchTerm || '').toLowerCase();
        let list = q
            ? this._leads.filter(l =>
                (l.name       && l.name.toLowerCase().includes(q))      ||
                (l.company    && l.company.toLowerCase().includes(q))   ||
                (l.status     && l.status.toLowerCase().includes(q))    ||
                (l.tipoSeguro && l.tipoSeguro.toLowerCase().includes(q))||
                (l.vendedor   && l.vendedor.toLowerCase().includes(q))
              )
            : [...this._leads];

        if (this.sortField) {
            const dir = this.sortDir === 'asc' ? 1 : -1;
            list = list.sort((a, b) => {
                let av = a[this.sortField] ?? '';
                let bv = b[this.sortField] ?? '';
                if (typeof av === 'string') av = av.toLowerCase();
                if (typeof bv === 'string') bv = bv.toLowerCase();
                return av < bv ? -dir : av > bv ? dir : 0;
            });
        }

        return list.map((l, i) => ({
            ...l,
            rowNum:               i + 1,
            ratingClass:          this._ratingClass(l.rating),
            sumaAseguradaFmt:     l.sumaAsegurada != null ? '$' + Number(l.sumaAsegurada).toLocaleString('es-MX') : null,
            isEditingStatus:      this.inlineId === l.id && this.inlineField === 'status',
            isEditingSeguro:      this.inlineId === l.id && this.inlineField === 'tipoSeguro',
            isEditingSource:      this.inlineId === l.id && this.inlineField === 'leadSource',
            isEditingMonto:       this.inlineId === l.id && this.inlineField === 'monto',
            isEditingRating:      this.inlineId === l.id && this.inlineField === 'rating',
            isEditingSumaAseg:    this.inlineId === l.id && this.inlineField === 'sumaAsegurada',
        }));
    }

    get hasLeads()   { return this.filteredLeads.length > 0; }
    get totalLabel() { return this.filteredLeads.length + ' prospectos'; }

    /* ── Grid headers ── */
    get gridHeaders() {
        const sf = this.sortField;
        const sd = this.sortDir;
        const s = (field, label) => ({
            key: field, field, label, sortable: true,
            cellClass: 'vl-grid-cell vl-hdr-sort' + (sf === field ? ' vl-sorted' : ''),
            icon: sf === field ? (sd === 'asc' ? '↑' : '↓') : '⇅',
        });
        const n = (key, label) => ({
            key, field: '', label, sortable: false,
            cellClass: 'vl-grid-cell',
            icon: '',
        });
        return [
            n('edit',          ''),
            s('name',          'Nombre'),
            n('contacto',      'Contacto'),
            s('tipoSeguro',    'Tipo seguro ✎'),
            s('monto',         'Monto ✎'),
            s('rating',        'Rating ✎'),
            s('sumaAsegurada', 'Suma aseg. ✎'),
            s('score',         'Score IA'),
            s('status',        'Estatus ✎'),
            s('leadSource',    'Origen ✎'),
            s('vendedor',      'Vendedor'),
            s('createdDate',   'Fecha'),
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

    /* ── Inline edit options ── */
    get statusOptions()  { return STATUSES.map(s => ({ key: s, value: s, label: s })); }
    get seguroOptions()  { return TIPOS_SEGURO.map(s => ({ key: s, value: s, label: s })); }
    get sourceOptions()  { return LEAD_SOURCES.map(s => ({ key: s, value: s, label: s })); }
    get ratingOptions()  { return [{ key: 'Hot', value: 'Hot', label: '🔥 Hot' }, { key: 'Warm', value: 'Warm', label: '🌡 Warm' }, { key: 'Cold', value: 'Cold', label: '❄ Cold' }]; }

    /* ── Inline open ── */
    handleInlineOpen(e) {
        e.stopPropagation();
        const id    = e.currentTarget.dataset.id;
        const field = e.currentTarget.dataset.field;
        const val   = e.currentTarget.dataset.val || '';
        if (this.inlineId === id && this.inlineField === field) {
            this._clearInline();
            return;
        }
        this.inlineId    = id;
        this.inlineField = field;
        this.inlineVal   = val;
    }

    handleInlineSelectChange(e) {
        e.stopPropagation();
        const val = e.target.value;
        this._commitInline(val);
    }

    handleInlineInputChange(e) { this.inlineVal = e.target.value; }

    handleInlineInputKey(e) {
        e.stopPropagation();
        if (e.key === 'Enter')  { this._commitInline(e.target.value); }
        if (e.key === 'Escape') { this._clearInline(); }
    }

    handleInlineInputBlur(e) {
        if (this.inlineId) this._commitInline(e.target.value);
    }

    handleInlineCancel(e) { e.stopPropagation(); this._clearInline(); }
    handleSelectClick(e)  { e.stopPropagation(); }

    _commitInline(rawVal) {
        const id    = this.inlineId;
        const field = this.inlineField;
        if (!id || !field) return;

        const def = FIELD_API[field];
        if (!def) { this._clearInline(); return; }

        const val = def.isNum ? (parseFloat(rawVal) || 0) : rawVal;

        this._leads = this._leads.map(l => {
            if (l.id !== id) return l;
            const patch = { [field]: val };
            if (field === 'status')        patch.statusClass      = this._statusClass(val);
            if (field === 'monto')         patch.montoFmt         = val ? '$' + Number(val).toLocaleString('es-MX') : null;
            if (field === 'sumaAsegurada') patch.sumaAseguradaFmt = val ? '$' + Number(val).toLocaleString('es-MX') : null;
            return { ...l, ...patch };
        });
        this._clearInline();

        actualizarLead({ lead: { sobjectType: 'Lead', Id: id, [def.api]: val || null } })
            .catch(() => { this._load(); });
    }

    _clearInline() { this.inlineId = null; this.inlineField = null; this.inlineVal = ''; }

    _ratingClass(r) {
        if (r === 'Hot')  return 'vl-rating-hot';
        if (r === 'Warm') return 'vl-rating-warm';
        if (r === 'Cold') return 'vl-rating-cold';
        return '';
    }

    _statusClass(s) {
        if (!s) return 'vt-badge-gray';
        if (s === 'Calificado')           return 'vt-badge-green';
        if (s === 'No Calificado')        return 'vt-badge-red';
        if (s === 'Transferido a agente') return 'vt-badge-orange';
        if (s === 'Precalificado')        return 'vt-badge-blue';
        return 'vt-badge-gray';
    }

    /* ── Kanban ── */
    get kanbanColumns() {
        const leads = this.filteredLeads;
        return KANBAN_COLS.map(col => ({
            ...col,
            colClass: 'vk-col' + (this.dragOverCol === col.key ? ' vk-col-over' : ''),
            leads:    leads.filter(l => l.status === col.key),
            count:    leads.filter(l => l.status === col.key).length,
        }));
    }

    handleDragStart(e) {
        this._draggedId = e.currentTarget.dataset.id;
        e.dataTransfer.effectAllowed = 'move';
    }
    handleDragEnd()    { this._draggedId = null; this.dragOverCol = null; }
    handleDragOver(e)  { e.preventDefault(); const s = e.currentTarget.dataset.status; if (this.dragOverCol !== s) this.dragOverCol = s; }

    handleDrop(e) {
        e.preventDefault();
        const targetStatus = e.currentTarget.dataset.status;
        this.dragOverCol   = null;
        const id = this._draggedId;
        this._draggedId = null;
        if (!id || !targetStatus) return;
        const lead = this._leads.find(l => l.id === id);
        if (!lead || lead.status === targetStatus) return;

        this._leads = this._leads.map(l =>
            l.id === id ? { ...l, status: targetStatus, statusClass: this._statusClass(targetStatus) } : l
        );
        actualizarLead({ lead: { sobjectType: 'Lead', Id: id, Status: targetStatus } })
            .catch(() => { this._load(); });
    }

    handleKanbanEdit(e) {
        e.stopPropagation();
        const id = e.currentTarget.dataset.id;
        const lead = this._leads.find(l => l.id === id);
        if (lead) this.dispatchEvent(new CustomEvent('leadeditropen', { detail: lead, bubbles: true, composed: true }));
    }

    /* ── Row / Detail ── */
    handleRowClick(e) {
        if (this.inlineId) { this._clearInline(); return; }
        const id   = e.currentTarget.dataset.id;
        const lead = this._leads.find(l => l.id === id);
        if (lead) {
            this.selectedLead          = lead;
            this.editScore             = lead.score ?? 0;
            this.showPrecalModal       = false;
            this.panelPrecalificaciones = [];
            this._loadPrecal(lead.id);
        }
    }

    _loadPrecal(leadId) {
        getPrecalificacionesByProspecto({ prospectoId: leadId })
            .then(data => {
                this.panelPrecalificaciones = (data || []).map(p => ({
                    ...p,
                    fechaFmt:      p.fechaEstadosFinancieros || '—',
                    capitalFmt:    p.capitalContable     != null ? '$' + Number(p.capitalContable).toLocaleString('es-MX', {maximumFractionDigits:0}) : '—',
                    ventasFmt:     p.ventasNetas         != null ? '$' + Number(p.ventasNetas).toLocaleString('es-MX', {maximumFractionDigits:0}) : '—',
                    lineaFmt:              p.lineaAfianzamiento    != null ? '$' + Number(p.lineaAfianzamiento).toLocaleString('es-MX', {maximumFractionDigits:0}) : '—',
                    importeTotalContratoFmt: p.importeTotalContrato != null ? '$' + Number(p.importeTotalContrato).toLocaleString('es-MX', {maximumFractionDigits:0}) : '—',
                    liquidezLabel: p.liquidez            != null ? Number(p.liquidez).toFixed(2) : '—',
                    apalancLabel:  p.apalancamiento      != null ? Number(p.apalancamiento).toFixed(2) : '—',
                    estadoLabel:   p.estadoAutomatico || p.estado || '—',
                    capacidadLabel: p.capacidadAfianzamiento || '—',
                }));
            })
            .catch(() => { this.panelPrecalificaciones = []; });
    }

    get hasPanelPrecal() { return this.panelPrecalificaciones.length > 0; }

    handleAddPrecal()          { this.editingPrecalId = null; this.showPrecalModal = true; }
    handleEditPrecal(e)        { e.stopPropagation(); this.editingPrecalId = e.currentTarget.dataset.id; this.showPrecalModal = true; }
    handlePrecalModalClose()   { this.showPrecalModal = false; this.editingPrecalId = null; }
    handlePrecalModalSuccess() { this.showPrecalModal = false; this.editingPrecalId = null; this._loadPrecal(this.selectedLead.id); }

    handleCloseDetail() {
        this.selectedLead          = null;
        this.showPrecalModal       = false;
        this.panelPrecalificaciones = [];
    }
    handleScoreSlider(e) { this.editScore = parseInt(e.target.value, 10); }

    handleSaveScore() {
        if (!this.selectedLead) return;
        this.isSavingScore = true;
        actualizarScoreLead({ leadId: this.selectedLead.id, score: this.editScore })
            .then(() => {
                this.isSavingScore = false;
                const s     = this.editScore;
                const color = s >= 71 ? '#16a34a' : s >= 41 ? '#d97706' : '#dc2626';
                const cls   = s >= 71 ? 'vl-score-green' : s >= 41 ? 'vl-score-orange' : 'vl-score-red';
                const patch = { score: s, scoreLabel: String(s), scoreClass: cls, scoreBarStyle: `width:${s}%;background:${color}` };
                this.selectedLead = { ...this.selectedLead, ...patch };
                this._leads = this._leads.map(l =>
                    l.id === this.selectedLead.id ? { ...l, ...patch } : l
                );
            })
            .catch(() => { this.isSavingScore = false; });
    }

    get scoreSaveLabel() { return this.isSavingScore ? 'Guardando...' : 'Guardar'; }

    handleSearch(e)   { this.searchTerm = e.target.value; }
    handleNuevoLead() { this.dispatchEvent(new CustomEvent('nuevolead')); }

    handleRowEditBtn(e) {
        e.stopPropagation();
        const id   = e.currentTarget.dataset.id;
        const lead = this._leads.find(l => l.id === id);
        if (lead) this.dispatchEvent(new CustomEvent('leadeditropen', { detail: lead, bubbles: true, composed: true }));
    }

    handleEditLead() {
        this.dispatchEvent(new CustomEvent('leadeditropen', { detail: this.selectedLead, bubbles: true, composed: true }));
        this.selectedLead = null;
    }

    handleConvertirLead() {
        this.dispatchEvent(new CustomEvent('convertirleadaopp', { detail: this.selectedLead, bubbles: true, composed: true }));
        this.selectedLead = null;
    }

    /* ── Filtros server-side ── */

    get filterBtnClass() {
        const active = this.filterRules.some(r => r.value && String(r.value).trim());
        return 'vl-btn-filters' + (active ? ' vl-btn-filters-active' : '') + (this.showFilters ? ' vl-btn-filters-open' : '');
    }

    get filterBtnLabel() {
        const count = this.filterRules.filter(r => r.value && String(r.value).trim()).length;
        return count > 0 ? `Filtros (${count})` : 'Filtros';
    }

    get hasFilterRules()  { return this.filterRules.length > 0; }
    get applyBtnLabel()   { return this.isApplying ? 'Aplicando...' : 'Aplicar filtros'; }

    get filterRulesView() {
        return this.filterRules.map(r => {
            const def = FILTER_FIELD_DEFS.find(f => f.value === r.field) || FILTER_FIELD_DEFS[0];
            const ops = getOpsForType(def.type);
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
        getLeads({ filtersJson })
            .then(data => { this._leads = (data || []).map(l => ({ ...l })); this.isApplying = false; })
            .catch(() => { this.isApplying = false; });
    }

    @api refresh() { this._load(); }
}
