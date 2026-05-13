import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import getFianzasList        from '@salesforce/apex/TechFianzaController.getFianzasList';
import getSubmodulosFianza   from '@salesforce/apex/TechFianzaController.getSubmodulosFianza';
import guardarEndoso         from '@salesforce/apex/TechFianzaController.guardarEndoso';
import eliminarEndoso        from '@salesforce/apex/TechFianzaController.eliminarEndoso';
import guardarComision       from '@salesforce/apex/TechFianzaController.guardarComision';
import eliminarComision      from '@salesforce/apex/TechFianzaController.eliminarComision';
import guardarPlan           from '@salesforce/apex/TechFianzaController.guardarPlan';
import eliminarPlan          from '@salesforce/apex/TechFianzaController.eliminarPlan';
import guardarRecibo         from '@salesforce/apex/TechFianzaController.guardarRecibo';
import eliminarRecibo        from '@salesforce/apex/TechFianzaController.eliminarRecibo';
import marcarReciboCobrado   from '@salesforce/apex/TechFianzaController.marcarReciboCobrado';

const MONEY = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN', maximumFractionDigits: 0 });
function fmt(v)  { return v == null ? '—' : MONEY.format(v); }
function fmtD(s) {
    if (!s) return '—';
    const p = String(s).split('-');
    return p.length === 3 ? `${p[2]}/${p[1]}/${p[0]}` : String(s);
}

const ESTATUS_FIANZA   = { 'Vigente': 'tfi-badge tfi-badge-green', 'Emitida': 'tfi-badge tfi-badge-blue', 'Cancelada': 'tfi-badge tfi-badge-gray', 'Vencida': 'tfi-badge tfi-badge-red', 'Reclamada': 'tfi-badge tfi-badge-red' };
const ESTATUS_ENDOSO   = { 'Aplicado': 'tfi-badge tfi-badge-green', 'Aprobado': 'tfi-badge tfi-badge-blue', 'En revisión': 'tfi-badge tfi-badge-orange', 'Rechazado': 'tfi-badge tfi-badge-red', 'Borrador': 'tfi-badge tfi-badge-gray' };
const ESTATUS_PLAN     = { 'Activo': 'tfi-badge tfi-badge-green', 'En mora': 'tfi-badge tfi-badge-red', 'Cerrado': 'tfi-badge tfi-badge-gray' };
const ESTATUS_RECIBO   = { 'Cobrado': 'tfi-badge tfi-badge-green', 'Vencido': 'tfi-badge tfi-badge-red', 'Parcial': 'tfi-badge tfi-badge-orange', 'Anulado': 'tfi-badge tfi-badge-gray', 'Programado': 'tfi-badge tfi-badge-blue', 'Por cobrar': 'tfi-badge tfi-badge-amber' };
const ESTATUS_COMISION = { 'Pagada': 'tfi-badge tfi-badge-green', 'Liberada': 'tfi-badge tfi-badge-blue', 'Revertida': 'tfi-badge tfi-badge-red', 'Devengada': 'tfi-badge tfi-badge-orange' };

export default class TechVentasFianzaTab extends LightningElement {
    @track fianzas       = [];
    @track expanded      = {};
    @track planExpanded  = {};
    @track _subCache     = {};

    @track selectedId      = null;
    @track panelTab        = 'detalles';

    @track isLoading       = false;
    @track error           = null;

    @track filterText      = '';
    @track sortField       = '';
    @track sortDir         = 'asc';

    // ── Fianza edit (Detalles tab) ─────────────────────────────────────────────
    @track isEditingFianza = false;
    @track fianzaEdit      = {};
    @track isSavingFianza  = false;

    // ── Endoso modal ───────────────────────────────────────────────────────────
    @track showEndosoModal  = false;
    @track endosoEdit       = {};
    @track isSavingEndoso   = false;

    // ── Comision modal ─────────────────────────────────────────────────────────
    @track showComisionModal = false;
    @track comisionEdit      = {};
    @track isSavingComision  = false;

    // ── Plan modal ─────────────────────────────────────────────────────────────
    @track showPlanModal     = false;
    @track planEdit          = {};
    @track isSavingPlan      = false;

    // ── Recibo modal ───────────────────────────────────────────────────────────
    @track showReciboModal   = false;
    @track reciboEdit        = {};
    @track isSavingRecibo    = false;

    // ── Cobro inline ───────────────────────────────────────────────────────────
    @track cobroEdit         = null; // { reciboId, monto, fecha }
    @track isSavingCobro     = false;

    connectedCallback() { this._load(); }

    async _load() {
        this.isLoading = true;
        this.error     = null;
        try {
            this.fianzas = await getFianzasList();
        } catch (e) {
            this.error = e?.body?.message || 'Error al cargar fianzas';
        } finally {
            this.isLoading = false;
        }
    }

