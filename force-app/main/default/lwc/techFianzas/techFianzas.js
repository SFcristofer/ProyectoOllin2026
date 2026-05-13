import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFianzasList           from '@salesforce/apex/TechFianzaController.getFianzasList';
import getSubmodulosFianza      from '@salesforce/apex/TechFianzaController.getSubmodulosFianza';
import searchContratistas       from '@salesforce/apex/TechFianzaController.searchContratistas';
import searchVendedores         from '@salesforce/apex/TechFianzaController.searchVendedores';
import searchContratosForFianza from '@salesforce/apex/TechFianzaController.searchContratosForFianza';
import addRelacionFianza        from '@salesforce/apex/TechFianzaController.addRelacionFianza';
import deleteRelacion           from '@salesforce/apex/TechFianzaController.deleteRelacion';

const ALL_COLUMNS = [
    { field: 'contratistas',       label: 'Contratista(s)',    icon: 'utility:user',        isContratistas:      true, minWidthStyle: 'min-width:160px', sortable: false },
    { field: 'vendedores',         label: 'Vendedor(es)',      icon: 'utility:people',      isVendedores:        true, minWidthStyle: 'min-width:160px', sortable: false },
    { field: 'beneficiario',       label: 'Beneficiario',      icon: 'utility:company',     isBeneficiario:      true, minWidthStyle: 'min-width:180px', sortable: true  },
    { field: 'contratos',          label: 'Contrato(s)',       icon: 'utility:contract',    isContratos:         true, minWidthStyle: 'min-width:160px', sortable: false },
    { field: 'tipoRiesgo',         label: 'Tipo de Riesgo',    icon: 'utility:type_tool',   isTipoRiesgo:        true, minWidthStyle: 'min-width:150px', sortable: true  },
    { field: 'monto',              label: 'Monto Afianzado',   icon: 'utility:currency',    isMonto:             true, minWidthStyle: 'min-width:150px', sortable: true  },
    { field: 'montoVigente',       label: 'Monto Vigente',     icon: 'utility:currency',    isMontoVigente:      true, minWidthStyle: 'min-width:150px', sortable: true  },
    { field: 'primaNeta',          label: 'Prima Neta',        icon: 'utility:currency',    isPrimaNeta:         true, minWidthStyle: 'min-width:130px', sortable: true  },
    { field: 'primaVigente',       label: 'Prima Vigente',     icon: 'utility:currency',    isPrimaVigente:      true, minWidthStyle: 'min-width:130px', sortable: true  },
    { field: 'estatus',            label: 'Estado',            icon: 'utility:record',      isEstatus:           true, minWidthStyle: 'min-width:120px', sortable: true  },
    { field: 'fecha',              label: 'Fecha Emisión',     icon: 'utility:event',       isFecha:             true, minWidthStyle: 'min-width:130px', sortable: true  },
    { field: 'fechaVencimiento',   label: 'Vencimiento',       icon: 'utility:event',       isFechaVencimiento:  true, minWidthStyle: 'min-width:130px', sortable: true  },
    { field: 'fechaVencimientoVig',label: 'Venc. Vigente',     icon: 'utility:event',       isFechaVigente:      true, minWidthStyle: 'min-width:140px', sortable: true  },
    { field: 'plazoReclamacion',   label: 'Plazo Reclamación', icon: 'utility:event',       isPlazoReclamacion:  true, minWidthStyle: 'min-width:140px', sortable: true  },
    { field: 'diasReclamacion',    label: 'Días p/Recl.',      icon: 'utility:formula',     isDiasReclamacion:   true, minWidthStyle: 'min-width:120px', sortable: true  },
];

const DEFAULT_VISIBLE = ['contratistas', 'tipoRiesgo', 'monto', 'estatus', 'fechaVencimiento', 'beneficiario', 'vendedores', 'contratos', 'primaNeta', 'fecha'];

const SF_FIELD_MAP = {
    name:    'Name',
    monto:   'Monto_Afianzado__c',
    estatus: 'Estatus__c',
    fecha:   'Fecha_de_Emisi_n__c',
};

const STATUS_ORDER = ['Activa', 'Pendiente', 'Cancelada', 'Vencida'];

