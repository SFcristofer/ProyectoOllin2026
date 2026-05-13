import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getConveniosList from '@salesforce/apex/TechConvenioController.getConveniosList';

const ALL_COLUMNS = [
    { field: 'contrato',   label: 'Contrato',     icon: 'utility:contract',  isContrato:   true, minWidthStyle: 'min-width:150px', sortable: true  },
    { field: 'tipo',       label: 'Tipo',          icon: 'utility:record',    isTipo:       true, minWidthStyle: 'min-width:140px', sortable: true  },
    { field: 'fecha',      label: 'Fecha',         icon: 'utility:event',     isFecha:      true, minWidthStyle: 'min-width:130px', sortable: true  },
    { field: 'nuevoValor', label: 'Nuevo Valor',   icon: 'utility:currency',  isNuevoValor: true, minWidthStyle: 'min-width:140px', sortable: true  },
    { field: 'diferencia', label: 'Diferencia',    icon: 'utility:currency',  isDiferencia: true, minWidthStyle: 'min-width:140px', sortable: true  },
];
const DEFAULT_VISIBLE = ['contrato', 'tipo', 'fecha', 'nuevoValor'];

export default class TechConvenioModificatorio extends NavigationMixin(LightningElement) {
    @track filteredData      = [];
    @track originalData      = [];
    @track visibleColumns    = [];
    @track kanbanColumns     = [];
    @track isDetailPanelOpen = false;
    @track isEditingPanel    = false;
    @track selectedItem      = null;
    @track showColumnPicker  = false;

    currentView = 'grid'; searchTerm = ''; isLoading = true;
    isCreateModalOpen = false; wiredResult;
    sortField = 'name'; sortDir = 'asc';

    @wire(getConveniosList)
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
    get gridTabClass()   { return `at-view-tab${this.currentView === 'grid'    ? ' at-view-tab-active' : ''}`; }
    get galleryTabClass(){ return `at-view-tab${this.currentView === 'gallery' ? ' at-view-tab-active' : ''}`; }
    get kanbanTabClass() { return `at-view-tab${this.currentView === 'kanban'  ? ' at-view-tab-active' : ''}`; }

    handleViewChange(event) {
        this.currentView = event.currentTarget.dataset.view;
        this.showColumnPicker = false;
        if (this.currentView === 'kanban') this._buildKanban();
    }

    _buildKanban() {
        const map = {};
        this.filteredData.forEach(f => { const s = f.tipo || 'Sin Tipo'; if (!map[s]) map[s] = []; map[s].push(f); });
        this.kanbanColumns = Object.keys(map).map(s => ({ status: s, items: map[s], count: map[s].length, badgeClass: 'at-badge at-badge-gray' }));
    }

    handleSearch(event) { this.searchTerm = event.target.value.toLowerCase(); this.filterData(); }

    filterData() {
        const term = this.searchTerm;
        let result = term
            ? this.originalData.filter(f => (f.name && f.name.toLowerCase().includes(term)) || (f.contrato && f.contrato.toLowerCase().includes(term)) || (f.tipo && f.tipo.toLowerCase().includes(term)))
            : [...this.originalData];
        result.sort((a, b) => {
            let va = a[this.sortField]; let vb = b[this.sortField];
            if (va == null) va = ''; if (vb == null) vb = '';
            const cmp = (typeof va === 'number' && typeof vb === 'number') ? va - vb : String(va).localeCompare(String(vb), 'es', { numeric: true });
            return this.sortDir === 'asc' ? cmp : -cmp;
        });
        this.filteredData = result.map((f, idx) => ({
            ...f, rowNumber: idx + 1,
            nuevoValorFmt: f.nuevoValor != null ? `$${Number(f.nuevoValor).toLocaleString('es-MX', { minimumFractionDigits: 2 })}` : '—',
            diferenciaFmt: f.diferencia != null ? `$${Number(f.diferencia).toLocaleString('es-MX', { minimumFractionDigits: 2 })}` : '—',
        }));
        if (this.isKanbanView) this._buildKanban();
    }

    handleCellClick(event) { const rowId = event.currentTarget.dataset.id; if (rowId) this._openDetail(rowId); }
    handleExpandRow(event) { event.stopPropagation(); this._openDetail(event.currentTarget.dataset.id); }
    _openDetail(id)        { this.selectedItem = this.filteredData.find(f => f.id === id) || null; this.isDetailPanelOpen = !!this.selectedItem; this.isEditingPanel = false; }
    handleCloseDetailPanel(){ this.isDetailPanelOpen = false; this.selectedItem = null; this.isEditingPanel = false; }

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

    get currentDetailIndex() { return this.filteredData.findIndex(f => f.id === this.selectedItem?.id); }
    get isFirstRecord()      { return this.currentDetailIndex <= 0; }
    get isLastRecord()       { return this.currentDetailIndex >= this.filteredData.length - 1; }
    handlePrevRecord() { const i = this.currentDetailIndex; if (i > 0) { this.selectedItem = { ...this.filteredData[i - 1] }; this.isEditingPanel = false; } }
    handleNextRecord() { const i = this.currentDetailIndex; if (i < this.filteredData.length - 1) { this.selectedItem = { ...this.filteredData[i + 1] }; this.isEditingPanel = false; } }

    handleNew() { this.isCreateModalOpen = true; }
    handleCloseCreateModal() { this.isCreateModalOpen = false; }
    handleCreateSuccess()    { this.isCreateModalOpen = false; return refreshApex(this.wiredResult); }

    get availableColumns()    { const s = new Set(this.visibleColumns.map(c => c.field)); return ALL_COLUMNS.filter(c => !s.has(c.field)); }
    get hasAvailableColumns() { return this.availableColumns.length > 0; }
    handleToggleColumnPicker(event) { event.stopPropagation(); this.showColumnPicker = !this.showColumnPicker; }
    stopPropagation(event)          { event.stopPropagation(); }
    handleSelectColumn(event)       { event.stopPropagation(); const col = ALL_COLUMNS.find(c => c.field === event.currentTarget.dataset.field); if (col) this.visibleColumns = [...this.visibleColumns, col]; this.showColumnPicker = false; }

    handleSort(event) {
        const field = event.currentTarget.dataset.field;
        if (!field) return;
        if (this.sortField === field) { this.sortDir = this.sortDir === 'asc' ? 'desc' : 'asc'; }
        else { this.sortField = field; this.sortDir = 'asc'; }
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
}