    async _loadSub(fianzaId) {
        if (this._subCache[fianzaId]) return;
        try {
            const sub = await getSubmodulosFianza({ fianzaId });
            this._subCache = { ...this._subCache, [fianzaId]: sub };
        } catch (_e) { /* silent */ }
    }

    async _reloadSub(fianzaId) {
        const next = { ...this._subCache };
        delete next[fianzaId];
        this._subCache = next;
        await this._loadSub(fianzaId);
    }

    // ── Accordion ────────────────────────────────────────────────────────────────

    async handleToggle(e) {
        e.stopPropagation();
        const id   = e.currentTarget.dataset.id;
        const next = { ...this.expanded };
        if (next[id]) { delete next[id]; } else { next[id] = true; await this._loadSub(id); }
        this.expanded = next;
    }

    handlePlanToggle(e) {
        e.stopPropagation();
        const key  = 'plan-' + e.currentTarget.dataset.id;
        const next = { ...this.planExpanded };
        if (next[key]) delete next[key]; else next[key] = true;
        this.planExpanded = next;
    }

    // ── Row click / panel ────────────────────────────────────────────────────────

    async handleRowClick(e) {
        const id = e.currentTarget.dataset.id;
        if (!id) return;
        if (this.selectedId === id) { this.selectedId = null; return; }
        this.selectedId      = id;
        this.panelTab        = 'detalles';
        this.cobroEdit       = null;
        this.isEditingFianza = false;
        await this._loadSub(id);
    }

    handleClosePanel() {
        this.selectedId        = null;
        this.cobroEdit         = null;
        this.isEditingFianza   = false;
        this.showEndosoModal   = false;
        this.showComisionModal = false;
        this.showPlanModal     = false;
        this.showReciboModal   = false;
    }

    get showPanel()  { return !!this.selectedId; }
    get panelFianza(){ return this.fianzas.find(f => f.id === this.selectedId) || null; }
    get panelSub()   { return this._subCache[this.selectedId] || null; }

    // ── Panel tabs ───────────────────────────────────────────────────────────────

    handlePanelTab(e) {
        this.panelTab        = e.currentTarget.dataset.tab;
        this.cobroEdit       = null;
        this.isEditingFianza = false;
    }

    get ptClsDetalles()   { return 'tfi-ptab' + (this.panelTab === 'detalles'   ? ' tfi-ptab-active' : ''); }
    get ptClsEndosos()    { return 'tfi-ptab' + (this.panelTab === 'endosos'    ? ' tfi-ptab-active' : ''); }
    get ptClsPlanes()     { return 'tfi-ptab' + (this.panelTab === 'planes'     ? ' tfi-ptab-active' : ''); }
    get ptClsComisiones() { return 'tfi-ptab' + (this.panelTab === 'comisiones' ? ' tfi-ptab-active' : ''); }

    get showPtDetalles()   { return this.panelTab === 'detalles'; }
    get showPtEndosos()    { return this.panelTab === 'endosos'; }
    get showPtPlanes()     { return this.panelTab === 'planes'; }
    get showPtComisiones() { return this.panelTab === 'comisiones'; }

    // ── Fianza edit ──────────────────────────────────────────────────────────────

    handleEditFianza() {
        const f = this.panelFianza;
        if (!f) return;
        this.fianzaEdit = {
            tipoRiesgo:       f.tipoRiesgo           || '',
            estatus:          f.estatus               || '',
            monto:            f.monto        != null  ? String(f.monto)        : '',
            primaNeta:        f.primaNeta    != null  ? String(f.primaNeta)    : '',
            fechaEmision:     f.fechaEmision != null  ? String(f.fechaEmision)    : '',
            fechaVencimiento: f.fechaVencimiento != null ? String(f.fechaVencimiento) : '',
        };
        this.isEditingFianza = true;
    }

    handleCancelFianzaEdit() { this.isEditingFianza = false; this.fianzaEdit = {}; }

    handleFianzaEditField(e) {
        const field = e.currentTarget.dataset.field;
        this.fianzaEdit = { ...this.fianzaEdit, [field]: e.target.value };
    }