export default class TechFianzas extends NavigationMixin(LightningElement) {
    @track fianzasOriginales = [];
    @track fianzasFiltradas  = [];
    @track visibleColumns    = [];
    @track kanbanColumns     = [];
    @track isDetailPanelOpen = false;
    @track selectedFianza    = null;
    @track showColumnPicker  = false;
    @track isAddingContratista  = false;
    @track isAddingVendedor     = false;
    @track isAddingContratoRel  = false;
    @track contratistaResults   = [];
    @track vendedorResults      = [];
    @track contratoRelResults   = [];
    @track isEditingPanel           = false;
    @track isCreatingNewContratista = false;
    @track isCreatingNewVendedor    = false;
    @track isCreatingNewContratoRel = false;

    currentView   = 'grid';
    searchTerm    = '';
    isLoading     = true;
    sortField     = 'name';
    sortDir       = 'asc';
    isCreateModalOpen = false;
    isEditModalOpen   = false;
    editFianzaId      = null;
    editingCell   = null;
    wiredFianzasResult;

    @track currentPage = 1;
    pageSize = 50;

    @track submodulos = { planes: [], comisiones: [], totalOllin: 0, totalVendedor: 0, loading: false };
    @track expandPlanes     = true;
    @track expandComisiones = true;

    // ─── Wire ──────────────────────────────────────────────────
    @wire(getFianzasList)
    wiredFianzas(result) {
        this.wiredFianzasResult = result;
        this.isLoading = true;
        const { data, error } = result;
        if (data) {
            this.fianzasOriginales = data;
            this.filterData();
        } else if (error) {
            this.fianzasOriginales = [];
            this.dispatchEvent(new ShowToastEvent({ title: 'Error al cargar', message: error.body?.message, variant: 'error' }));
        }
        this.isLoading = false;
    }

    connectedCallback() {
        this.visibleColumns = ALL_COLUMNS.filter(c => DEFAULT_VISIBLE.includes(c.field));
    }

    // ─── View tabs ─────────────────────────────────────────────
    get isGridView()     { return this.currentView === 'grid'; }
    get isGalleryView()  { return this.currentView === 'gallery'; }
    get isKanbanView()   { return this.currentView === 'kanban'; }
    get isCalendarView() { return this.currentView === 'calendar'; }

    get gridTabClass()     { return this._tabCls('grid'); }
    get galleryTabClass()  { return this._tabCls('gallery'); }
    get kanbanTabClass()   { return this._tabCls('kanban'); }
    get calendarTabClass() { return this._tabCls('calendar'); }

    _tabCls(view) {
        return `at-view-tab${this.currentView === view ? ' at-view-tab-active' : ''}`;
    }

    handleViewChange(event) {
        this.currentView = event.currentTarget.dataset.view;
        this.showColumnPicker = false;
        if (this.currentView === 'kanban') this._buildKanban();
    }

    // ─── Kanban ────────────────────────────────────────────────
    _buildKanban() {
        const map = {};
        this.fianzasFiltradas.forEach(f => {
            const s = f.estatus || 'Sin Estado';
            if (!map[s]) map[s] = [];
            map[s].push(f);
        });
        const badgeMap = {
            'Activa':    'at-badge at-badge-green',
            'Pendiente': 'at-badge at-badge-orange',
            'Cancelada': 'at-badge at-badge-red',
            'Vencida':   'at-badge at-badge-gray',
        };
        const ordered = STATUS_ORDER.filter(s => map[s]).concat(Object.keys(map).filter(s => !STATUS_ORDER.includes(s)));
        this.kanbanColumns = ordered.map(s => ({
            status:    s,
            items:     map[s],
            count:     map[s].length,
            badgeClass: badgeMap[s] || 'at-badge at-badge-gray',
        }));
    }

    // ─── Search / filter ───────────────────────────────────────
    handleSearch(event) {
        this.searchTerm = event.target.value.toLowerCase();
        this.currentPage = 1;
        this.filterData();
    }

