import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSeguros from '@salesforce/apex/TechPolizasController.getSeguros';
import actualizarRecibo from '@salesforce/apex/TechPolizasController.actualizarRecibo';
import getVendedores from '@salesforce/apex/TechPolizasController.getVendedores';
import actualizarVendedor from '@salesforce/apex/TechPolizasController.actualizarVendedor';
import deleteEndoso from '@salesforce/apex/TechPolizasController.deleteEndoso';

const MONEY_FMT      = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN', maximumFractionDigits: 0 });
const MONEY_FMT_FULL = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN', minimumFractionDigits: 2, maximumFractionDigits: 2 });

const TEXT_OPS_P = [
    { v: 'contains', l: 'contiene' },
    { v: 'eq',       l: 'es igual a' },
    { v: 'ne',       l: 'no es igual a' },
];
const EQ_OPS_P = [{ v: 'eq', l: 'es igual a' }, { v: 'ne', l: 'es diferente a' }];

const FILTER_DEFS_SEGUROS = [
    { value: 'name',          label: 'Póliza',       type: 'text' },
    { value: 'cliente',       label: 'Asegurado',    type: 'text' },
    { value: 'aseguradora',   label: 'Aseguradora',  type: 'text' },
    { value: 'ramo',          label: 'Ramo',         type: 'text' },
    { value: 'estatus',       label: 'Estatus',      type: 'picklist', options: ['Emitida','Activa','Por renovar','Cancelada','Vencida'] },
    { value: 'vendedorNombre',label: 'Vendedor',     type: 'text' },
];

function getOpsP(type) { return type === 'text' ? TEXT_OPS_P : EQ_OPS_P; }