    async handleSaveFianza() {
        this.isSavingFianza = true;
        try {
            const ed     = this.fianzaEdit;
            const fields = { Id: this.selectedId };
            if (ed.tipoRiesgo)       fields['Tipo_de_Riesgo__c']        = ed.tipoRiesgo;
            if (ed.estatus)          fields['Estatus__c']               = ed.estatus;
            if (ed.monto)            fields['Monto_Afianzado__c']       = parseFloat(ed.monto);
            if (ed.primaNeta)        fields['Prima_neta__c']            = parseFloat(ed.primaNeta);
            if (ed.fechaEmision)     fields['Fecha_de_Emision__c']      = ed.fechaEmision;
            if (ed.fechaVencimiento) fields['Fecha_de_Vencimiento__c']  = ed.fechaVencimiento;
            await updateRecord({ fields });
            this.isEditingFianza = false;
            this.fianzaEdit      = {};
            await this._load();
            this.dispatchEvent(new ShowToastEvent({ title: 'Fianza actualizada', variant: 'success' }));
        } catch (err) {
            const msg = err?.body?.output?.errors?.[0]?.message || err?.body?.message || 'Error al guardar';
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: msg, variant: 'error' }));
        } finally {
            this.isSavingFianza = false;
        }
    }

    // ── Panel data getters ───────────────────────────────────────────────────────

    get panelDetails() {
        const f = this.panelFianza;
        if (!f) return [];
        return [
            { key: 'name',        label: 'Fianza',         value: f.name },
            { key: 'tipoRiesgo',  label: 'Tipo de riesgo', value: f.tipoRiesgo || '—' },
            { key: 'contratista', label: 'Contratista',    value: (f.contratistas || []).join(', ') || '—' },
            { key: 'beneficiario',label: 'Beneficiario',   value: f.beneficiario || '—' },
            { key: 'institucion', label: 'Institución',    value: f.institucion  || '—' },
            { key: 'monto',       label: 'Monto original', value: fmt(f.monto),        isMoney: true },
            { key: 'montoVig',    label: 'Monto vigente',  value: fmt(f.montoVigente), isMoney: true },
            { key: 'prima',       label: 'Prima neta',     value: fmt(f.primaNeta),    isMoney: true },
            { key: 'primaVig',    label: 'Prima vigente',  value: fmt(f.primaVigente), isMoney: true },
            { key: 'emision',     label: 'Fecha emisión',  value: fmtD(f.fechaEmision  ? String(f.fechaEmision)  : null) },
            { key: 'vencimiento', label: 'Vencimiento',    value: fmtD(f.fechaVencimiento ? String(f.fechaVencimiento) : null) },
            { key: 'estatus',     label: 'Estatus',        value: f.estatus, isBadge: true, badgeClass: ESTATUS_FIANZA[f.estatus] || 'tfi-badge tfi-badge-gray' },
        ];
    }

    get panelEndosos() {
        const sub = this.panelSub;
        if (!sub?.endosos?.length) return [];
        return sub.endosos.map(e => ({
            ...e,
            fechaEfectivaFmt: fmtD(e.fechaEfectiva),
            finVigenciaFmt:   fmtD(e.finVigencia),
            nuevoMontoFmt:    e.nuevoMonto != null ? fmt(e.nuevoMonto)  : null,
            nuevaPrimaFmt:    e.nuevaPrima != null ? fmt(e.nuevaPrima)  : null,
            diferenciaMonto:  e.diferenciaMonto != null ? (e.diferenciaMonto >= 0 ? '+' : '') + fmt(Math.abs(e.diferenciaMonto)) : '—',
            estadoClass:      ESTATUS_ENDOSO[e.estado] || 'tfi-badge tfi-badge-gray',
            hasNuevoMonto:    e.nuevoMonto != null,
            hasNuevaPrima:    e.nuevaPrima != null,
            hasFinVigencia:   !!e.finVigencia,
            hasConvenio:      !!e.convenio,
        }));
    }
    get hasPanelEndosos() { return this.panelEndosos.length > 0; }

    get panelPlanes() {
        const sub = this.panelSub;
        if (!sub?.planes?.length) return [];
        return sub.planes.map(pl => ({
            ...pl,
            estatusClass:  ESTATUS_PLAN[pl.estatus] || 'tfi-badge tfi-badge-gray',
            montoTotalFmt: fmt(pl.montoTotal),
            recibos: (pl.recibos || []).map(r => {
                const isCobro = this.cobroEdit?.reciboId === r.id;
                return {
                    ...r,
                    estadoClass:   ESTATUS_RECIBO[r.estado] || 'tfi-badge tfi-badge-gray',
                    montoProgFmt:  fmt(r.montoProg),
                    montoCobFmt:   r.montoCob != null ? fmt(r.montoCob) : null,
                    isCobrado:     r.estado === 'Cobrado' || r.estado === 'Anulado',
                    isCobroEdit:   isCobro,
                    cobroMonto:    isCobro ? this.cobroEdit.monto : '',
                    cobroFecha:    isCobro ? this.cobroEdit.fecha : '',
                    isSavingCobro: isCobro && this.isSavingCobro,
                };
            }),
        }));
    }
    get hasPanelPlanes() { return this.panelPlanes.length > 0; }

    get panelComisiones() {
        const sub = this.panelSub;
        if (!sub?.comisiones?.length) return [];
        return sub.comisiones.map(c => ({
            ...c,
            estatusClass:     ESTATUS_COMISION[c.estatus] || 'tfi-badge tfi-badge-orange',
            montoOllinFmt:    fmt(c.montoOllin),
            montoVendedorFmt: fmt(c.montoVendedor),
        }));
    }
    get hasPanelComisiones() { return this.panelComisiones.length > 0; }

    get panelTotales() {
        const sub = this.panelSub;
        if (!sub) return null;
        return { ollinFmt: fmt(sub.totalOllin), vendedorFmt: fmt(sub.totalVendedor) };
    }

    // ── Flat rows (accordion) ────────────────────────────────────────────────────

    get filteredFianzas() {
        let list = this.fianzas;
        if (this.filterText?.trim()) {
            const q = this.filterText.toLowerCase();
            list = list.filter(f =>
                (f.name || '').toLowerCase().includes(q) ||
                (f.tipoRiesgo || '').toLowerCase().includes(q) ||
                ((f.contratistas || []).join(' ')).toLowerCase().includes(q) ||
                (f.estatus || '').toLowerCase().includes(q)
            );
        }
        if (this.sortField) {
            const dir = this.sortDir === 'asc' ? 1 : -1;
            const sf  = this.sortField;
            list = [...list].sort((a, b) => {
                const av = a[sf] ?? ''; const bv = b[sf] ?? '';
                if (typeof av === 'number' && typeof bv === 'number') return (av - bv) * dir;
                return String(av).localeCompare(String(bv)) * dir;
            });
        }
        return list;
    }

    get flatRows() {
        const rows = [];
        for (const f of (this.filteredFianzas || [])) {
            const isExpanded = !!this.expanded[f.id];
            const isSelected = f.id === this.selectedId;
            rows.push({
                rowKey: `fianza-${f.id}`,
                isFianza: true, isEndoso: false, isPlan: false, isRecibo: false, isSectionHeader: false,
                id: f.id, name: f.name || '—',
                tipoRiesgo:      f.tipoRiesgo || '—',
                contratista:     (f.contratistas || []).join(', ') || '—',
                institucion:     f.institucion || '—',
                montoFmt:        fmt(f.monto),
                montoVigenteFmt: fmt(f.montoVigente),
                primaNetaFmt:    fmt(f.primaNeta),
                fechaVencimiento: fmtD(f.fechaVencimiento ? String(f.fechaVencimiento) : null),
                estatus:         f.estatus || '—',
                estatusClass:    ESTATUS_FIANZA[f.estatus] || 'tfi-badge tfi-badge-gray',
                isExpanded,
                toggleIcon: isExpanded ? 'utility:chevrondown' : 'utility:chevronright',
                trClass: 'tfi-row tfi-row-fianza' + (isSelected ? ' tfi-row-selected' : ''),
            });
            if (!isExpanded) continue;
            const sub = this._subCache[f.id];
            if (!sub) {
                rows.push({ rowKey: `loading-${f.id}`, isSectionHeader: true, isFianza: false, isEndoso: false, isPlan: false, isRecibo: false, sectionLabel: 'Cargando...', trClass: 'tfi-row tfi-row-section-hdr' });
                continue;
            }
            if (sub.endosos?.length) {
                rows.push({ rowKey: `end-hdr-${f.id}`, isSectionHeader: true, isFianza: false, isEndoso: false, isPlan: false, isRecibo: false, sectionLabel: `Endosos (${sub.endosos.length})`, trClass: 'tfi-row tfi-row-section-hdr' });
                for (const en of sub.endosos) {
                    rows.push({ rowKey: `endoso-${en.id}`, isEndoso: true, isFianza: false, isPlan: false, isRecibo: false, isSectionHeader: false, id: en.id, name: en.name || '—', tipo: en.tipo || '—', estado: en.estado || '—', estadoClass: ESTATUS_ENDOSO[en.estado] || 'tfi-badge tfi-badge-gray', fechaEfectiva: fmtD(en.fechaEfectiva), diferenciaMonto: en.diferenciaMonto != null ? (en.diferenciaMonto >= 0 ? '+' : '') + fmt(Math.abs(en.diferenciaMonto)) : '—', trClass: 'tfi-row tfi-row-endoso' });
                }
            }
            if (sub.planes?.length) {
                rows.push({ rowKey: `plan-hdr-${f.id}`, isSectionHeader: true, isFianza: false, isEndoso: false, isPlan: false, isRecibo: false, sectionLabel: `Planes de pago (${sub.planes.length})`, trClass: 'tfi-row tfi-row-section-hdr' });
                for (const pl of sub.planes) {
                    const planKey        = 'plan-' + pl.id;
                    const isPlanExpanded = !!this.planExpanded[planKey];
                    rows.push({ rowKey: planKey, isPlan: true, isFianza: false, isEndoso: false, isRecibo: false, isSectionHeader: false, id: pl.id, name: pl.name || '—', periodo: pl.periodo || '—', metodo: pl.metodo || '—', numRecibos: pl.numRecibos || '—', estatus: pl.estatus || '—', estatusClass: ESTATUS_PLAN[pl.estatus] || 'tfi-badge tfi-badge-gray', isPlanExpanded, planToggleIcon: isPlanExpanded ? 'utility:chevrondown' : 'utility:chevronright', trClass: 'tfi-row tfi-row-plan' });
                    if (isPlanExpanded && pl.recibos?.length) {
                        for (const r of pl.recibos) {
                            rows.push({ rowKey: `recibo-${r.id}`, isRecibo: true, isFianza: false, isPlan: false, isEndoso: false, isSectionHeader: false, id: r.id, numero: r.numero || '—', estado: r.estado || '—', estadoClass: ESTATUS_RECIBO[r.estado] || 'tfi-badge tfi-badge-gray', fechaProg: r.fechaProg || '—', montoProgFmt: fmt(r.montoProg), trClass: 'tfi-row tfi-row-recibo' });
                        }
                    }
                }
            }
            if (!sub.endosos?.length && !sub.planes?.length) {
                rows.push({ rowKey: `empty-${f.id}`, isSectionHeader: true, isFianza: false, isEndoso: false, isPlan: false, isRecibo: false, sectionLabel: 'Sin endosos ni planes de pago', trClass: 'tfi-row tfi-row-section-hdr tfi-row-empty' });
            }
        }
        return rows;
    }

    get showTable()  { return !this.isLoading && !this.error && this.fianzas.length > 0; }
    get isEmpty()    { return !this.isLoading && !this.error && this.fianzas.length === 0; }
    get hasError()   { return !this.isLoading && !!this.error; }

    handleSort(e) {
        const field = e.currentTarget.dataset.field;
        if (!field) return;
        if (this.sortField === field) this.sortDir = this.sortDir === 'asc' ? 'desc' : 'asc';
        else { this.sortField = field; this.sortDir = 'asc'; }
    }
    handleFilterInput(e) { this.filterText = e.target.value; }
    stopProp(e) { e.stopPropagation(); }

    // ── Endoso modal ─────────────────────────────────────────────────────────────

    handleNewEndoso(e) {
        e.stopPropagation();
        this.endosoEdit      = { fianzaId: this.selectedId, tipo: 'Aumento monto', estado: 'Borrador', fechaEfectiva: '', finVigencia: '', nuevoMonto: '', nuevaPrima: '', motivo: '', observaciones: '' };
        this.showEndosoModal = true;
    }

    handleEditEndoso(e) {
        e.stopPropagation();
        const en = (this.panelSub?.endosos || []).find(x => x.id === e.currentTarget.dataset.id);
        if (!en) return;
        this.endosoEdit = { id: en.id, fianzaId: this.selectedId, tipo: en.tipo || 'Aumento monto', estado: en.estado || 'Borrador', fechaEfectiva: en.fechaEfectiva || '', finVigencia: en.finVigencia || '', nuevoMonto: en.nuevoMonto != null ? String(en.nuevoMonto) : '', nuevaPrima: en.nuevaPrima != null ? String(en.nuevaPrima) : '', motivo: en.motivo || '', observaciones: en.observaciones || '' };
        this.showEndosoModal = true;
    }

    handleEndosoField(e) {
        this.endosoEdit = { ...this.endosoEdit, [e.currentTarget.dataset.field]: e.target.value };
    }
    handleCloseEndosoModal() { this.showEndosoModal = false; this.endosoEdit = {}; }

    async handleSaveEndoso() {
        this.isSavingEndoso = true;
        try {
            const d    = this.endosoEdit;
            const data = { fianzaId: d.fianzaId, tipo: d.tipo, estado: d.estado, motivo: d.motivo || null, observaciones: d.observaciones || null, fechaEfectiva: d.fechaEfectiva || null, finVigencia: d.finVigencia || null, nuevoMonto: d.nuevoMonto ? parseFloat(d.nuevoMonto) : null, nuevaPrima: d.nuevaPrima ? parseFloat(d.nuevaPrima) : null };
            if (d.id) data.id = d.id;
            await guardarEndoso({ data });
            await this._reloadSub(d.fianzaId);
            this.showEndosoModal = false;
            this.endosoEdit      = {};
            this.dispatchEvent(new ShowToastEvent({ title: d.id ? 'Endoso actualizado' : 'Endoso creado', variant: 'success' }));
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err?.body?.message || 'Error al guardar endoso', variant: 'error' }));
        } finally {
            this.isSavingEndoso = false;
        }
    }

    async handleDeleteEndoso(e) {
        e.stopPropagation();
        const id = e.currentTarget.dataset.id;
        const en = (this.panelSub?.endosos || []).find(x => x.id === id);
        if (en?.isAplicado) { this.dispatchEvent(new ShowToastEvent({ title: 'No permitido', message: 'Un endoso aplicado no puede eliminarse.', variant: 'warning' })); return; }
        // eslint-disable-next-line no-alert
        if (!confirm('¿Eliminar este endoso?')) return;
        try {
            await eliminarEndoso({ endosoId: id });
            await this._reloadSub(this.selectedId);
            this.dispatchEvent(new ShowToastEvent({ title: 'Endoso eliminado', variant: 'success' }));
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err?.body?.message || 'Error', variant: 'error' }));
        }
    }

    get tipoEndosoOptions() {
        const cur = this.endosoEdit?.tipo || '';
        return ['Aumento monto', 'Reducción monto', 'Extensión vigencia', 'Cambio de prima', 'Cambio datos'].map(v => ({ value: v, label: v, isSelected: v === cur }));
    }
    get estadoEndosoOptions() {
        const cur = this.endosoEdit?.estado || '';
        return ['Borrador', 'En revisión', 'Aprobado', 'Rechazado', 'Aplicado'].map(v => ({ value: v, label: v, isSelected: v === cur }));
    }

    // ── Comision modal ───────────────────────────────────────────────────────────

    handleNewComision(e) {
        e.stopPropagation();
        this.comisionEdit     = { fianzaId: this.selectedId, estatus: 'Devengada', pct: '', montoOllin: '', montoVendedor: '' };
        this.showComisionModal = true;
    }

    handleEditComision(e) {
        e.stopPropagation();
        const c = (this.panelSub?.comisiones || []).find(x => x.id === e.currentTarget.dataset.id);
        if (!c) return;
        this.comisionEdit     = { id: c.id, fianzaId: this.selectedId, estatus: c.estatus || 'Devengada', pct: c.montoOllin != null ? String(c.pct || '').replace('%', '') : '', montoOllin: c.montoOllin != null ? String(c.montoOllin) : '', montoVendedor: c.montoVendedor != null ? String(c.montoVendedor) : '' };
        this.showComisionModal = true;
    }

    async handleDeleteComision(e) {
        e.stopPropagation();
        const id = e.currentTarget.dataset.id;
        // eslint-disable-next-line no-alert
        if (!confirm('¿Eliminar esta comisión?')) return;
        try {
            await eliminarComision({ comisionId: id });
            await this._reloadSub(this.selectedId);
            this.dispatchEvent(new ShowToastEvent({ title: 'Comisión eliminada', variant: 'success' }));
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err?.body?.message || 'Error', variant: 'error' }));
        }
    }

    handleComisionField(e) {
        this.comisionEdit = { ...this.comisionEdit, [e.currentTarget.dataset.field]: e.target.value };
    }
    handleCloseComisionModal() { this.showComisionModal = false; this.comisionEdit = {}; }

    async handleSaveComision() {
        this.isSavingComision = true;
        try {
            const d    = this.comisionEdit;
            const data = { fianzaId: d.fianzaId, estatus: d.estatus, pct: d.pct ? parseFloat(d.pct) : null, montoOllin: d.montoOllin ? parseFloat(d.montoOllin) : null, montoVend: d.montoVendedor ? parseFloat(d.montoVendedor) : null };
            if (d.id) data.id = d.id;
            await guardarComision({ data });
            await this._reloadSub(d.fianzaId);
            this.showComisionModal = false;
            this.comisionEdit      = {};
            this.dispatchEvent(new ShowToastEvent({ title: d.id ? 'Comisión actualizada' : 'Comisión guardada', variant: 'success' }));
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err?.body?.message || 'Error', variant: 'error' }));
        } finally {
            this.isSavingComision = false;
        }
    }

    get estatusComisionOptions() {
        const cur = this.comisionEdit?.estatus || '';
        return ['Devengada', 'Liberada', 'Pagada', 'Revertida'].map(v => ({ value: v, label: v, isSelected: v === cur }));
    }

    // ── Plan modal ───────────────────────────────────────────────────────────────

    handleNewPlan(e) {
        e.stopPropagation();
        this.planEdit    = { fianzaId: this.selectedId, estatus: 'Activo', periodo: '', metodo: '', fechaInicio: '', montoTotal: '', numRecibos: '' };
        this.showPlanModal = true;
    }

    handleEditPlan(e) {
        e.stopPropagation();
        const pl = (this.panelSub?.planes || []).find(x => x.id === e.currentTarget.dataset.id);
        if (!pl) return;
        this.planEdit = { id: pl.id, fianzaId: this.selectedId, estatus: pl.estatus || 'Activo', periodo: pl.periodo || '', metodo: pl.metodo || '', fechaInicio: pl.fechaInicio || '', montoTotal: pl.montoTotal != null ? String(pl.montoTotal) : '', numRecibos: pl.numRecibos || '' };
        this.showPlanModal = true;
    }

    async handleDeletePlan(e) {
        e.stopPropagation();
        const id = e.currentTarget.dataset.id;
        // eslint-disable-next-line no-alert
        if (!confirm('¿Eliminar este plan de pago y todos sus recibos?')) return;
        try {
            await eliminarPlan({ planId: id });
            await this._reloadSub(this.selectedId);
            this.dispatchEvent(new ShowToastEvent({ title: 'Plan eliminado', variant: 'success' }));
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err?.body?.message || 'Error', variant: 'error' }));
        }
    }

    handlePlanField(e) {
        this.planEdit = { ...this.planEdit, [e.currentTarget.dataset.field]: e.target.value };
    }
    handleClosePlanModal() { this.showPlanModal = false; this.planEdit = {}; }

    async handleSavePlan() {
        this.isSavingPlan = true;
        try {
            const d    = this.planEdit;
            const data = { fianzaId: d.fianzaId, estatus: d.estatus, periodo: d.periodo || null, metodo: d.metodo || null, fechaInicio: d.fechaInicio || null, montoTotal: d.montoTotal ? parseFloat(d.montoTotal) : null, numRecibos: d.numRecibos ? parseFloat(d.numRecibos) : null };
            if (d.id) data.id = d.id;
            await guardarPlan({ data });
            await this._reloadSub(d.fianzaId);
            this.showPlanModal = false;
            this.planEdit      = {};
            this.dispatchEvent(new ShowToastEvent({ title: d.id ? 'Plan actualizado' : 'Plan creado', variant: 'success' }));
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err?.body?.message || 'Error', variant: 'error' }));
        } finally {
            this.isSavingPlan = false;
        }
    }

    get estatusPlanOptions() {
        const cur = this.planEdit?.estatus || '';
        return ['Activo', 'En mora', 'Cerrado'].map(v => ({ value: v, label: v, isSelected: v === cur }));
    }
    get periodoPlanOptions() {
        const cur = this.planEdit?.periodo || '';
        return ['Contado', 'Mensual', 'Trimestral', 'Semestral', 'Anual'].map(v => ({ value: v, label: v, isSelected: v === cur }));
    }
    get metodoPlanOptions() {
        const cur = this.planEdit?.metodo || '';
        return ['Transferencia (SPEI)', 'Tarjeta credito/debito', 'Efectivo', 'Cheque', 'Domiciliacion bancaria', 'Descuento via nomina', 'Enlace de pago']
            .map(v => ({ value: v, label: v, isSelected: v === cur }));
    }

    // ── Recibo modal ─────────────────────────────────────────────────────────────

    handleNewRecibo(e) {
        e.stopPropagation();
        const planId = e.currentTarget.dataset.planid;
        this.reciboEdit    = { planId, estado: 'Programado', numero: '', fechaProg: '', montoProg: '' };
        this.showReciboModal = true;
    }

    handleEditRecibo(e) {
        e.stopPropagation();
        const id = e.currentTarget.dataset.id;
        const planId = e.currentTarget.dataset.planid;
        const pl = (this.panelSub?.planes || []).find(x => x.id === planId);
        const r  = (pl?.recibos || []).find(x => x.id === id);
        if (!r) return;
        this.reciboEdit    = { id: r.id, planId, estado: r.estado || 'Programado', numero: r.numero || '', fechaProg: r.fechaProg || '', montoProg: r.montoProg != null ? String(r.montoProg) : '' };
        this.showReciboModal = true;
    }

    async handleDeleteRecibo(e) {
        e.stopPropagation();
        const id = e.currentTarget.dataset.id;
        // eslint-disable-next-line no-alert
        if (!confirm('¿Eliminar este recibo?')) return;
        try {
            await eliminarRecibo({ reciboId: id });
            await this._reloadSub(this.selectedId);
            this.dispatchEvent(new ShowToastEvent({ title: 'Recibo eliminado', variant: 'success' }));
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err?.body?.message || 'Error', variant: 'error' }));
        }
    }

    handleReciboField(e) {
        this.reciboEdit = { ...this.reciboEdit, [e.currentTarget.dataset.field]: e.target.value };
    }
    handleCloseReciboModal() { this.showReciboModal = false; this.reciboEdit = {}; }

    async handleSaveRecibo() {
        this.isSavingRecibo = true;
        try {
            const d    = this.reciboEdit;
            const data = { planId: d.planId, estado: d.estado, numero: d.numero ? parseFloat(d.numero) : null, fechaProg: d.fechaProg || null, montoProg: d.montoProg ? parseFloat(d.montoProg) : null };
            if (d.id) data.id = d.id;
            await guardarRecibo({ data });
            await this._reloadSub(this.selectedId);
            this.showReciboModal = false;
            this.reciboEdit      = {};
            this.dispatchEvent(new ShowToastEvent({ title: d.id ? 'Recibo actualizado' : 'Recibo creado', variant: 'success' }));
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err?.body?.message || 'Error', variant: 'error' }));
        } finally {
            this.isSavingRecibo = false;
        }
    }

    get estadoReciboOptions() {
        const cur = this.reciboEdit?.estado || '';
        return ['Programado', 'Por cobrar', 'Cobrado', 'Parcial', 'Vencido', 'Anulado'].map(v => ({ value: v, label: v, isSelected: v === cur }));
    }

    // ── Cobro inline ─────────────────────────────────────────────────────────────

    handleIniciarCobro(e) {
        e.stopPropagation();
        this.cobroEdit = { reciboId: e.currentTarget.dataset.id, monto: '', fecha: '' };
    }
    handleCancelCobro(e) { e.stopPropagation(); this.cobroEdit = null; }
    handleCobroField(e) {
        this.cobroEdit = { ...this.cobroEdit, [e.currentTarget.dataset.field]: e.target.value };
    }

    async handleSaveCobro(e) {
        e.stopPropagation();
        if (!this.cobroEdit) return;
        this.isSavingCobro = true;
        try {
            const { reciboId, monto, fecha } = this.cobroEdit;
            await marcarReciboCobrado({ reciboId, montoCobrado: monto ? parseFloat(monto) : 0, fechaPago: fecha || null });
            this.cobroEdit = null;
            await this._reloadSub(this.selectedId);
            this.dispatchEvent(new ShowToastEvent({ title: 'Cobro registrado', variant: 'success' }));
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err?.body?.message || 'Error', variant: 'error' }));
        } finally {
            this.isSavingCobro = false;
        }
    }

    // ── Edit form options ────────────────────────────────────────────────────────

    get tipoRiesgoOptions() {
        const cur = this.fianzaEdit?.tipoRiesgo || '';
        return ['Cumplimiento', 'Anticipo', 'Vicios y Defectos Ocultos', 'Pasivos Laborales', 'Otro'].map(v => ({ value: v, label: v, isSelected: v === cur }));
    }
    get estatusFianzaOptions() {
        const cur = this.fianzaEdit?.estatus || '';
        return ['Emitida', 'Vigente', 'Vencida', 'Cancelada', 'Reclamada'].map(v => ({ value: v, label: v, isSelected: v === cur }));
    }

    // ── Headers ──────────────────────────────────────────────────────────────────

    get headers() {
        const defs = [
            { key: 'tog',  field: '',                 label: '',              cls: 'tfi-th-tog',  sortable: false },
            { key: 'name', field: 'name',             label: 'Fianza',        cls: 'tfi-th-name', sortable: true  },
            { key: 'tipo', field: 'tipoRiesgo',       label: 'Tipo riesgo',   cls: '',            sortable: true  },
            { key: 'cont', field: 'contratista',      label: 'Contratista',   cls: '',            sortable: true  },
            { key: 'inst', field: 'institucion',      label: 'Institución',   cls: '',            sortable: true  },
            { key: 'mon',  field: 'monto',            label: 'Monto orig.',   cls: 'tfi-th-num',  sortable: true  },
            { key: 'vig',  field: 'montoVigente',     label: 'Monto vig.',    cls: 'tfi-th-num',  sortable: true  },
            { key: 'prim', field: 'primaNeta',        label: 'Prima neta',    cls: 'tfi-th-num',  sortable: true  },
            { key: 'venc', field: 'fechaVencimiento', label: 'Vencimiento',   cls: '',            sortable: true  },
            { key: 'est',  field: 'estatus',          label: 'Estatus',       cls: '',            sortable: true  },
        ];
        return defs.map(h => ({
            ...h,
            thClass: 'tfi-th ' + (h.cls || '') + (h.sortable ? ' tfi-th-sort' : '') + (this.sortField === h.field && h.field ? ' tfi-th-sorted' : ''),
            icon: h.sortable ? (this.sortField !== h.field ? '↕' : this.sortDir === 'asc' ? '↑' : '↓') : '',
        }));
    }
}