    filterData() {
        const term = this.searchTerm;
        let result = term
            ? this.fianzasOriginales.filter(f =>
                (f.name       && f.name.toLowerCase().includes(term))       ||
                (f.estatus    && f.estatus.toLowerCase().includes(term))    ||
                (f.contratistas && f.contratistas.some(c => c.toLowerCase().includes(term)))
            )
            : [...this.fianzasOriginales];

        result.sort((a, b) => {
            let va = a[this.sortField]; let vb = b[this.sortField];
            if (va == null) va = ''; if (vb == null) vb = '';
            const cmp = (typeof va === 'number' && typeof vb === 'number') ? va - vb : String(va).localeCompare(String(vb), 'es', { numeric: true });
            return this.sortDir === 'asc' ? cmp : -cmp;
        });

        const ec = this.editingCell;
        this.fianzasFiltradas = result.map((f, idx) => ({
            ...f,
            rowNumber:               idx + 1,
            fechaISO:                f.fechaEmision ? String(f.fechaEmision).substring(0, 10) : '',
            fechaDisplay:            f.fechaEmision ? new Date(f.fechaEmision).toLocaleDateString('es-MX', { year:'numeric', month:'short', day:'numeric' }) : '',
            fechaVencimientoDisplay:  f.fechaVencimiento    ? new Date(f.fechaVencimiento).toLocaleDateString('es-MX', { year:'numeric', month:'short', day:'numeric' }) : '—',
            fechaVigenteDisplay:      f.fechaVencimientoVig ? new Date(f.fechaVencimientoVig).toLocaleDateString('es-MX', { year:'numeric', month:'short', day:'numeric' }) : '—',
            plazoReclamacionDisplay:  f.plazoReclamacion    ? new Date(f.plazoReclamacion).toLocaleDateString('es-MX', { year:'numeric', month:'short', day:'numeric' }) : '—',
            diasReclamacionDisplay:   f.diasReclamacion     != null ? String(f.diasReclamacion) : '—',
            tipoRiesgoDisplay:        f.tipoRiesgo || '—',
            estatusClass:            this._estatusCls(f.estatus),
            hasContratistas:    f.contratistas    && f.contratistas.length    > 0,
            hasVendedores:      f.vendedores      && f.vendedores.length      > 0,
            hasContratos:       f.contratos       && f.contratos.length       > 0,
            hasContratistaRels: f.contratistaRels && f.contratistaRels.length > 0,
            hasVendedorRels:    f.vendedorRels    && f.vendedorRels.length    > 0,
            hasContratoRels:    f.contratoRels    && f.contratoRels.length    > 0,
            isEditingName:    ec?.rowId === f.id && ec?.field === 'name',
            isEditingMonto:   ec?.rowId === f.id && ec?.field === 'monto',
            isEditingEstatus: ec?.rowId === f.id && ec?.field === 'estatus',
            isEditingFecha:   ec?.rowId === f.id && ec?.field === 'fecha',
        }));

        if (this.isKanbanView) this._buildKanban();
    }

    _estatusCls(estatus) {
        if (estatus === 'Activa')    return 'at-badge at-badge-green';
        if (estatus === 'Pendiente') return 'at-badge at-badge-orange';
        if (estatus === 'Cancelada') return 'at-badge at-badge-red';
        if (estatus === 'Vencida')   return 'at-badge at-badge-gray';
        return 'at-badge at-badge-gray';
    }

    // ─── Inline editing ────────────────────────────────────────
    handleCellClick(event) {
        const td    = event.currentTarget;
        const rowId = td.dataset.id;
        const field = td.dataset.field;
        if (!rowId || !field) return;

        const chipFields = ['contratistas', 'vendedores', 'contratos'];
        if (chipFields.includes(field)) {
            this._openDetailById(rowId);
            return;
        }

        this.editingCell = { rowId, field };
        this.filterData();

        // Focus after re-render
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        Promise.resolve().then(() => {
            const el = this.template.querySelector(
                `input[data-id="${rowId}"][data-field="${field}"], select[data-id="${rowId}"][data-field="${field}"]`
            );
            if (el) el.focus();
        });
    }

    handleCellBlur(event) {
        const el    = event.currentTarget;
        this._commitEdit(el.dataset.id, el.dataset.field, el.value);
    }

    handleCellKeydown(event) {
        if (event.key === 'Enter') {
            event.currentTarget.blur();
        } else if (event.key === 'Escape') {
            this.editingCell = null;
            this.filterData();
        }
    }

    handleSelectChange(event) {
        const el = event.currentTarget;
        this._commitEdit(el.dataset.id, el.dataset.field, el.value);
    }

