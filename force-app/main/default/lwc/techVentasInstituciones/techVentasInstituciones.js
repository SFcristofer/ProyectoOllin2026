import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getInstitucionList from '@salesforce/apex/TechInstitucionController.getInstitucionList';

const GRID_HEADERS = [
    { key: 'num',      field: '',                   label: '#',                   sortable: false },
    { key: 'name',     field: 'name',               label: 'Nombre',              sortable: true  },
    { key: 'tipo',     field: 'tipo',               label: 'Tipo',                sortable: true  },
    { key: 'estatus',  field: 'estatus',            label: 'Estatus',             sortable: true  },
    { key: 'ejPpal',   field: 'ejecutivoPrincipal', label: 'Ejecutivo principal', sortable: true  },
    { key: 'totalEj',  field: '',                   label: 'Ejecs.',              sortable: false },
];

const ESTATUS_CLASS = {
    'Activa':     'vin-badge vin-badge-green',
    'Activo':     'vin-badge vin-badge-green',
    'Suspendida': 'vin-badge vin-badge-orange',
    'Suspendido': 'vin-badge vin-badge-orange',
    'Inactiva':   'vin-badge vin-badge-gray',
    'Inactivo':   'vin-badge vin-badge-gray',
};

const TIPO_CLASS = {
    'Aseguradora': 'vin-badge vin-badge-blue',
    'Afianzadora': 'vin-badge vin-badge-amber',
    'Ambas':       'vin-badge vin-badge-purple',
};

const TEXT_OPS = [
    { v: 'contains', l: 'contiene'      },
    { v: 'eq',       l: 'es igual a'    },
    { v: 'ne',       l: 'no es igual a' },
];
const EQ_OPS = [
    { v: 'eq', l: 'es igual a'    },
    { v: 'ne', l: 'es diferente a' },
];

