import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContratistaList from '@salesforce/apex/TechContratistaController.getContratistaList';
import getPrecalificaciones from '@salesforce/apex/TechPrecalificacionController.getPrecalificacionesByContratista';

const CHIPS_MAX = 3;

const GRID_HEADERS = [
    { key: 'num',     field: '',        label: '#',                 sortable: false },
    { key: 'name',    field: 'name',    label: 'Nombre',            sortable: true  },
    { key: 'rfc',     field: 'rfc',     label: 'RFC',               sortable: true  },
    { key: 'cliente', field: 'cliente', label: 'Ciudad',            sortable: true  },
    { key: 'fianzas', field: '',        label: 'Fianza(s)',         sortable: false },
    { key: 'contratos', field: '',      label: 'Contrato(s)',       sortable: false },
    { key: 'precal',  field: '',        label: 'Precalificaciones', sortable: false },
    { key: 'estatus', field: 'estatus', label: 'Estado',            sortable: true  },
];

const ESTATUS_CLASS = {
    'Activo':     'vct-badge vct-badge-green',
    'Activa':     'vct-badge vct-badge-green',
    'Inactivo':   'vct-badge vct-badge-gray',
    'Pendiente':  'vct-badge vct-badge-orange',
    'Cancelado':  'vct-badge vct-badge-red',
    'Cancelada':  'vct-badge vct-badge-red',
};

const TEXT_OPS = [
    { v: 'contains', l: 'contiene' },
    { v: 'eq',       l: 'es igual a' },
    { v: 'ne',       l: 'no es igual a' },
];
const EQ_OPS = [
    { v: 'eq', l: 'es igual a' },
    { v: 'ne', l: 'es diferente a' },
];

const FILTER_FIELD_DEFS = [
    { value: 'name',    label: 'Nombre',  type: 'text' },
    { value: 'rfc',     label: 'RFC',     type: 'text' },
    { value: 'cliente', label: 'Ciudad',  type: 'text' },
    { value: 'estatus', label: 'Estatus', type: 'picklist', options: ['Activo','Activa','Inactivo','Pendiente','Cancelado','Cancelada'] },
];

function getOpsForType(type) { return type === 'text' ? TEXT_OPS : EQ_OPS; }

function matchRules(item, rules) {
    return rules.every(r => {
        if (!r.value && r.value !== 0) return true;
        const iv = String(item[r.field] || '').toLowerCase();
        const v  = String(r.value).toLowerCase().trim();
        if (r.op === 'contains') return iv.includes(v);
        if (r.op === 'eq')       return iv === v;
        if (r.op === 'ne')       return iv !== v;
        return true;
    });
}

export default class TechVentasContratistas extends LightningElement {

    @track isLoading   = true;
    @track hasError    = false;
    @track errorMsg    = '';
    @track isModalOpen = false;
    @track searchTerm  = '';

    @track sortField          = 'name';
    @track sortDir            = 'asc';

    @track showFilters        = false;
    @track filterRules        = [];
    _filterRuleCounter        = 0;

    @track isInterfacesOpen   = false;
    @track interfacesId       = null;
    @track interfacesName     = '';

    @track selectedContratista    = null;
    @track isEditingPanel         = false;
    @track isSavingEdit           = false;
    @track panelPrecalificaciones = [];
    @track isLoadingPrecal        = false;
    @track showPrecalModal         = false;
    @track editingPrecalId         = null;
    @track showPdfModal            = false;
    @track pdfModalUrl             = '';
    @track pdfModalTitle           = '';

    _wiredResult;
    _originalData = [];

    @wire(getContratistaList)
    wiredData(result) {
        this._wiredResult = result;
        const { data, error } = result;
        if (data) {
            this._originalData = data;
            this.hasError = false;
        } else if (error) {
            this.hasError = true;
            this.errorMsg = error?.body?.message || 'Error al cargar contratistas';
            this._originalData = [];
        }
        this.isLoading = false;
    }

    get _filtered() {
        const term = this.searchTerm.toLowerCase();
        let result = term
            ? this._originalData.filter(r =>
                (r.name    && r.name.toLowerCase().includes(term))    ||
                (r.rfc     && r.rfc.toLowerCase().includes(term))     ||
                (r.cliente && r.cliente.toLowerCase().includes(term))
              )
            : this._originalData;
        const active = this.filterRules.filter(r => r.value && String(r.value).trim());
        if (active.length) result = result.filter(item => matchRules(item, active));
        return result;
    }

