import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContratistaList                from '@salesforce/apex/TechContratistaController.getContratistaList';
import searchFianzas                     from '@salesforce/apex/TechContratistaController.searchFianzas';
import searchContratos                   from '@salesforce/apex/TechContratistaController.searchContratos';
import addRelacion                       from '@salesforce/apex/TechContratistaController.addRelacion';
import getPrecalificacionesByContratista from '@salesforce/apex/TechPrecalificacionController.getPrecalificacionesByContratista';

const ALL_COLUMNS = [
    { field: 'rfc',              label: 'RFC',               icon: 'utility:identity',  isRfc:              true, minWidthStyle: 'min-width:140px', sortable: true  },
    { field: 'cliente',          label: 'Ciudad',            icon: 'utility:location',  isCliente:          true, minWidthStyle: 'min-width:160px', sortable: true  },
    { field: 'fianzas',          label: 'Fianza(s)',          icon: 'utility:layers',    isFianzas:          true, minWidthStyle: 'min-width:160px', sortable: false },
    { field: 'contratos',        label: 'Contrato(s)',        icon: 'utility:contract',  isContratos:        true, minWidthStyle: 'min-width:160px', sortable: false },
    { field: 'precalificaciones',label: 'Precalificaciones',  icon: 'utility:percent',   isPrecalificaciones:true, minWidthStyle: 'min-width:180px', sortable: false },
    { field: 'estatus',          label: 'Estado',             icon: 'utility:record',    isEstatus:          true, minWidthStyle: 'min-width:120px', sortable: true  },
];
const DEFAULT_VISIBLE = ['rfc', 'cliente', 'fianzas', 'contratos', 'precalificaciones', 'estatus'];
const SF_FIELD_MAP    = { name: 'Name', rfc: 'RFC__c' };

export default class TechContratistas extends LightningElement {
    @track filteredData      = [];
    @track originalData      = [];
    @track visibleColumns    = [];
    @track kanbanColumns     = [];
    @track isDetailPanelOpen = false;
    @track isEditingPanel    = false;
    @track selectedItem      = null;
    @track showColumnPicker  = false;
    @track isAddingFianza    = false;
    @track isAddingContrato  = false;
    @track fianzaSearchResults   = [];
    @track contratoSearchResults = [];
    @track precalificaciones          = [];
    @track isLoadingPrecalificaciones = false;
    @track isAddingPrecalificacion    = false;
    @track selectedPrecalificacion    = null;
    @track isPdfPanelOpen             = false;
    @track isInterfacesOpen           = false;
    @track interfacesContratistaId    = null;
    @track interfacesContratistaName  = '';

    currentView = 'grid'; searchTerm = ''; isLoading = true;
    isCreateModalOpen = false; editingCell = null; wiredResult;
    sortField = 'name'; sortDir = 'asc';