const FILTER_FIELD_DEFS = [
    { value: 'name',    label: 'Nombre',  type: 'text' },
    { value: 'tipo',    label: 'Tipo',    type: 'picklist', options: ['Aseguradora', 'Afianzadora', 'Ambas'] },
    { value: 'estatus', label: 'Estatus', type: 'picklist', options: ['Activa', 'Suspendida', 'Inactiva'] },
    { value: 'ejecutivoPrincipal', label: 'Ejecutivo principal', type: 'text' },
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

const AVATAR_COLORS = ['#6366f1', '#0ea5e9', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899'];

export default class TechVentasInstituciones extends NavigationMixin(LightningElement) {

    @track isLoading   = true;
    @track hasError    = false;
    @track errorMsg    = '';
    @track isModalOpen              = false;
    @track isEjecutivoModalOpen     = false;
    @track isPasswordModalOpen      = false;
    @track passwordModalMode        = 'reveal';
    @track isAccesoModalOpen        = false;
    @track isEjecutivoEditModalOpen = false;
    @track isAccesoEditModalOpen    = false;
    @track passwordAccesoId         = null;
    @track passwordPortalName       = '';
    @track editEjecutivoId          = null;
    @track editAccesoId             = null;
    @track _pendingAccesoAction     = null;
    @track _pendingDeleteAccesoId   = null;
    @track confirmDeleteEjecutivoId = null;
    @track searchTerm  = '';

    @track sortField = 'name';
    @track sortDir   = 'asc';

    @track showFilters = false;
    @track filterRules = [];
    _filterRuleCounter = 0;

    @track selectedInstitucion = null;
    @track isEditingPanel      = false;

    _wiredResult;
    _originalData = [];

    @wire(getInstitucionList)
    wiredData(result) {
        this._wiredResult = result;
        const { data, error } = result;
        if (data) {
            this._originalData = data;
            this.hasError = false;
        } else if (error) {
            this.hasError = true;
            this.errorMsg = error?.body?.message || 'Error al cargar instituciones';
            this._originalData = [];
        }
        this.isLoading = false;
    }

    get _filtered() {
        const term = this.searchTerm.toLowerCase();
        let result = term
            ? this._originalData.filter(r =>
                (r.name               && r.name.toLowerCase().includes(term))               ||
                (r.tipo               && r.tipo.toLowerCase().includes(term))               ||
                (r.ejecutivoPrincipal && r.ejecutivoPrincipal.toLowerCase().includes(term))
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
        return this._sorted.map((r, idx) => ({
            id:                r.id,
            rowNum:            idx + 1,
            name:              r.name    || '—',
            tipo:              r.tipo    || '—',
            estatus:           r.estatus || '—',
            ejecutivoPrincipal: r.ejecutivoPrincipal || '—',
            totalEjecutivos:   r.totalEjecutivos || 0,
            tipoClass:         TIPO_CLASS[r.tipo]       || 'vin-badge vin-badge-gray',
            estatusClass:      ESTATUS_CLASS[r.estatus] || 'vin-badge vin-badge-gray',
            ejChipClass:       (r.totalEjecutivos > 0) ? 'vin-chip vin-chip-blue' : 'vin-chip vin-chip-gray',
        }));
    }

    get showGrid() { return !this.isLoading && !this.hasError && this._filtered.length > 0; }
    get isEmpty()  { return !this.isLoading && !this.hasError && this._filtered.length === 0; }

    get gridHeaders() {
        return GRID_HEADERS.map(h => ({
            ...h,
            cellClass: 'vin-grid-cell vin-grid-hdr' +
                       (h.sortable ? ' vin-hdr-sort' : '') +
                       (this.sortField === h.field && h.field ? ' vin-sorted' : ''),
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
            this.selectedInstitucion = item;
            this.isEditingPanel      = false;
        }
    }

    get panelInstitucion() {
        if (!this.selectedInstitucion) return null;
        const r = this.selectedInstitucion;
        let sitioWebUrl = r.sitioWeb || '';
        if (sitioWebUrl && !sitioWebUrl.startsWith('http')) sitioWebUrl = 'https://' + sitioWebUrl;
        return {
            ...r,
            tipoClass:    TIPO_CLASS[r.tipo]       || 'vin-badge vin-badge-gray',
            estatusClass: ESTATUS_CLASS[r.estatus] || 'vin-badge vin-badge-gray',
            sitioWebUrl,
        };
    }

    get panelEjecutivos() {
        return (this.selectedInstitucion?.ejecutivos || []).map((ej, i) => {
            const words    = (ej.name || '').trim().split(/\s+/);
            const initials = words.length >= 2
                ? (words[0][0] + words[1][0]).toUpperCase()
                : ((words[0] || '?')[0] || '?').toUpperCase();
            const puestoArea = [ej.puesto, ej.area].filter(Boolean).join(' — ');
            return {
                ...ej,
                initials,
                avatarStyle:   `background:${AVATAR_COLORS[i % AVATAR_COLORS.length]};`,
                puestoArea:    puestoArea || '—',
                email:         ej.email    || '—',
                telefono:      ej.telefono || '—',
                celular:       ej.celular  || '—',
                confirmDelete: this.confirmDeleteEjecutivoId === ej.id,
            };
        });
    }
    get panelEjecutivosCount() { return (this.selectedInstitucion?.ejecutivos || []).length; }
    get hasEjecutivos()        { return this.panelEjecutivosCount > 0; }

    get panelAccesos() {
        return this.selectedInstitucion?.accesos || [];
    }
    get panelAccesosCount() { return this.panelAccesos.length; }
    get hasAccesos()        { return this.panelAccesos.length > 0; }

    handleNuevoEjecutivo() { this.isEjecutivoModalOpen = true; }

    handleEjecutivoModalClose()   { this.isEjecutivoModalOpen = false; }
    handleEjecutivoModalSuccess() {
        this.isEjecutivoModalOpen = false;
        this.dispatchEvent(new ShowToastEvent({ title: 'Creado', message: 'Ejecutivo creado exitosamente', variant: 'success' }));
        this._refreshAndReselect();
    }

    handleNuevoAcceso() {
        if (!this.selectedInstitucion) return;
        this.isAccesoModalOpen = true;
    }

    handleAccesoModalClose()   { this.isAccesoModalOpen = false; }
    handleAccesoModalSuccess() {
        this.isAccesoModalOpen = false;
        this.dispatchEvent(new ShowToastEvent({ title: 'Creado', message: 'Acceso al portal creado exitosamente', variant: 'success' }));
        this._refreshAndReselect();
    }

    handleTogglePass(e) {
        e.stopPropagation();
        this._openPasswordModal(e.currentTarget.dataset.id, e.currentTarget.dataset.name, 'reveal');
    }

    handlePasswordModalClose() {
        this.isPasswordModalOpen  = false;
        this._pendingAccesoAction = null;
        this._pendingDeleteAccesoId = null;
    }

    handlePasswordModalVerified() {
        this.isPasswordModalOpen = false;
        const action = this._pendingAccesoAction;
        this._pendingAccesoAction = null;
        if (action === 'edit') {
            this.isAccesoEditModalOpen = true;
        } else if (action === 'delete') {
            const id = this._pendingDeleteAccesoId;
            this._pendingDeleteAccesoId = null;
            deleteRecord(id)
                .then(() => {
                    this.dispatchEvent(new ShowToastEvent({ title: 'Eliminado', message: 'Acceso eliminado', variant: 'success' }));
                    this._refreshAndReselect();
                })
                .catch(err => {
                    this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err?.body?.message || 'No se pudo eliminar', variant: 'error' }));
                });
        }
    }

    _openPasswordModal(accesoId, portalName, mode, action) {
        this.passwordAccesoId     = accesoId;
        this.passwordPortalName   = portalName || '';
        this.passwordModalMode    = mode;
        this._pendingAccesoAction = action || null;
        this.isPasswordModalOpen  = true;
    }

    /* ── Ejecutivos: editar / eliminar ── */
    handleEditEjecutivo(e) {
        e.stopPropagation();
        this.editEjecutivoId        = e.currentTarget.dataset.id;
        this.isEjecutivoEditModalOpen = true;
    }
    handleEjecutivoEditClose()   { this.isEjecutivoEditModalOpen = false; }
    handleEjecutivoEditSuccess() {
        this.isEjecutivoEditModalOpen = false;
        this.dispatchEvent(new ShowToastEvent({ title: 'Guardado', message: 'Ejecutivo actualizado', variant: 'success' }));
        this._refreshAndReselect();
    }

    handleDeleteEjecutivoConfirm(e) {
        e.stopPropagation();
        this.confirmDeleteEjecutivoId = e.currentTarget.dataset.id;
    }
    handleCancelDeleteEjecutivo(e) {
        e.stopPropagation();
        this.confirmDeleteEjecutivoId = null;
    }
    handleDeleteEjecutivo(e) {
        e.stopPropagation();
        const id = e.currentTarget.dataset.id;
        this.confirmDeleteEjecutivoId = null;
        deleteRecord(id)
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Eliminado', message: 'Ejecutivo eliminado', variant: 'success' }));
                this._refreshAndReselect();
            })
            .catch(err => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err?.body?.message || 'No se pudo eliminar', variant: 'error' }));
            });
    }

    /* ── Accesos: editar / eliminar (requieren contraseña maestra) ── */
    handleEditAcceso(e) {
        e.stopPropagation();
        const id   = e.currentTarget.dataset.id;
        const name = e.currentTarget.dataset.name;
        this.editAccesoId = id;
        this._openPasswordModal(id, 'Acceso: ' + (name || ''), 'gate', 'edit');
    }
    handleAccesoEditClose()   { this.isAccesoEditModalOpen = false; }
    handleAccesoEditSuccess() {
        this.isAccesoEditModalOpen = false;
        this.dispatchEvent(new ShowToastEvent({ title: 'Guardado', message: 'Acceso actualizado', variant: 'success' }));
        this._refreshAndReselect();
    }

    handleDeleteAccesoConfirm(e) {
        e.stopPropagation();
        const id   = e.currentTarget.dataset.id;
        const name = e.currentTarget.dataset.name;
        this._pendingDeleteAccesoId = id;
        this._openPasswordModal(id, 'Eliminar acceso: ' + (name || ''), 'gate', 'delete');
    }

    _refreshAndReselect() {
        const prevId = this.selectedInstitucion?.id;
        refreshApex(this._wiredResult).then(() => {
            if (prevId) {
                const updated = this._originalData.find(r => r.id === prevId);
                if (updated) this.selectedInstitucion = updated;
            }
        });
    }

    get selectedInstitucionId()   { return this.selectedInstitucion?.id   || null; }
    get selectedInstitucionName() { return this.selectedInstitucion?.name || ''; }

    handleClosePanel() { this.selectedInstitucion = null; this.isEditingPanel = false; }
    handleEditPanel()  { this.isEditingPanel = true; }
    handleCancelEdit() { this.isEditingPanel = false; }

    handlePanelSaveSuccess() {
        this.isEditingPanel = false;
        this.dispatchEvent(new ShowToastEvent({ title: 'Guardado', message: 'Institución actualizada', variant: 'success' }));
        this._refreshAndReselect();
    }

    /* ── Filtros ── */
    get filterBtnClass() {
        const active = this.filterRules.some(r => r.value && String(r.value).trim());
        return 'vin-btn-filters' + (active ? ' vin-btn-filters-active' : '') + (this.showFilters ? ' vin-btn-filters-open' : '');
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
                id:              r.id,
                field:           r.field,
                op:              r.op,
                value:           r.value,
                fieldOptions:    FILTER_FIELD_DEFS.map(f => ({ value: f.value, label: f.label, selected: f.value === r.field })),
                opOptions:       ops.map(o => ({ value: o.v, label: o.l, selected: o.v === r.op })),
                isText:          def.type === 'text',
                isPicklist:      def.type === 'picklist',
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

    handleNuevo()        { this.isModalOpen = true; }
    handleModalClose()   { this.isModalOpen = false; }
    handleModalSuccess() {
        this.isModalOpen = false;
        this.isLoading   = true;
        refreshApex(this._wiredResult).then(() => { this.isLoading = false; });
        this.dispatchEvent(new ShowToastEvent({ title: 'Creada', message: 'Institución creada exitosamente', variant: 'success' }));
    }
}