    get _sorted() {
        const data = [...this._filtered];
        if (!this.sortField) return data;
        const dir = this.sortDir === 'asc' ? 1 : -1;
        const f   = this.sortField;
        return data.sort((a, b) => String(a[f] ?? '').localeCompare(String(b[f] ?? '')) * dir);
    }

    get rows() {
        return this._sorted.map((r, idx) => {
            const fianzas   = r.fianzas   || [];
            const contratos = r.contratos || [];
            const precal    = r.precalificaciones || [];
            return {
                id:             r.id,
                rowNum:         idx + 1,
                name:           r.name   || '—',
                rfc:            r.rfc    || '—',
                cliente:        r.cliente || '—',
                estatus:        r.estatus || 'Activo',
                estatusClass:   ESTATUS_CLASS[r.estatus] || 'vct-badge vct-badge-green',
                fianzasChips:   fianzas.slice(0, CHIPS_MAX),
                fianzasExtra:   fianzas.length > CHIPS_MAX ? fianzas.length - CHIPS_MAX : 0,
                contratosChips: contratos.slice(0, CHIPS_MAX),
                contratosExtra: contratos.length > CHIPS_MAX ? contratos.length - CHIPS_MAX : 0,
                precalChips:    precal.slice(0, 2),
                precalExtra:    precal.length > 2 ? precal.length - 2 : 0,
            };
        });
    }

    get showGrid()  { return !this.isLoading && !this.hasError && this._filtered.length > 0; }
    get isEmpty()   { return !this.isLoading && !this.hasError && this._filtered.length === 0; }

