import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRecibosList from '@salesforce/apex/TechReciboCobroController.getRecibosList';
import FECHA_PROGRAMADA_FIELD from '@salesforce/schema/Tech_Recibo_Pago__c.Fecha_programada__c';

const ALL_COLUMNS = [
    { field: 'plan',               label: 'Plan de Pago',     icon: 'utility:list',        isPlan:   true, minWidthStyle: 'min-width:160px', sortable: true },
    { field: 'estatus',            label: 'Estado',           icon: 'utility:record',      isEstatus: true, minWidthStyle: 'min-width:120px', sortable: true },
    { field: 'montoProgramadoFmt', label: 'Monto Programado', icon: 'utility:money',       isMonto:   true, minWidthStyle: 'min-width:140px', sortable: false },
    { field: 'montoCobradoFmt',    label: 'Monto Cobrado',    icon: 'utility:money',       isMontoCob: true, minWidthStyle: 'min-width:130px', sortable: false },
    { field: 'fechaProgramada',    label: 'Fecha Programada', icon: 'utility:event',       isFechaProg: true, minWidthStyle: 'min-width:140px', sortable: true },
    { field: 'fechaPago',          label: 'Fecha de Pago',    icon: 'utility:event',       isFechaPago: true, minWidthStyle: 'min-width:130px', sortable: true },
    { field: 'metodoPago',         label: 'Método de Pago',   icon: 'utility:credit_card', isMetodo:   true, minWidthStyle: 'min-width:140px', sortable: true },
    { field: 'saldoFmt',           label: 'Saldo',            icon: 'utility:money',       isSaldo:    true, minWidthStyle: 'min-width:110px', sortable: false },
];
const DEFAULT_VISIBLE = ['plan', 'estatus', 'montoProgramadoFmt', 'fechaProgramada'];
const SF_FIELD_MAP    = { name: 'Name', fechaProgramada: 'Fecha_programada__c' };

export default class TechReciboCobro extends LightningElement {
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

    @wire(getRecibosList)
    wiredData(result) {
        this.wiredResult = result;
        this.isLoading = true;
        const { data, error } = result;
        if (data)  { this.originalData = data; this.filterData(); }
        else if (error) { this.originalData = []; this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: error.body?.message, variant: 'error' })); }
        this.isLoading = false;
    }

    connectedCallback() { this.visibleColumns = ALL_COLUMNS.filter(c => DEFAULT_VISIBLE.includes(c.field)); }

    get isGridView()    { return this.currentView === 'grid'; }
    get isGalleryView() { return this.currentView === 'gallery'; }
    get isKanbanView()  { return this.currentView === 'kanban'; }
    get gridTabClass()    { return `at-view-tab${this.currentView === 'grid'    ? ' at-view-tab-active' : ''}`; }
    get galleryTabClass() { return `at-view-tab${this.currentView === 'gallery' ? ' at-view-tab-active' : ''}`; }
    get kanbanTabClass()  { return `at-view-tab${this.currentView === 'kanban'  ? ' at-view-tab-active' : ''}`; }

    handleViewChange(event) {
        this.currentView = event.currentTarget.dataset.view;
        this.showColumnPicker = false;
        if (this.currentView === 'kanban') this._buildKanban();
    }

    _buildKanban() {
        const map = {};
        this.filteredData.forEach(r => { const s = r.estatus || 'Sin Estado'; if (!map[s]) map[s] = []; map[s].push(r); });
        this.kanbanColumns = Object.keys(map).map(s => ({ status: s, items: map[s], count: map[s].length, badgeClass: 'at-badge at-badge-gray' }));
    }

    handleSearch(event) { this.searchTerm = event.target.value.toLowerCase(); this.filterData(); }

    filterData() {
        const term = this.searchTerm;
        let result = term
            ? this.originalData.filter(r => (r.name && r.name.toLowerCase().includes(term)) || (r.plan && r.plan.toLowerCase().includes(term)))
            : [...this.originalData];
        result.sort((a, b) => {
            let va = a[this.sortField]; let vb = b[this.sortField];
            if (va == null) va = ''; if (vb == null) vb = '';
            const cmp = (typeof va === 'number' && typeof vb === 'number') ? va - vb : String(va).localeCompare(String(vb), 'es', { numeric: true });
            return this.sortDir === 'asc' ? cmp : -cmp;
        });
        const ec = this.editingCell;
        this.filteredData = result.map((r, idx) => ({
            ...r, rowNumber: idx + 1,
            hasPlan:       !!r.plan,
            isEditingName:      ec?.rowId === r.id && ec?.field === 'name',
            isEditingFechaProg: ec?.rowId === r.id && ec?.field === 'fechaProgramada',
        }));
        if (this.isKanbanView) this._buildKanban();
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
        this.filterData();
        if (field === 'fechaProgramada') {
            const fields = { Id: rowId, [FECHA_PROGRAMADA_FIELD.fieldApiName]: value || null };
            updateRecord({ fields })
                .then(() => refreshApex(this.wiredResult))
                .catch(err => this.dispatchEvent(new ShowToastEvent({ title: 'Error al guardar', message: err.body?.message || 'Error desconocido', variant: 'error' })));
        }
    }

    handleExpandRow(event) { event.stopPropagation(); this._openDetail(event.currentTarget.dataset.id); }
    _openDetail(id)        { this.selectedItem = this.filteredData.find(r => r.id === id) || null; this.isDetailPanelOpen = !!this.selectedItem; }
    handleCloseDetailPanel() { this.isDetailPanelOpen = false; this.selectedItem = null; this.isEditingPanel = false; }

    get currentDetailIndex() { return this.filteredData.findIndex(r => r.id === this.selectedItem?.id); }
    get isFirstRecord()      { return this.currentDetailIndex <= 0; }
    get isLastRecord()       { return this.currentDetailIndex >= this.filteredData.length - 1; }
    handlePrevRecord() { const i = this.currentDetailIndex; if (i > 0) { this.selectedItem = { ...this.filteredData[i - 1] }; this.isEditingPanel = false; } }
    handleNextRecord() { const i = this.currentDetailIndex; if (i < this.filteredData.length - 1) { this.selectedItem = { ...this.filteredData[i + 1] }; this.isEditingPanel = false; } }

    handleEditFromPanel()    { this.isEditingPanel = true; }
    handlePanelCancel()      { this.isEditingPanel = false; }
    handlePanelSaveSuccess() {
        this.isEditingPanel = false;
        refreshApex(this.wiredResult).then(() => {
            const updated = this.filteredData.find(r => r.id === this.selectedItem?.id);
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
        this.filterData();
    }
    get nameSortArrow() { return this._sortArrow('name'); }
    _sortArrow(field)   { return this.sortField === field ? (this.sortDir === 'asc' ? ' ▲' : ' ▼') : ''; }
    get visibleColumnsWithSort() {
        return this.visibleColumns.map(col => ({
            ...col,
            thClass:   `at-th${col.sortable ? ' at-th-sortable' : ''}`,
            sortArrow: col.sortable ? this._sortArrow(col.field) : '',
        }));
    }
}