    @wire(getContratistaList)
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
        const badgeMap = { 'Activo': 'at-badge at-badge-green', 'Inactivo': 'at-badge at-badge-gray' };
        this.kanbanColumns = Object.keys(map).map(s => ({ status: s, items: map[s], count: map[s].length, badgeClass: badgeMap[s] || 'at-badge at-badge-gray' }));
    }

    handleSearch(event) { this.searchTerm = event.target.value.toLowerCase(); this.filterData(); }

    filterData() {
        const term = this.searchTerm;
        let result = term
            ? this.originalData.filter(f => (f.name && f.name.toLowerCase().includes(term)) || (f.rfc && f.rfc.toLowerCase().includes(term)) || (f.fianzas && f.fianzas.some(x => x.toLowerCase().includes(term))))
            : [...this.originalData];
        result.sort((a, b) => {
            let va = a[this.sortField]; let vb = b[this.sortField];
            if (va == null) va = ''; if (vb == null) vb = '';
            const cmp = (typeof va === 'number' && typeof vb === 'number') ? va - vb : String(va).localeCompare(String(vb), 'es', { numeric: true });
            return this.sortDir === 'asc' ? cmp : -cmp;
        });
        const ec = this.editingCell;
        this.filteredData = result.map((f, idx) => {
            const precs = f.precalificaciones || [];
            return {
                ...f, rowNumber: idx + 1,
                estatusClass:         this._estatusCls(f.estatus),
                hasFianzas:           f.fianzas && f.fianzas.length > 0,
                hasContratos:         f.contratos && f.contratos.length > 0,
                isEditingName:        ec?.rowId === f.id && ec?.field === 'name',
                precalificaciones:    precs,
                precalificacionChips: precs.slice(0, 2),
                precalificacionExtra: precs.length > 2 ? precs.length - 2 : 0,
            };
        });
        if (this.isKanbanView) this._buildKanban();
    }

    _estatusCls(s) {
        if (s === 'Activo' || s === 'Activa')       return 'at-badge at-badge-green';
        if (s === 'Pendiente')                        return 'at-badge at-badge-orange';
        if (s === 'Cancelado' || s === 'Cancelada')  return 'at-badge at-badge-red';
        if (s === 'En Proceso')                       return 'at-badge at-badge-blue';
        if (s === 'Completado')                       return 'at-badge at-badge-green';
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
    _openDetail(id) {
        this.selectedItem = this.filteredData.find(f => f.id === id) || null;
        this.isDetailPanelOpen = !!this.selectedItem;
        this.isAddingPrecalificacion = false;
        this.precalificaciones = [];
        if (this.selectedItem) this._loadPrecalificaciones();
    }
    handleCloseDetailPanel() {
        this.isDetailPanelOpen = false;
        this.selectedItem = null;
        this.isEditingPanel = false;
        this.precalificaciones = [];
        this.isAddingPrecalificacion = false;
        this.selectedPrecalificacion = null;
        this.isPdfPanelOpen = false;
    }

    handleCloseAll() {
        this.handleCloseDetailPanel();
    }

    get panelsWrapperClass() {
        if (this.isPdfPanelOpen)          return 'at-panels-wrapper at-panels-wrapper-pdf';
        if (this.isAddingPrecalificacion) return 'at-panels-wrapper at-panels-wrapper-dual';
        return 'at-panels-wrapper';
    }

    get detailPanelClass() {
        return 'at-detail-panel';
    }

    get pdfUrl() {
        return this.selectedPrecalificacion
            ? `/apex/PrecalificacionPDF?id=${this.selectedPrecalificacion.id}#navpanes=0&toolbar=1`
            : '';
    }

    handleClosePdfPanel() {
        this.isPdfPanelOpen = false;
        this.selectedPrecalificacion = null;
    }

    _loadPrecalificaciones() {
        this.isLoadingPrecalificaciones = true;
        console.log('[Precalificaciones] contratistaId:', this.selectedItem.id);
        getPrecalificacionesByContratista({ contratistaId: this.selectedItem.id })
            .then(data => {
                console.log('[Precalificaciones] data recibida:', JSON.stringify(data));
                const fmt = v => v != null ? '$' + Number(v).toLocaleString('es-MX', { minimumFractionDigits: 0 }) : '—';
                this.precalificaciones = data.map(p => ({
                    ...p,
                    estadoLabel:           p.estadoAutomatico || p.estado || 'Sin estado',
                    capitalContableFmt:    fmt(p.capitalContable),
                    ventasNetasFmt:        fmt(p.ventasNetas),
                    lineaAfianzamientoFmt: fmt(p.lineaAfianzamiento),
                    fechaFmt:              p.fechaEstadosFinancieros ? p.fechaEstadosFinancieros : '—',
                }));
                console.log('[Precalificaciones] mapeadas:', JSON.stringify(this.precalificaciones));
            })
            .catch(err => {
                console.error('[Precalificaciones] ERROR:', JSON.stringify(err));
                this.precalificaciones = [];
            })
            .finally(() => { this.isLoadingPrecalificaciones = false; });
    }

    get hasPrecalificaciones() { return this.precalificaciones.length > 0; }

    handleAddPrecalificacionStart()  { this.isAddingPrecalificacion = true; this.isPdfPanelOpen = false; }
    handleCancelPrecalificacion()    { this.isAddingPrecalificacion = false; }

    handlePrecalificacionSaved() {
        this.isAddingPrecalificacion = false;
        this._loadPrecalificaciones();
        return refreshApex(this.wiredResult);
    }

    handlePrecalificacionError(event) {
        this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: event.detail?.detail || 'Error al guardar', variant: 'error' }));
    }

    handlePrecalificacionClick(event) {
        event.stopPropagation();
        const id = event.currentTarget.dataset.id;
        this.selectedPrecalificacion = this.precalificaciones.find(p => p.id === id) || null;
        if (this.selectedPrecalificacion) this.isPdfPanelOpen = true;
    }

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

    get hasFianzaResults()   { return this.fianzaSearchResults.length   > 0; }
    get hasContratoResults() { return this.contratoSearchResults.length > 0; }

    handleAddFianzaStart()   { this.isAddingFianza   = true;  this.fianzaSearchResults   = []; }
    handleAddContratoStart() { this.isAddingContrato = true;  this.contratoSearchResults = []; }
    handleCancelAddFianza()   { this.isAddingFianza   = false; this.fianzaSearchResults   = []; }
    handleCancelAddContrato() { this.isAddingContrato = false; this.contratoSearchResults = []; }

    handleFianzaSearch(event) {
        const term = event.target.value;
        if (!term) { this.fianzaSearchResults = []; return; }
        searchFianzas({ term })
            .then(res  => { this.fianzaSearchResults = res; })
            .catch(()  => { this.fianzaSearchResults = []; });
    }

    handleContratoSearch(event) {
        const term = event.target.value;
        if (!term) { this.contratoSearchResults = []; return; }
        searchContratos({ term })
            .then(res  => { this.contratoSearchResults = res; })
            .catch(()  => { this.contratoSearchResults = []; });
    }

    _afterAddRelacion(tipo) {
        return refreshApex(this.wiredResult).then(() => {
            const updated = this.filteredData.find(f => f.id === this.selectedItem.id);
            if (updated) this.selectedItem = { ...updated };
            if (tipo === 'Fianza')   { this.isAddingFianza   = false; this.fianzaSearchResults   = []; }
            if (tipo === 'Contrato') { this.isAddingContrato = false; this.contratoSearchResults = []; }
        });
    }

    handleSelectFianza(event) {
        const relatedId = event.currentTarget.dataset.id;
        addRelacion({ contratistaId: this.selectedItem.id, relatedId, tipo: 'Fianza' })
            .then(() => this._afterAddRelacion('Fianza'))
            .catch(err => this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err.body?.message, variant: 'error' })));
    }

    handleSelectContrato(event) {
        const relatedId = event.currentTarget.dataset.id;
        addRelacion({ contratistaId: this.selectedItem.id, relatedId, tipo: 'Contrato' })
            .then(() => this._afterAddRelacion('Contrato'))
            .catch(err => this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err.body?.message, variant: 'error' })));
    }

    handleOpenCreateModal()  { this.isCreateModalOpen = true; }
    handleCloseCreateModal() { this.isCreateModalOpen = false; }
    handleCreateSuccess()    { this.isCreateModalOpen = false; return refreshApex(this.wiredResult); }

    handleOpenInterfaces() {
        if (!this.selectedItem) return;
        this.interfacesContratistaId   = this.selectedItem.id;
        this.interfacesContratistaName = this.selectedItem.name;
        this.isInterfacesOpen = true;
    }

    handleOpenInterfacesRow(event) {
        event.stopPropagation();
        this.interfacesContratistaId   = event.currentTarget.dataset.id;
        this.interfacesContratistaName = event.currentTarget.dataset.name;
        this.isInterfacesOpen = true;
    }

    handleCloseInterfaces() { this.isInterfacesOpen = false; }

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