    get gridHeaders() {
        return GRID_HEADERS.map(h => ({
            ...h,
            cellClass: 'vct-grid-cell vct-grid-hdr' +
                       (h.sortable ? ' vct-hdr-sort' : '') +
                       (this.sortField === h.field && h.field ? ' vct-sorted' : ''),
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

    handleSearch(e) { this.searchTerm = e.target.value; }

    handleRowClick(e) {
        const id   = e.currentTarget.dataset.id;
        const item = this._originalData.find(r => r.id === id);
        if (item) {
            this.selectedContratista    = item;
            this.isEditingPanel         = false;
            this.panelPrecalificaciones = [];
            this._loadPrecal(id);
        }
    }

    _loadPrecal(contratistaId) {
        this.isLoadingPrecal = true;
        getPrecalificaciones({ contratistaId })
            .then(data => {
                this.panelPrecalificaciones = (data || []).map(p => ({
                    ...p,
                    fechaFmt:      p.fechaEstadosFinancieros || '—',
                    lineaFmt:      p.lineaAfianzamiento    != null ? '$' + Number(p.lineaAfianzamiento).toLocaleString('es-MX', {maximumFractionDigits:0}) : '—',
                    capitalFmt:    p.capitalContable        != null ? '$' + Number(p.capitalContable).toLocaleString('es-MX', {maximumFractionDigits:0}) : '—',
                    ventasFmt:     p.ventasNetas            != null ? '$' + Number(p.ventasNetas).toLocaleString('es-MX', {maximumFractionDigits:0}) : '—',
                    scoreLabel:    p.scoreICP               != null ? String(Number(p.scoreICP).toFixed(1)) : '—',
                    liquidezLabel: p.liquidez               != null ? String(Number(p.liquidez).toFixed(2)) : '—',
                    estadoLabel:   p.estadoAutomatico || p.estado || '—',
                    badgeClass:    this._precalBadge(p.estatusClass),
                }));
            })
            .catch(() => { this.panelPrecalificaciones = []; })
            .finally(() => { this.isLoadingPrecal = false; });
    }

    _precalBadge(cls) {
        if (cls === 'airtable-badge-green')  return 'vct-badge vct-badge-green';
        if (cls === 'airtable-badge-orange') return 'vct-badge vct-badge-orange';
        if (cls === 'airtable-badge-red')    return 'vct-badge vct-badge-red';
        return 'vct-badge vct-badge-gray';
    }

    /* ── Panel relation getters ── */
    get panelFianzasData() {
        const map = { 'airtable-badge-green':'vct-badge vct-badge-green', 'airtable-badge-orange':'vct-badge vct-badge-orange', 'airtable-badge-gray':'vct-badge vct-badge-gray', 'airtable-badge-red':'vct-badge vct-badge-red' };
        return (this.selectedContratista?.fianzasData || []).map(f => ({
            ...f, badgeClass: map[f.estatusClass] || 'vct-badge vct-badge-gray'
        }));
    }
    get hasPanelFianzas()  { return (this.selectedContratista?.fianzasData || []).length > 0; }

    get panelContratosData() {
        const map = { 'airtable-badge-green':'vct-badge vct-badge-green', 'airtable-badge-orange':'vct-badge vct-badge-orange', 'airtable-badge-gray':'vct-badge vct-badge-gray' };
        return (this.selectedContratista?.contratosData || []).map(c => ({
            ...c, badgeClass: map[c.estatusClass] || 'vct-badge vct-badge-gray'
        }));
    }
    get hasPanelContratos()       { return (this.selectedContratista?.contratosData || []).length > 0; }
    get hasPanelPrecalificaciones(){ return this.panelPrecalificaciones.length > 0; }

    handleOpenInterfaces(e) {
        e.stopPropagation();
        const id   = e.currentTarget.dataset.id;
        const name = e.currentTarget.dataset.name;
        this.interfacesId     = id;
        this.interfacesName   = name || '';
        this.isInterfacesOpen = true;
    }

    handleCloseInterfaces() {
        this.isInterfacesOpen = false;
        this.interfacesId     = null;
        this.interfacesName   = '';
    }

    handleClosePanel()     { this.selectedContratista = null; this.isEditingPanel = false; this.panelPrecalificaciones = []; this.showPrecalModal = false; }
    handleEditPanel()      { this.isEditingPanel = true; }
    handleCancelEdit()     { this.isEditingPanel = false; }

    handleAddPrecal()          { this.editingPrecalId = null; this.showPrecalModal = true; }
    handleEditPrecal(e)        { e.stopPropagation(); this.editingPrecalId = e.currentTarget.dataset.id; this.showPrecalModal = true; }
    handleViewPdf(e) {
        e.stopPropagation();
        const id = e.currentTarget.dataset.id;
        if (!id) return;
        const p = this.panelPrecalificaciones.find(x => x.id === id);
        this.pdfModalTitle = p ? p.name : 'Precalificación';
        this.pdfModalUrl   = `/apex/PrecalificacionPDF?id=${id}#navpanes=0&toolbar=1`;
        this.showPdfModal  = true;
    }
    handleClosePdfModal() { this.showPdfModal = false; this.pdfModalUrl = ''; this.pdfModalTitle = ''; }
    handlePrecalModalClose()   { this.showPrecalModal = false; this.editingPrecalId = null; }
    handlePrecalModalSuccess() { this.showPrecalModal = false; this.editingPrecalId = null; this._loadPrecal(this.selectedContratista.id); }

    handlePanelSaveSuccess() {
        this.isEditingPanel = false;
        this.dispatchEvent(new ShowToastEvent({ title: 'Guardado', message: 'Contratista actualizado', variant: 'success' }));
        const prevId = this.selectedContratista?.id;
        refreshApex(this._wiredResult).then(() => {
            if (prevId) {
                const updated = this._originalData.find(r => r.id === prevId);
                if (updated) this.selectedContratista = updated;
            }
        });
    }

    /* ── Filtros ── */
    get filterBtnClass() {
        const active = this.filterRules.some(r => r.value && String(r.value).trim());
        return 'vct-btn-filters' + (active ? ' vct-btn-filters-active' : '') + (this.showFilters ? ' vct-btn-filters-open' : '');
    }
    get filterBtnLabel() {
        const count = this.filterRules.filter(r => r.value && String(r.value).trim()).length;
        return count > 0 ? `Filtros (${count})` : 'Filtros';
    }
    get hasFilterRules() { return this.filterRules.length > 0; }
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
                isText:         def.type === 'text',
                isPicklist:     def.type === 'picklist',
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
        this.filterRules = [...this.filterRules, { id: ++this._filterRuleCounter, field: def.value, op: ops[0].v, value: '' }];
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
        this.filterRules = this.filterRules.map(r => r.id === id ? { ...r, field, op: ops[0].v, value: '' } : r);
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
    handleClearFilters() { this.filterRules = []; }

    handleNuevo()       { this.isModalOpen = true; }
    handleModalClose()  { this.isModalOpen = false; }
    handleModalSuccess() {
        this.isModalOpen = false;
        this.isLoading   = true;
        refreshApex(this._wiredResult).then(() => { this.isLoading = false; });
        this.dispatchEvent(new ShowToastEvent({ title: 'Creado', message: 'Contratista creado exitosamente', variant: 'success' }));
    }
}
