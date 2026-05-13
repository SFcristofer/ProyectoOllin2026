import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContratosList from '@salesforce/apex/TechContratoController.getContratosList';

const ALL_COLUMNS = [
    { field: 'contratista',  label: 'Contratista',     icon: 'utility:user',        isContratista:  true, minWidthStyle: 'min-width:160px', sortable: true },
    { field: 'proyecto',     label: 'Proyecto',        icon: 'utility:work_order',  isProyecto:     true, minWidthStyle: 'min-width:160px', sortable: true },
    { field: 'beneficiario', label: 'Beneficiario',    icon: 'utility:people',      isBeneficiario: true, minWidthStyle: 'min-width:160px', sortable: true },
    { field: 'institucion',  label: 'Institución',     icon: 'utility:company',     isInstitucion:  true, minWidthStyle: 'min-width:150px', sortable: true },
    { field: 'monto',        label: 'Suma Fianzas',    icon: 'utility:currency',    isMonto:        true, minWidthStyle: 'min-width:140px', sortable: true },
    { field: 'valorVigente', label: 'Valor Vigente',   icon: 'utility:currency',    isValorVigente: true, minWidthStyle: 'min-width:140px', sortable: true },
    { field: 'exposicion',   label: 'Exposición %',    icon: 'utility:percent',     isExposicion:   true, minWidthStyle: 'min-width:120px', sortable: true },
    { field: 'fechaInicio',  label: 'Fecha Inicio',    icon: 'utility:event',       isFechaInicio:  true, minWidthStyle: 'min-width:130px', sortable: true },
    { field: 'fechaFin',     label: 'Fecha Fin',       icon: 'utility:event',       isFechaFin:     true, minWidthStyle: 'min-width:130px', sortable: true },
    { field: 'estatus',      label: 'Estado',          icon: 'utility:record',      isEstatus:      true, minWidthStyle: 'min-width:120px', sortable: true },
];
const DEFAULT_VISIBLE = ['contratista', 'beneficiario', 'proyecto', 'monto', 'valorVigente', 'estatus'];
const SF_FIELD_MAP    = { monto: 'Suma_Fianzas__c' };

export default class TechContratos extends LightningElement {
    @track filteredData      = [];
    @track originalData      = [];
    @track visibleColumns    = [];
    @track kanbanColumns     = [];
    @track isDetailPanelOpen = false;
    @track isEditingPanel    = false;
    @track selectedItem      = null;
    @track showColumnPicker  = false;

    currentView = 'grid'; searchTerm = ''; isLoading = true;
    isCreateModalOpen = false; editingCell = null; wiredResult;
    sortField = 'name'; sortDir = 'asc';

    @track currentPage = 1;
    pageSize = 50;