function matchRulesP(item, rules) {
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

function fmtMoney(v) { return v == null ? '—' : MONEY_FMT.format(v); }

function fmtDate(s) {
    if (!s) return '—';
    const p = s.split('-');
    return p.length === 3 ? `${p[2]}/${p[1]}/${p[0]}` : s;
}

const POLIZA_STATUS_CLASS = {
    'Emitida':    'pp-badge pp-badge-blue',
    'Activa':     'pp-badge pp-badge-green',
    'Por renovar':'pp-badge pp-badge-amber',
    'Cancelada':  'pp-badge pp-badge-gray',
    'Vencida':    'pp-badge pp-badge-red',
};

const RECIBO_STATUS_CLASS = {
    'Cobrado':    'pp-badge pp-badge-green',
    'Programado': 'pp-badge pp-badge-blue',
    'Por cobrar': 'pp-badge pp-badge-amber',
    'Vencido':    'pp-badge pp-badge-red',
    'Parcial':    'pp-badge pp-badge-amber',
    'Anulado':    'pp-badge pp-badge-gray',
};

export default class TechVentasPolizas extends LightningElement {
    @track activeSubTab     = 'polizas';
    @track polizas          = [];
    @track vendedores       = [];
    @track expandedRows     = {};
    @track selectedPoliza   = null;
    @track selectedPanelTab = 'detalles';
    @track isLoading        = false;
    @track error            = null;

    @track editingCell  = null;
    @track isSavingCell = false;

    @track editingPolizaField    = null;
    @track isSavingPolizaField   = false;

    @track sortField          = '';
    @track sortDir            = 'asc';

    @track showFilters        = false;
    @track filterRules        = [];
    _filterRuleCounter        = 0;

    @track showEndosoModal  = false;
    @track editingEndosoId  = null;

    _focusRecord = null;

    @api get focusRecord() { return this._focusRecord; }
    set focusRecord(val) {
        this._focusRecord = val;
        if (!val) return;
        this._load().then(() => this._applyFocusFilter(val.numero));
    }

    _applyFocusFilter(numero) {
        if (!numero || numero === '—') return;
        this._filterRuleCounter++;
        this.filterRules = [{ id: this._filterRuleCounter, field: 'name', op: 'contains', value: numero }];
        this.showFilters = true;
    }

    connectedCallback() {
        this._load();
        getVendedores().then(data => { this.vendedores = data || []; }).catch(() => {});
    }

    async _load() {
        this.isLoading = true;
        this.error     = null;
        try {
            this.polizas = await getSeguros();
        } catch (e) {
            this.error = e?.body?.message || 'Error al cargar pólizas';
        } finally {
            this.isLoading = false;
        }
    }

    handleToggle(e) { e.stopPropagation(); this._toggle(e.currentTarget.dataset.id); }
    handlePlanToggle(e) { e.stopPropagation(); this._toggle('plan-' + e.currentTarget.dataset.id); }

    _toggle(key) {
        const next = { ...this.expandedRows };
        if (next[key]) delete next[key]; else next[key] = true;
        this.expandedRows = next;
    }

    handleRowClick(e) {
        const id = e.currentTarget.dataset.id;
        if (!id) return;
        const p = this.polizas.find(x => x.id === id);
        if (p) { this.selectedPoliza = p; this.selectedPanelTab = 'detalles'; this.editingCell = null; }
    }

    handleClosePanel() {
        this.selectedPoliza = null;
        this.editingCell    = null;
        this.editingPolizaField = null;
        this._resetEndosoModal();
    }
    get showPanel() { return this.selectedPoliza != null; }

    handleAbrirPanel(e) {
        e.stopPropagation();
        const reciboId = e.currentTarget.dataset.id;
        for (const p of (this.polizas || [])) {
            if (p.planPago?.recibos?.some(r => r.id === reciboId)) {
                this.selectedPoliza   = p;
                this.selectedPanelTab = 'plan';
                this.editingCell      = null;
                break;
            }
        }
    }

    handlePanelTab(e) {
        this.selectedPanelTab = e.currentTarget.dataset.tab;
        this.editingCell      = null;
        this.editingPolizaField = null;
        this._resetEndosoModal();
    }

    get endosoSeguroId() { return this.selectedPoliza?.id || null; }

    _resetEndosoModal() {
        this.showEndosoModal = false;
        this.editingEndosoId = null;
    }

    handleNewEndoso(e) {
        e.stopPropagation();
        this.editingEndosoId = null;
        this.showEndosoModal  = true;
    }

    handleEditEndoso(e) {
        e.stopPropagation();
        this.editingEndosoId = e.currentTarget.dataset.id;
        this.showEndosoModal  = true;
    }

    handleEndosoModalClose() { this._resetEndosoModal(); }

    async handleEndosoModalSuccess() {
        this._resetEndosoModal();
        const prevId = this.selectedPoliza.id;
        await this._load();
        this.selectedPoliza   = this.polizas.find(p => p.id === prevId) || null;
        this.selectedPanelTab = 'endosos';
    }

    async handleDeleteEndoso(e) {
        e.stopPropagation();
        const id = e.currentTarget.dataset.id;
        const en = (this.selectedPoliza?.endosos || []).find(x => x.id === id);
        if (en?.estado === 'Aplicado') {
            this.dispatchEvent(new ShowToastEvent({ title: 'No permitido', message: 'Un endoso aplicado no puede eliminarse.', variant: 'warning' }));
            return;
        }
        // eslint-disable-next-line no-alert
        if (!confirm('¿Eliminar este endoso?')) return;
        try {
            await deleteEndoso({ endosoId: id });
            const prevId = this.selectedPoliza.id;
            await this._load();
            this.selectedPoliza   = this.polizas.find(p => p.id === prevId) || null;
            this.selectedPanelTab = 'endosos';
            this.dispatchEvent(new ShowToastEvent({ title: 'Endoso eliminado', variant: 'success' }));
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err?.body?.message || 'Error al eliminar', variant: 'error' }));
        }
    }

    get isTabPolizas()     { return this.activeSubTab === 'polizas'; }
    get isTabInstitucion() { return this.activeSubTab === 'institucion'; }
    get stClassPolizas()     { return 'pp-subtab' + (this.isTabPolizas     ? ' pp-subtab-active' : ''); }
    get stClassInstitucion() { return 'pp-subtab' + (this.isTabInstitucion ? ' pp-subtab-active' : ''); }

    handlePolizasSubTab(e) { this.activeSubTab = e.currentTarget.dataset.tab; }

    get panelTabClassDetalles()  { return 'pp-ptab' + (this.selectedPanelTab === 'detalles'  ? ' pp-ptab-active' : ''); }
    get panelTabClassEndosos()   { return 'pp-ptab' + (this.selectedPanelTab === 'endosos'   ? ' pp-ptab-active' : ''); }
    get panelTabClassPlan()      { return 'pp-ptab' + (this.selectedPanelTab === 'plan'      ? ' pp-ptab-active' : ''); }
    get showPanelDetalles()      { return this.selectedPanelTab === 'detalles';  }
    get showPanelEndosos()       { return this.selectedPanelTab === 'endosos';   }
    get showPanelPlan()          { return this.selectedPanelTab === 'plan';      }

    get vendedorOptions() {
        const opts = [{ label: '— Sin asignar —', value: '' }];
        for (const v of (this.vendedores || [])) {
            opts.push({ label: v.nombre || v.id, value: v.id });
        }
        return opts;
    }

    handlePolizaPencilClick(e) {
        e.stopPropagation();
        const field = e.currentTarget.dataset.field;
        const value = e.currentTarget.dataset.value || '';
        this.editingPolizaField = { field, value };
    }

    handlePolizaFieldChange(e) {
        this.editingPolizaField = { ...this.editingPolizaField, value: e.detail.value };
    }

    handlePolizaFieldCancel(e) {
        e.stopPropagation();
        this.editingPolizaField = null;
    }

    async handlePolizaFieldSave(e) {
        e.stopPropagation();
        if (!this.editingPolizaField || !this.selectedPoliza) return;
        const { value } = this.editingPolizaField;
        this.isSavingPolizaField = true;
        try {
            await actualizarVendedor({
                polizaId:   this.selectedPoliza.id,
                tipo:       'Seguro',
                vendedorId: value || null,
            });
            this.editingPolizaField = null;
            this.dispatchEvent(new ShowToastEvent({ title: 'Guardado', message: 'Vendedor actualizado', variant: 'success' }));
            const prevId = this.selectedPoliza.id;
            await this._load();
            this.selectedPoliza = this.polizas.find(p => p.id === prevId) || null;
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err?.body?.message || 'Error al actualizar', variant: 'error' }));
        } finally {
            this.isSavingPolizaField = false;
        }
    }

    get estatusOptions() {
        return [
            { label: 'Programado',  value: 'Programado'  },
            { label: 'Por cobrar',  value: 'Por cobrar'  },
            { label: 'Cobrado',     value: 'Cobrado'     },
            { label: 'Parcial',     value: 'Parcial'     },
            { label: 'Vencido',     value: 'Vencido'     },
            { label: 'Anulado',     value: 'Anulado'     },
        ];
    }

    get metodoPagoOptions() {
        return [
            { label: '— Sin especificar —',    value: '' },
            { label: 'Efectivo',               value: 'Efectivo' },
            { label: 'Transferencia (SPEI)',    value: 'Transferencia (SPEI)' },
            { label: 'Tarjeta credito/debito', value: 'Tarjeta credito/debito' },
            { label: 'Cheque',                 value: 'Cheque' },
            { label: 'Domiciliación bancaria', value: 'Domiciliacion bancaria' },
            { label: 'Descuento vía nómina',   value: 'Descuento via nomina' },
            { label: 'Enlace de pago',         value: 'Enlace de pago' },
        ];
    }

    get motivoNoPagoOptions() {
        return [
            { label: '— Sin especificar —',    value: '' },
            { label: 'Cliente decide cancelar', value: 'Cliente decide cancelar' },
        ];
    }

    handlePencilClick(e) {
        e.stopPropagation();
        const reciboId = e.currentTarget.dataset.reciboId;
        const field    = e.currentTarget.dataset.field;
        const value    = e.currentTarget.dataset.value || '';
        this.editingCell = { reciboId, field, value };
    }

    handleCellValueChange(e) {
        this.editingCell = { ...this.editingCell, value: e.detail.value };
    }

    handleRefValueChange(e) {
        this.editingCell = { ...this.editingCell, refValue: e.detail.value };
    }

    handleCellCancel(e) {
        e.stopPropagation();
        this.editingCell = null;
    }

    async handleCellSave(e) {
        e.stopPropagation();
        if (!this.editingCell) return;
        const { reciboId, field, value, refValue } = this.editingCell;

        if (field === 'metodoPago' && value && value !== 'Efectivo') {
            if (!refValue || !refValue.trim()) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Campo requerido',
                    message: 'Debes ingresar la Referencia de pago para este método.',
                    variant: 'error'
                }));
                return;
            }
        }
        if (field === 'referenciaPago' && !value.trim()) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Campo requerido',
                message: 'La Referencia de pago no puede estar vacía.',
                variant: 'error'
            }));
            return;
        }

        this.isSavingCell = true;
        try {
            await actualizarRecibo({
                reciboId,
                estado:           field === 'estado'           ? value          : null,
                fechaPago:        field === 'fechaPago'        ? value          : null,
                fechaProgramada:  field === 'fechaProgramada'  ? value          : null,
                montoCobrado:     field === 'montoCobrado'     ? (value ? parseFloat(value)    : null) : null,
                metodoPago:       field === 'metodoPago'       ? value          : null,
                referenciaPago:   field === 'metodoPago'       ? (refValue || null)
                                : field === 'referenciaPago'   ? value          : null,
                motivoNoPago:     field === 'motivoNoPago'     ? value          : null,
                intentosContacto: field === 'intentosContacto' ? (value ? parseInt(value, 10)  : null) : null,
            });
            this.editingCell = null;
            this.dispatchEvent(new ShowToastEvent({ title: 'Guardado', message: 'Campo actualizado', variant: 'success' }));
            await this._load();
            if (this.selectedPoliza) {
                this.selectedPoliza = this.polizas.find(p => p.id === this.selectedPoliza.id) || null;
            }
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err?.body?.message || 'Verifica los datos e intenta de nuevo', variant: 'error' }));
        } finally {
            this.isSavingCell = false;
        }
    }

    get panelPoliza() {
        const p = this.selectedPoliza;
        if (!p) return null;
        const epf = this.editingPolizaField;
        return {
            ...p,
            primaFmt:         fmtMoney(p.prima),
            vigenciaInicio:   fmtDate(p.vigenciaInicio),
            vigenciaFin:      fmtDate(p.vigenciaFin),
            diasLabel:        p.diasParaVencer != null ? String(p.diasParaVencer) + ' días' : '—',
            vendedorNombre:   p.vendedorNombre || '—',
            vendedorEmail:    p.vendedorEmail  || '—',
            editVendedor:     epf?.field === 'vendedor',
            polizaFieldValue: epf?.field === 'vendedor' ? epf.value : (p.vendedorId || ''),
            isSavingVendedor: this.isSavingPolizaField,
        };
    }

    get panelEndosos() {
        const endosos = this.selectedPoliza?.endosos;
        if (!endosos?.length) return [];
        return endosos.map(e => ({
            ...e,
            fechaEfectiva:    fmtDate(e.fechaEfectiva),
            finVigenciaFmt:   fmtDate(e.finVigencia),
            nuevoMontoFmt:    e.nuevoMonto != null ? fmtMoney(e.nuevoMonto) : null,
            diferenciaMonto:  e.diferenciaMonto != null
                ? (e.diferenciaMonto >= 0 ? '+' : '') + fmtMoney(Math.abs(e.diferenciaMonto)) : '—',
            badgeClass:       e.estado === 'Aplicado' ? 'pp-badge pp-badge-green' : 'pp-badge pp-badge-gray',
            hasNuevoMonto:    e.nuevoMonto != null,
            hasConvenio:      !!e.convenioNombre,
            hasFinVigencia:   !!e.finVigencia,
            isAplicado:       e.estado === 'Aplicado',
        }));
    }

    get hasPanelEndosos() { return this.panelEndosos.length > 0; }

    get panelPlan() {
        const plan = this.selectedPoliza?.planPago;
        if (!plan) return null;
        const ec = this.editingCell;
        return {
            ...plan,
            fechaInicio: fmtDate(plan.fechaInicio),
            recibos: (plan.recibos || []).map(r => {
                const isThis = ec?.reciboId === r.id;
                const ef = isThis ? ec.field : null;
                return {
                    id:              r.id,
                    name:            r.name,
                    numero:          r.numero,
                    estado:          r.estado || '—',
                    badgeClass:      RECIBO_STATUS_CLASS[r.estado] || 'pp-badge pp-badge-gray',
                    montoFmt:        r.monto != null ? MONEY_FMT_FULL.format(r.monto) : '—',
                    montoCobradoFmt: r.montoCobrado != null ? fmtMoney(r.montoCobrado) : '—',
                    saldoFmt:        r.saldo        != null ? fmtMoney(r.saldo)        : '—',
                    fechaVencFmt:    fmtDate(r.fechaVencimiento),
                    fechaPagoFmt:    r.fechaPago ? fmtDate(r.fechaPago) : '—',
                    metodoPagoFmt:    r.metodoPago      || '—',
                    referenciaPagoFmt:r.referenciaPago  || '—',
                    intentosFmt:     r.intentosContacto != null ? String(r.intentosContacto) : '—',
                    motivoFmt:       r.motivoNoPago      || '—',
                    rawEstado:       r.estado       || '',
                    rawFechaVenc:    r.fechaVencimiento || '',
                    rawFechaPago:    r.fechaPago     || '',
                    rawMontoCobrado: r.montoCobrado != null ? String(r.montoCobrado) : '',
                    rawMetodoPago:    r.metodoPago      || '',
                    rawReferenciaPago:r.referenciaPago  || '',
                    rawIntentos:     r.intentosContacto != null ? String(r.intentosContacto) : '',
                    rawMotivo:       r.motivoNoPago     || '',
                    editEstado:       isThis && ef === 'estado',
                    editFechaProg:    isThis && ef === 'fechaProgramada',
                    editFechaPago:    isThis && ef === 'fechaPago',
                    editMonto:        isThis && ef === 'montoCobrado',
                    editMetodo:       isThis && ef === 'metodoPago',
                    editReferencia:   isThis && ef === 'referenciaPago',
                    editIntentos:     isThis && ef === 'intentosContacto',
                    editMotivo:       isThis && ef === 'motivoNoPago',
                    cellValue:        isThis ? ec.value : '',
                    refValue:         isThis ? (ec.refValue || '') : '',
                    needsReferencia:  isThis && ef === 'metodoPago' && ec.value !== 'Efectivo' && ec.value !== '',
                    showReferencia:   r.metodoPago && r.metodoPago !== 'Efectivo',
                    showFechaPago:    !!r.fechaPago,
                    isSaving:         isThis && this.isSavingCell,
                };
            }),
        };
    }

    get hasPanelPlan()   { return this.panelPlan != null; }
    get hasNoPanelPlan() { return !this.hasPanelPlan; }

    get filteredPolizas() {
        const active = this.filterRules.filter(r => r.value && String(r.value).trim());
        let result = active.length ? this.polizas.filter(p => matchRulesP(p, active)) : this.polizas;
        if (this.sortField) {
            const dir = this.sortDir === 'asc' ? 1 : -1;
            const f   = this.sortField;
            result = [...result].sort((a, b) => {
                const av = a[f] ?? ''; const bv = b[f] ?? '';
                if (typeof av === 'number' && typeof bv === 'number') return (av - bv) * dir;
                return String(av).localeCompare(String(bv)) * dir;
            });
        }
        return result;
    }

    get ppHeaders() {
        const defs = [
            { key: 'name',     field: 'name',          label: 'Póliza / Nombre',    cls: 'pp-th-name', sortable: true  },
            { key: 'cliente',  field: 'cliente',        label: 'Cliente',            cls: '',           sortable: true  },
            { key: 'aseg',     field: 'aseguradora',    label: 'Aseguradora',        cls: '',           sortable: true  },
            { key: 'ramo',     field: 'ramo',           label: 'Ramo',               cls: '',           sortable: true  },
            { key: 'prima',    field: 'prima',          label: 'Prima neta',         cls: 'pp-th-num',  sortable: true  },
            { key: 'vig',      field: 'vigenciaFin',    label: 'Vigencia fin',       cls: '',           sortable: true  },
            { key: 'dias',     field: 'diasParaVencer', label: 'Días',               cls: 'pp-th-dias', sortable: true  },
            { key: 'estatus',  field: 'estatus',        label: 'Estatus',            cls: '',           sortable: true  },
            { key: 'act',      field: '',               label: '',                   cls: 'pp-th-act',  sortable: false },
        ];
        return defs.map(h => ({
            ...h,
            thClass: (h.cls || '') + (h.sortable ? ' pp-th-sort' : '') + (this.sortField === h.field && h.field ? ' pp-th-sorted' : ''),
            icon: !h.sortable ? '' : this.sortField !== h.field ? '↕' : this.sortDir === 'asc' ? '↑' : '↓'
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

    get showTable() { return !this.isLoading && !this.error && this.polizas.length > 0; }
    get isEmpty()   { return !this.isLoading && !this.error && this.polizas.length === 0; }
    get showEmpty() { return !this.isLoading && !this.error && this.filteredPolizas.length === 0 && this.polizas.length > 0; }

    get filterBtnClass() {
        const active = this.filterRules.some(r => r.value && String(r.value).trim());
        return 'pp-btn-filters' + (active ? ' pp-btn-filters-active' : '') + (this.showFilters ? ' pp-btn-filters-open' : '');
    }
    get filterBtnLabel() {
        const count = this.filterRules.filter(r => r.value && String(r.value).trim()).length;
        return count > 0 ? `Filtros (${count})` : 'Filtros';
    }
    get hasFilterRules() { return this.filterRules.length > 0; }
    get filterRulesView() {
        return this.filterRules.map(r => {
            const defs = FILTER_DEFS_SEGUROS;
            const def  = defs.find(f => f.value === r.field) || defs[0];
            const ops  = getOpsP(def.type);
            return {
                id: r.id, field: r.field, op: r.op, value: r.value,
                fieldOptions: defs.map(f => ({ value: f.value, label: f.label, selected: f.value === r.field })),
                opOptions:    ops.map(o => ({ value: o.v, label: o.l, selected: o.v === r.op })),
                isText:       def.type === 'text',
                isPicklist:   def.type === 'picklist',
                picklistOptions: def.type === 'picklist'
                    ? (def.options || []).map(o => ({ value: o, label: o, selected: o === r.value }))
                    : [],
            };
        });
    }
    handleToggleFilters() { this.showFilters = !this.showFilters; }
    handleClearFilters()  { this.filterRules = []; }
    handleAddRule() {
        const defs = FILTER_DEFS_SEGUROS;
        const ops  = getOpsP(defs[0].type);
        this.filterRules = [...this.filterRules, { id: ++this._filterRuleCounter, field: defs[0].value, op: ops[0].v, value: '' }];
    }
    handleRemoveRule(e) {
        const id = parseInt(e.currentTarget.dataset.id, 10);
        this.filterRules = this.filterRules.filter(r => r.id !== id);
    }
    handleFilterFieldChange(e) {
        const id    = parseInt(e.currentTarget.dataset.id, 10);
        const field = e.target.value;
        const defs  = FILTER_DEFS_SEGUROS;
        const def   = defs.find(f => f.value === field) || defs[0];
        const ops   = getOpsP(def.type);
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

    get flatRows() {
        const rows = [];
        const sel  = this.selectedPoliza;

        for (const p of (this.filteredPolizas || [])) {
            const isExpanded = !!this.expandedRows[p.id];
            const days = p.diasParaVencer;
            let showRenovBadge = false, renovBadgeClass = 'pp-renov-badge';
            if (days != null && days >= 0 && days <= 90) {
                showRenovBadge = true;
                renovBadgeClass += days <= 60 ? ' pp-renov-red' : ' pp-renov-amber';
            }

            rows.push({
                rowKey: `poliza-${p.id}`, isPoliza: true, isEndoso: false, isPlan: false, isRecibo: false, isSectionHeader: false,
                id: p.id, name: p.name || '—', cliente: p.cliente || '—', aseguradora: p.aseguradora || '—',
                ramo: p.ramo || '—', primaFmt: fmtMoney(p.prima), vigenciaFin: fmtDate(p.vigenciaFin),
                diasParaVencer: days != null ? String(days) + 'd' : '—', renovDias: days, estatus: p.estatus || '—',
                isExpanded, toggleIcon: isExpanded ? 'utility:chevrondown' : 'utility:chevronright',
                showRenovBadge, renovBadgeClass,
                estatusBadgeClass: POLIZA_STATUS_CLASS[p.estatus] || 'pp-badge pp-badge-gray',
                trClass: 'pp-row pp-row-poliza' + (sel?.id === p.id ? ' pp-row-selected' : ''),
            });

            if (!isExpanded) continue;

            if (p.endosos?.length > 0) {
                rows.push({ rowKey: `endosos-hdr-${p.id}`, isSectionHeader: true, isPoliza: false, isEndoso: false, isPlan: false, isRecibo: false, sectionLabel: `Endosos (${p.endosos.length})`, trClass: 'pp-row pp-row-section-hdr' });
                for (const e of p.endosos) {
                    rows.push({
                        rowKey: `endoso-${e.id}`, isEndoso: true, isPoliza: false, isPlan: false, isRecibo: false, isSectionHeader: false,
                        id: e.id, name: e.name || '—', fechaEfectiva: fmtDate(e.fechaEfectiva),
                        diferenciaMonto: e.diferenciaMonto != null ? (e.diferenciaMonto >= 0 ? '+' : '') + fmtMoney(Math.abs(e.diferenciaMonto)) : '—',
                        estado: e.estado || '—', estadoBadgeClass: e.estado === 'Aplicado' ? 'pp-badge pp-badge-green' : 'pp-badge pp-badge-gray',
                        trClass: 'pp-row pp-row-endoso',
                    });
                }
            }

            if (p.planPago) {
                const plan = p.planPago;
                const planKey = `plan-${plan.id}`;
                const isPlanExpanded = !!this.expandedRows[planKey];
                rows.push({
                    rowKey: planKey, isPlan: true, isPoliza: false, isEndoso: false, isRecibo: false, isSectionHeader: false,
                    id: plan.id, name: plan.name || '—', metodoPago: plan.metodoPago || '—', periodoPago: plan.periodoPago || '—',
                    fechaInicio: fmtDate(plan.fechaInicio), numRecibos: plan.numRecibos != null ? String(plan.numRecibos) : '—',
                    estado: plan.estado || '—', isPlanExpanded, planToggleIcon: isPlanExpanded ? 'utility:chevrondown' : 'utility:chevronright',
                    estadoBadgeClass: plan.estado === 'Activo' ? 'pp-badge pp-badge-green' : 'pp-badge pp-badge-gray',
                    trClass: 'pp-row pp-row-plan',
                });

                if (isPlanExpanded && plan.recibos?.length > 0) {
                    for (const r of plan.recibos) {
                        rows.push({
                            rowKey: `recibo-${r.id}`, isRecibo: true, isPoliza: false, isPlan: false, isEndoso: false, isSectionHeader: false,
                            id: r.id, numero: r.numero != null ? String(r.numero) : '?',
                            montoFmt: fmtMoney(r.monto),
                            montoCobradoFmt: r.montoCobrado != null ? fmtMoney(r.montoCobrado) : null,
                            showFechaPago: !!r.fechaPago,
                            fechaPago: fmtDate(r.fechaPago), fechaVencimiento: fmtDate(r.fechaVencimiento),
                            estado: r.estado || '—', estadoBadgeClass: RECIBO_STATUS_CLASS[r.estado] || 'pp-badge pp-badge-gray',
                            showMarcarPagado: r.estado !== 'Cobrado' && r.estado !== 'Anulado',
                            trClass: 'pp-row pp-row-recibo',
                        });
                    }
                }
            }
        }
        return rows;
    }
}