    handleSelectBlur(event) {
        if (!this.editingCell) return;
        this.editingCell = null;
        this.filterData();
    }

    _commitEdit(rowId, field, value) {
        this.editingCell = null;
        const sfField = SF_FIELD_MAP[field];
        if (!sfField || !rowId || value === undefined || value === null) {
            this.filterData();
            return;
        }

        const parsedValue = field === 'monto' ? parseFloat(value) : value;
        const fields = { Id: rowId, [sfField]: parsedValue };

        updateRecord({ fields })
            .then(() => {
                this.fianzasOriginales = this.fianzasOriginales.map(f => {
                    if (f.id !== rowId) return f;
                    return { ...f, [field]: parsedValue };
                });
                this.filterData();
                this.dispatchEvent(new ShowToastEvent({ title: 'Guardado', message: 'Campo actualizado.', variant: 'success' }));
            })
            .catch(err => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err.body?.message, variant: 'error' }));
                this.filterData();
            });
    }

    // ─── Row expansion / detail panel ──────────────────────────
    handleExpandRow(event) {
        event.stopPropagation();
        this._openDetailById(event.currentTarget.dataset.id);
    }

    _openDetailById(id) {
        this.selectedFianza = this.fianzasFiltradas.find(f => f.id === id) || null;
        this.isDetailPanelOpen = !!this.selectedFianza;
        if (this.selectedFianza) this._loadSubmodulos(id);
    }

    _loadSubmodulos(fianzaId) {
        this.submodulos = { planes: [], comisiones: [], totalOllin: 0, totalVendedor: 0, loading: true };
        getSubmodulosFianza({ fianzaId })
            .then(data => {
                this.submodulos = { ...data, loading: false };
            })
            .catch(() => {
                this.submodulos = { planes: [], comisiones: [], totalOllin: 0, totalVendedor: 0, loading: false };
            });
    }

    handleCloseDetailPanel() {
        this.isDetailPanelOpen = false;
        this.selectedFianza    = null;
        this.isEditingPanel    = false;
        this.submodulos        = { planes: [], comisiones: [], totalOllin: 0, totalVendedor: 0, loading: false };
    }

    get currentDetailIndex() { return this.fianzasFiltradas.findIndex(f => f.id === this.selectedFianza?.id); }
    get isFirstRecord()      { return this.currentDetailIndex <= 0; }
    get isLastRecord()       { return this.currentDetailIndex >= this.fianzasFiltradas.length - 1; }
    handlePrevRecord() {
        const i = this.currentDetailIndex;
        if (i > 0) {
            this.selectedFianza = { ...this.fianzasFiltradas[i - 1] };
            this.isEditingPanel = false;
            this._loadSubmodulos(this.selectedFianza.id);
        }
    }
    handleNextRecord() {
        const i = this.currentDetailIndex;
        if (i < this.fianzasFiltradas.length - 1) {
            this.selectedFianza = { ...this.fianzasFiltradas[i + 1] };
            this.isEditingPanel = false;
            this._loadSubmodulos(this.selectedFianza.id);
        }
    }

    handleEditFromPanel()   { this.isEditingPanel = true; }
    handlePanelCancel()     { this.isEditingPanel = false; }
    handlePanelSaveSuccess() {
        this.isEditingPanel = false;
        refreshApex(this.wiredFianzasResult).then(() => {
            const updated = this.fianzasFiltradas.find(f => f.id === this.selectedFianza?.id);
            if (updated) this.selectedFianza = { ...updated };
        });
        this.dispatchEvent(new ShowToastEvent({ title: 'Guardado', message: 'Fianza actualizada correctamente.', variant: 'success' }));
    }

    handleCloseEditModal()  { this.isEditModalOpen = false; this.editFianzaId = null; }
    handleEditSuccess()     { this.isEditModalOpen = false; this.editFianzaId = null; return refreshApex(this.wiredFianzasResult); }

    handleOverlayClick() {
        this.handleCloseDetailPanel();
    }

    // ─── Add field ─────────────────────────────────────────────
    get availableColumns() {
        const shown = new Set(this.visibleColumns.map(c => c.field));
        return ALL_COLUMNS.filter(c => !shown.has(c.field));
    }

    get hasAvailableColumns() {
        return this.availableColumns.length > 0;
    }

    handleToggleColumnPicker(event) {
        event.stopPropagation();
        this.showColumnPicker = !this.showColumnPicker;
    }

    stopPropagation(event) {
        event.stopPropagation();
    }

    handleSelectColumn(event) {
        event.stopPropagation();
        const field = event.currentTarget.dataset.field;
        const col   = ALL_COLUMNS.find(c => c.field === field);
        if (col) this.visibleColumns = [...this.visibleColumns, col];
        this.showColumnPicker = false;
    }

    // ─── Linked record search ──────────────────────────────────
    get hasContratistaResults()  { return this.contratistaResults.length  > 0; }
    get hasVendedorResults()     { return this.vendedorResults.length     > 0; }
    get hasContratoRelResults()  { return this.contratoRelResults.length  > 0; }

    handleAddContratistaStart()  { this.isAddingContratista = true;  this.contratistaResults  = []; }
    handleAddVendedorStart()     { this.isAddingVendedor    = true;  this.vendedorResults     = []; }
    handleAddContratoRelStart()  { this.isAddingContratoRel = true;  this.contratoRelResults  = []; }
    handleCancelContratista()    { this.isAddingContratista = false; this.contratistaResults  = []; this.isCreatingNewContratista = false; }
    handleCancelVendedor()       { this.isAddingVendedor    = false; this.vendedorResults     = []; this.isCreatingNewVendedor    = false; }
    handleCancelContratoRel()    { this.isAddingContratoRel = false; this.contratoRelResults  = []; this.isCreatingNewContratoRel = false; }

    _deleteRel(relId) {
        return deleteRelacion({ relId })
            .then(() => refreshApex(this.wiredFianzasResult))
            .then(() => {
                const updated = this.fianzasFiltradas.find(f => f.id === this.selectedFianza.id);
                if (updated) this.selectedFianza = { ...updated };
            })
            .catch(err => this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err.body?.message, variant: 'error' })));
    }
    handleDeleteContratista(event) { this._deleteRel(event.currentTarget.dataset.relId); }
    handleDeleteVendedor(event)    { this._deleteRel(event.currentTarget.dataset.relId); }
    handleDeleteContratoRel(event) { this._deleteRel(event.currentTarget.dataset.relId); }

    handleCreateNewAccount()  { this.isCreatingNewContratista = true; }
    handleCreateNewVendedor() { this.isCreatingNewVendedor    = true; }
    handleCreateNewContrato() { this.isCreatingNewContratoRel = true; }

    handleCancelCreateContratista() { this.isCreatingNewContratista = false; }
    handleCancelCreateVendedor()    { this.isCreatingNewVendedor    = false; }
    handleCancelCreateContratoRel() { this.isCreatingNewContratoRel = false; }

    handleCreatedContratista(event) {
        const newId = event.detail.id;
        addRelacionFianza({ fianzaId: this.selectedFianza.id, relatedId: newId, tipo: 'Contratista' })
            .then(() => { this.isCreatingNewContratista = false; return this._afterAddRelFianza('Contratista'); })
            .catch(err => this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err.body?.message, variant: 'error' })));
    }
    handleCreatedVendedor(event) {
        const newId = event.detail.id;
        addRelacionFianza({ fianzaId: this.selectedFianza.id, relatedId: newId, tipo: 'Vendedor' })
            .then(() => { this.isCreatingNewVendedor = false; return this._afterAddRelFianza('Vendedor'); })
            .catch(err => this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err.body?.message, variant: 'error' })));
    }
    handleCreatedContratoRel(event) {
        const newId = event.detail.id;
        addRelacionFianza({ fianzaId: this.selectedFianza.id, relatedId: newId, tipo: 'Contrato' })
            .then(() => { this.isCreatingNewContratoRel = false; return this._afterAddRelFianza('Contrato'); })
            .catch(err => this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err.body?.message, variant: 'error' })));
    }

    handleContratistaSearch(event) {
        const term = event.target.value;
        if (!term) { this.contratistaResults = []; return; }
        searchContratistas({ term })
            .then(res => { this.contratistaResults = res; })
            .catch(()  => { this.contratistaResults = []; });
    }
    handleVendedorSearch(event) {
        const term = event.target.value;
        if (!term) { this.vendedorResults = []; return; }
        searchVendedores({ term })
            .then(res => { this.vendedorResults = res; })
            .catch(()  => { this.vendedorResults = []; });
    }
    handleContratoRelSearch(event) {
        const term = event.target.value;
        if (!term) { this.contratoRelResults = []; return; }
        searchContratosForFianza({ term })
            .then(res => { this.contratoRelResults = res; })
            .catch(()  => { this.contratoRelResults = []; });
    }

    _afterAddRelFianza(tipo) {
        return refreshApex(this.wiredFianzasResult).then(() => {
            const updated = this.fianzasFiltradas.find(f => f.id === this.selectedFianza.id);
            if (updated) this.selectedFianza = { ...updated };
            if (tipo === 'Contratista') { this.isAddingContratista = false; this.contratistaResults  = []; }
            if (tipo === 'Vendedor')    { this.isAddingVendedor    = false; this.vendedorResults     = []; }
            if (tipo === 'Contrato')    { this.isAddingContratoRel = false; this.contratoRelResults  = []; }
        });
    }

    handleSelectContratista(event) {
        const relatedId = event.currentTarget.dataset.id;
        addRelacionFianza({ fianzaId: this.selectedFianza.id, relatedId, tipo: 'Contratista' })
            .then(() => this._afterAddRelFianza('Contratista'))
            .catch(err => this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err.body?.message, variant: 'error' })));
    }
    handleSelectVendedor(event) {
        const relatedId = event.currentTarget.dataset.id;
        addRelacionFianza({ fianzaId: this.selectedFianza.id, relatedId, tipo: 'Vendedor' })
            .then(() => this._afterAddRelFianza('Vendedor'))
            .catch(err => this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err.body?.message, variant: 'error' })));
    }
    handleSelectContratoRel(event) {
        const relatedId = event.currentTarget.dataset.id;
        addRelacionFianza({ fianzaId: this.selectedFianza.id, relatedId, tipo: 'Contrato' })
            .then(() => this._afterAddRelFianza('Contrato'))
            .catch(err => this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err.body?.message, variant: 'error' })));
    }

    // ─── Create modal ──────────────────────────────────────────
    handleOpenCreateModal() {
        this.isCreateModalOpen = true;
    }

    handleCloseCreateModal() {
        this.isCreateModalOpen = false;
    }

    handleCreateSuccess() {
        this.isCreateModalOpen = false;
        return refreshApex(this.wiredFianzasResult);
    }

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

    // ─── Sub-módulos: Plan de Pagos, Recibos y Comisiones ──────
    get hasPlanes()      { return this.submodulos.planes     && this.submodulos.planes.length     > 0; }
    get hasComisiones()  { return this.submodulos.comisiones && this.submodulos.comisiones.length > 0; }
    get planesToggleIcon()      { return this.expandPlanes     ? '▲' : '▼'; }
    get comisionesToggleIcon()  { return this.expandComisiones ? '▲' : '▼'; }

    handleTogglePlanes()     { this.expandPlanes     = !this.expandPlanes; }
    handleToggleComisiones() { this.expandComisiones = !this.expandComisiones; }

    // ─── Pagination ────────────────────────────────────────────
    get totalPages()   { return Math.max(1, Math.ceil(this.fianzasFiltradas.length / this.pageSize)); }
    get isFirstPage()  { return this.currentPage <= 1; }
    get isLastPage()   { return this.currentPage >= this.totalPages; }
    get paginationLabel() {
        const total = this.fianzasFiltradas.length;
        if (total === 0) return '0 registros';
        const start = (this.currentPage - 1) * this.pageSize + 1;
        const end   = Math.min(this.currentPage * this.pageSize, total);
        return `${start}–${end} de ${total}`;
    }
    get showPagination() { return this.fianzasFiltradas.length > this.pageSize; }
    get pagedFianzas() {
        const start = (this.currentPage - 1) * this.pageSize;
        return this.fianzasFiltradas.slice(start, start + this.pageSize);
    }
    handlePrevPage() { if (!this.isFirstPage) this.currentPage--; }
    handleNextPage() { if (!this.isLastPage)  this.currentPage++; }
}