    @wire(getContratosList)
    wiredData(result) {
        this.wiredResult = result;
        this.isLoading = true;
        const { data, error } = result;
        if (data) { this.originalData = data; this.filterData(); }
        else if (error) { this.originalData = []; this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: error.body?.message, variant: 'error' })); }
        this.isLoading = false;
    }

    connectedCallback() { this.visibleColumns = ALL_COLUMNS.filter(c => DEFAULT_VISIBLE.includes(c.field)); }

    get isGridView()     { return this.currentView === 'grid'; }
    get isGalleryView()  { return this.currentView === 'gallery'; }
    get isKanbanView()   { return this.currentView === 'kanban'; }
    get isCalendarView() { return this.currentView === 'calendar'; }
    get gridTabClass()     { return `at-view-tab${this.currentView === 'grid'     ? ' at-view-tab-active' : ''}`; }
    get galleryTabClass()  { return `at-view-tab${this.currentView === 'gallery'  ? ' at-view-tab-active' : ''}`; }
    get kanbanTabClass()   { return `at-view-tab${this.currentView === 'kanban'   ? ' at-view-tab-active' : ''}`; }
    get calendarTabClass() { return `at-view-tab${this.currentView === 'calendar' ? ' at-view-tab-active' : ''}`; }

    handleViewChange(event) {
        this.currentView = event.currentTarget.dataset.view;
        this.showColumnPicker = false;
        if (this.currentView === 'kanban') this._buildKanban();
    }

    _buildKanban() {
        const map = {};
        this.filteredData.forEach(f => { const s = f.estatus || 'Sin Estado'; if (!map[s]) map[s] = []; map[s].push(f); });
        const badgeMap = { 'Activo': 'at-badge at-badge-green', 'Vigente': 'at-badge at-badge-green', 'Vencido': 'at-badge at-badge-red', 'En Proceso': 'at-badge at-badge-blue' };
        this.kanbanColumns = Object.keys(map).map(s => ({ status: s, items: map[s], count: map[s].length, badgeClass: badgeMap[s] || 'at-badge at-badge-gray' }));
    }

    handleSearch(event) { this.searchTerm = event.target.value.toLowerCase(); this.currentPage = 1; this.filterData(); }

    filterData() {
        const term = this.searchTerm;
        let result = term
            ? this.originalData.filter(f => (f.name && f.name.toLowerCase().includes(term)) || (f.contratista && f.contratista.toLowerCase().includes(term)))
            : [...this.originalData];
        result.sort((a, b) => {
            let va = a[this.sortField]; let vb = b[this.sortField];
            if (va == null) va = ''; if (vb == null) vb = '';
            const cmp = (typeof va === 'number' && typeof vb === 'number') ? va - vb : String(va).localeCompare(String(vb), 'es', { numeric: true });
            return this.sortDir === 'asc' ? cmp : -cmp;
        });
        const ec = this.editingCell;
        this.filteredData = result.map((f, idx) => ({
            ...f, rowNumber: idx + 1,
            estatusClass:      this._estatusCls(f.estatus),
            montoFormatted:    f.monto        != null ? `$${Number(f.monto).toLocaleString('es-MX', { minimumFractionDigits: 2 })}` : '—',
            exposicionDisplay: f.exposicion   != null ? Number(f.exposicion).toFixed(1) + '%' : '—',
            isEditingName:     ec?.rowId === f.id && ec?.field === 'name',
        }));
        if (this.isKanbanView) this._buildKanban();
    }

    _estatusCls(s) {
        if (s === 'Activo' || s === 'Activa' || s === 'Vigente') return 'at-badge at-badge-green';
        if (s === 'Pendiente')                                    return 'at-badge at-badge-orange';
        if (s === 'Cancelado' || s === 'Cancelada' || s === 'Vencido') return 'at-badge at-badge-red';
        if (s === 'En Proceso')                                   return 'at-badge at-badge-blue';
        if (s === 'Completado')                                   return 'at-badge at-badge-green';
        return 'at-badge at-badge-gray';
    }

    handleCellClick(event) {
        const td = event.currentTarget; const rowId = td.dataset.id; const field = td.dataset.field;
        if (!rowId || !field) return;
        if (!SF_FIELD_MAP[field]) { this._openDetail(rowId); return; }
        this.editingCell = { rowId, field }; this.filterData();
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        Promise.resolve().then(() => { const el = this.template.querySelector(`input[data-id="${rowId}"][data-field="${field}"]`); if (el) el.focus(); });
    }
    handleCellBlur(event)    { const el = event.currentTarget; this._commit(el.dataset.id, el.dataset.field, el.value); }
    handleCellKeydown(event) { if (event.key === 'Enter') event.currentTarget.blur(); else if (event.key === 'Escape') { this.editingCell = null; this.filterData(); } }

    _commit(rowId, field, value) {
        this.editingCell = null;
        const sfField = SF_FIELD_MAP[field];
        if (!sfField || !rowId) { this.filterData(); return; }
        updateRecord({ fields: { Id: rowId, [sfField]: value } })
            .then(() => { this.originalData = this.originalData.map(f => f.id === rowId ? { ...f, [field]: value } : f); this.filterData(); })
            .catch(err => { this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err.body?.message, variant: 'error' })); this.filterData(); });
    }

    handleExpandRow(event) { event.stopPropagation(); this._openDetail(event.currentTarget.dataset.id); }
    _openDetail(id)        { this.selectedItem = this.filteredData.find(f => f.id === id) || null; this.isDetailPanelOpen = !!this.selectedItem; }
    handleCloseDetailPanel(){ this.isDetailPanelOpen = false; this.selectedItem = null; this.isEditingPanel = false; }

    get currentDetailIndex() { return this.filteredData.findIndex(f => f.id === this.selectedItem?.id); }
    get isFirstRecord()      { return this.currentDetailIndex <= 0; }
    get isLastRecord()       { return this.currentDetailIndex >= this.filteredData.length - 1; }
    handlePrevRecord() { const i = this.currentDetailIndex; if (i > 0) { this.selectedItem = { ...this.filteredData[i - 1] }; this.isEditingPanel = false; } }
    handleNextRecord() { const i = this.currentDetailIndex; if (i < this.filteredData.length - 1) { this.selectedItem = { ...this.filteredData[i + 1] }; this.isEditingPanel = false; } }

    handleEditFromPanel()    { this.isEditingPanel = true; }
    handlePanelCancel()      { this.isEditingPanel = false; }
    handlePanelSaveSuccess() {
        this.isEditingPanel = false;
        refreshApex(this.wiredResult).then(() => {
            const updated = this.filteredData.find(f => f.id === this.selectedItem?.id);
            if (updated) this.selectedItem = { ...updated };
        });
        this.dispatchEvent(new ShowToastEvent({ title: 'Guardado', message: 'Registro actualizado.', variant: 'success' }));
    }

    get availableColumns()    { const s = new Set(this.visibleColumns.map(c => c.field)); return ALL_COLUMNS.filter(c => !s.has(c.field)); }
    get hasAvailableColumns() { return this.availableColumns.length > 0; }
    handleToggleColumnPicker(event) { event.stopPropagation(); this.showColumnPicker = !this.showColumnPicker; }
    stopPropagation(event)          { event.stopPropagation(); }
    handleSelectColumn(event)       { event.stopPropagation(); const col = ALL_COLUMNS.find(c => c.field === event.currentTarget.dataset.field); if (col) this.visibleColumns = [...this.visibleColumns, col]; this.showColumnPicker = false; }

    handleOpenCreateModal()  { this.isCreateModalOpen = true; }
    handleCloseCreateModal() { this.isCreateModalOpen = false; }
    handleCreateSuccess()    { this.isCreateModalOpen = false; return refreshApex(this.wiredResult); }

    handleSort(event) {
        const field = event.currentTarget.dataset.field;
        if (!field) return;
        if (this.sortField === field) { this.sortDir = this.sortDir === 'asc' ? 'desc' : 'asc'; }
        else { this.sortField = field; this.sortDir = 'asc'; }
        this.currentPage = 1;
        this.filterData();
    }
    get nameSortArrow()  { return this._sortArrow('name'); }
    _sortArrow(field)    { return this.sortField === field ? (this.sortDir === 'asc' ? ' ▲' : ' ▼') : ''; }
    get visibleColumnsWithSort() {
        return this.visibleColumns.map(col => ({
            ...col,
            thClass:   `at-th${col.sortable ? ' at-th-sortable' : ''}`,
            sortArrow: col.sortable ? this._sortArrow(col.field) : '',
        }));
    }

    // ─── Pagination ────────────────────────────────────────────
    get totalPages()    { return Math.max(1, Math.ceil(this.filteredData.length / this.pageSize)); }
    get isFirstPage()   { return this.currentPage <= 1; }
    get isLastPage()    { return this.currentPage >= this.totalPages; }
    get showPagination(){ return this.filteredData.length > this.pageSize; }
    get paginationLabel() {
        const total = this.filteredData.length;
        if (total === 0) return '0 registros';
        const start = (this.currentPage - 1) * this.pageSize + 1;
        const end   = Math.min(this.currentPage * this.pageSize, total);
        return `${start}–${end} de ${total}`;
    }
    get pagedData() {
        const start = (this.currentPage - 1) * this.pageSize;
        return this.filteredData.slice(start, start + this.pageSize);
    }
    handlePrevPage() { if (!this.isFirstPage) this.currentPage--; }
    handleNextPage() { if (!this.isLastPage)  this.currentPage++; }
}