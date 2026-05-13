import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getGestionData from '@salesforce/apex/TechGestionController.getGestionData';
import marcarNoRenovada from '@salesforce/apex/TechGestionController.marcarNoRenovada';

const TIPO_LABEL = { seguro: '🛡 Seguro', fianza: '⚖ Fianza' };

export default class TechGestion extends NavigationMixin(LightningElement) {
    @track kpis               = {};
    @track recibosVencidos    = [];
    @track recibosPorCobrar   = [];
    @track recibosCobradosMes = [];
    @track recibosPendientesMes = [];
    @track renovaciones       = { atrasadas: [], mesActual: [], mesSiguiente: [] };
    @track loading            = true;
    @track error;

    @track showModal    = false;
    @track modalSeguroId;
    @track modalPoliza;
    @track modalCliente;
    @track saving       = false;

    // ── Panel KPI ─────────────────────────────────────────────────────────────
    @track activeKpiPanel = null;

    // ── Filtros ──────────────────────────────────────────────────────────────
    @track filterTipo = 'todos';
    @track filterRamo = '';

    _wiredResult;

    @wire(getGestionData)
    wiredData(result) {
        this._wiredResult = result;
        const { data, error } = result;
        if (data) {
            const d = JSON.parse(JSON.stringify(data));
            this.kpis            = d.kpis || {};
            this.renovaciones    = d.renovaciones || { atrasadas: [], mesActual: [], mesSiguiente: [] };
            const mapRow = (r, i) => ({ ...r, rowNum: i + 1, rowClass: 'tg-grid-row tg-grid-data ' + (r.semaforoClass || ''), tipoLabel: TIPO_LABEL[r.tipo] || r.tipo });
            this.recibosPorCobrar    = (d.recibosPorCobrar    || []).map(mapRow);
            this.recibosCobradosMes  = (d.recibosCobradosMes  || []).map(mapRow);
            this.recibosPendientesMes = (d.recibosPendientesMes || []).map(mapRow);
            this.recibosVencidos = (d.recibosVencidos || []).map((r, i) => ({
                ...r,
                rowNum   : i + 1,
                rowClass : 'tg-grid-row tg-grid-data ' + (r.semaforoClass || ''),
                tipoLabel: TIPO_LABEL[r.tipo] || r.tipo
            }));
            ['atrasadas', 'mesActual', 'mesSiguiente'].forEach(bucket => {
                this.renovaciones[bucket] = (this.renovaciones[bucket] || []).map((s, i) => ({
                    ...s,
                    rowNum   : i + 1,
                    tipoLabel: TIPO_LABEL[s.tipo] || s.tipo
                }));
            });
            this.error = undefined;
        } else if (error) {
            this.error = error.body?.message || error.message || 'Error al cargar datos';
        }
        this.loading = false;
    }

    // ── Getters base (sin filtro — para banner y lógica interna) ─────────────

    get hasAtrasadas()    { return (this.renovaciones?.atrasadas?.length  ?? 0) > 0; }
    get hasMesActual()    { return (this.renovaciones?.mesActual?.length   ?? 0) > 0; }
    get hasMesSiguiente() { return (this.renovaciones?.mesSiguiente?.length ?? 0) > 0; }

    get bannerText() {
        const n = this.kpis?.atrasadasCount ?? 0;
        return `${n} póliza${n === 1 ? '' : 's'} vencida${n === 1 ? '' : 's'} sin renovar — ${this.kpis?.atrasadasAmountFmt ?? '$0'}`;
    }

    get mesActualLabel()    { return new Date().toLocaleString('es-MX', { month: 'long', year: 'numeric' }); }
    get mesSiguienteLabel() {
        const d = new Date(); d.setMonth(d.getMonth() + 1);
        return d.toLocaleString('es-MX', { month: 'long', year: 'numeric' });
    }

    get saveLabel() { return this.saving ? 'Guardando...' : 'Confirmar'; }

    // ── Filtros ──────────────────────────────────────────────────────────────

    get tipoOptions() {
        return [
            { value: 'todos',   label: 'Todos los tipos',  selected: this.filterTipo === 'todos'   },
            { value: 'seguro',  label: '🛡 Solo seguros',  selected: this.filterTipo === 'seguro'  },
            { value: 'fianza',  label: '⚖ Solo fianzas',   selected: this.filterTipo === 'fianza'  }
        ];
    }

    get ramosOptions() {
        const allRows = [
            ...this.recibosVencidos,
            ...(this.renovaciones?.atrasadas    || []),
            ...(this.renovaciones?.mesActual    || []),
            ...(this.renovaciones?.mesSiguiente || [])
        ];
        const unique = [...new Set(allRows.map(r => r.ramo).filter(r => r && r !== '—'))].sort();
        return unique.map(v => ({ value: v, label: v, selected: v === this.filterRamo }));
    }

    get isFiltered() { return this.filterTipo !== 'todos' || this.filterRamo !== ''; }

    handleFilterTipo(e)  { this.filterTipo = e.target.value; }
    handleFilterRamo(e)  { this.filterRamo = e.target.value; }
    handleClearFilters() { this.filterTipo = 'todos'; this.filterRamo = ''; }

    _matches(row) {
        if (this.filterTipo !== 'todos' && row.tipo !== this.filterTipo) return false;
        if (this.filterRamo && row.ramo !== this.filterRamo) return false;
        return true;
    }

    get filteredRecibos() {
        return this.recibosVencidos
            .filter(r => this._matches(r))
            .map((r, i) => ({ ...r, rowNum: i + 1 }));
    }

    get filteredAtrasadas()    { return (this.renovaciones?.atrasadas    || []).filter(r => this._matches(r)).map((r,i) => ({...r, rowNum: i+1})); }
    get filteredMesActual()    { return (this.renovaciones?.mesActual    || []).filter(r => this._matches(r)).map((r,i) => ({...r, rowNum: i+1})); }
    get filteredMesSiguiente() { return (this.renovaciones?.mesSiguiente || []).filter(r => this._matches(r)).map((r,i) => ({...r, rowNum: i+1})); }

    get hasFilteredRecibos()      { return this.filteredRecibos.length > 0; }
    get hasFilteredAtrasadas()    { return this.filteredAtrasadas.length > 0; }
    get hasFilteredMesActual()    { return this.filteredMesActual.length > 0; }
    get hasFilteredMesSiguiente() { return this.filteredMesSiguiente.length > 0; }
    get hasFilteredRenovaciones() {
        return this.hasFilteredAtrasadas || this.hasFilteredMesActual || this.hasFilteredMesSiguiente;
    }

    get emptyRecibosMsg() {
        return this.isFiltered ? 'Sin recibos vencidos con los filtros actuales' : 'Sin recibos vencidos';
    }
    get emptyRenovMsg() {
        return this.isFiltered
            ? 'Sin pólizas/fianzas por renovar con los filtros actuales'
            : 'Sin pólizas por renovar en los próximos 2 meses';
    }

    // ── KPI — panel expandible ───────────────────────────────────────────────

    handleKpiVencidos()     { this._togglePanel('vencidos'); }
    handleKpiPorCobrar()    { this._togglePanel('porCobrar'); }
    handleKpiCobradoMes()   { this._togglePanel('cobradoMes'); }
    handleKpiPendienteMes() { this._togglePanel('pendienteMes'); }
    handleKpiRenovaciones() {
        const el = this.template.querySelector('.tg-section');
        if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }

    _togglePanel(key) { this.activeKpiPanel = this.activeKpiPanel === key ? null : key; }
    closeKpiDrawer()  { this.activeKpiPanel = null; }

    get showKpiDrawer() { return this.activeKpiPanel != null; }

    get _drawerCfg() {
        const cfgs = {
            vencidos:     { title: 'Recibos vencidos',     fechaLabel: 'Fecha programada', rows: this.recibosVencidos,     usaMora: true  },
            porCobrar:    { title: 'Por cobrar',            fechaLabel: 'Fecha programada', rows: this.recibosPorCobrar,    usaMora: false },
            cobradoMes:   { title: 'Cobrado este mes',      fechaLabel: 'Fecha pago',       rows: this.recibosCobradosMes,  usaMora: false },
            pendienteMes: { title: 'Pendiente del mes',     fechaLabel: 'Fecha programada', rows: this.recibosPendientesMes, usaMora: false },
        };
        return cfgs[this.activeKpiPanel] || {};
    }

    get kpiDrawerTitle()      { return this._drawerCfg.title      || ''; }
    get kpiDrawerFechaLabel() { return this._drawerCfg.fechaLabel || 'Fecha'; }
    get kpiDrawerUsaMora()    { return this._drawerCfg.usaMora    === true; }
    get kpiDrawerRowClass()   { return 'tg-grid-row tg-drawer-row' + (this.kpiDrawerUsaMora ? ' tg-drawer-mora' : ''); }
    get kpiDrawerHeadClass()  { return 'tg-grid-row tg-grid-header tg-drawer-row' + (this.kpiDrawerUsaMora ? ' tg-drawer-mora' : ''); }
    get kpiDrawerRows() {
        return (this._drawerCfg.rows || []).map((r, i) => ({ ...r, rowNum: i + 1 }));
    }
    get kpiDrawerEmpty()  { return this.kpiDrawerRows.length === 0; }
    get kpiDrawerCount()  { return this.kpiDrawerRows.length; }

    _kpiCardClass(key, extra) {
        const active = this.activeKpiPanel === key ? ' tg-kpi-active' : '';
        return 'tg-kpi-card' + (extra ? ' ' + extra : '') + active;
    }
    get kpiCardVencidos()    { return this._kpiCardClass('vencidos',     'tg-kpi-danger'); }
    get kpiCardPorCobrar()   { return this._kpiCardClass('porCobrar',    ''); }
    get kpiCardCobradoMes()  { return this._kpiCardClass('cobradoMes',   'tg-kpi-success'); }
    get kpiCardPendiente()   { return this._kpiCardClass('pendienteMes', ''); }
    get kpiCardRenovaciones(){ return 'tg-kpi-card tg-kpi-warn'; }

    handleRowNav(event) {
        const id     = event.currentTarget.dataset.id;
        const tipo   = event.currentTarget.dataset.tipo;
        const numero = event.currentTarget.dataset.numero;
        if (!id) return;
        event.stopPropagation();

        if (tipo === 'seguro' || tipo === 'fianza') {
            this.dispatchEvent(new CustomEvent('navigateinternal', {
                detail: { id, tipo, numero },
                bubbles: true,
                composed: true
            }));
            return;
        }
        // Recibos vencidos: navegar al registro
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: id, objectApiName: 'Tech_Recibo_Pago__c', actionName: 'view' }
        });
    }

    scrollToAtrasadas() {
        const el = this.template.querySelector('[data-bucket="atrasadas"]');
        if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }

    // ── Modal marcar no renovada ─────────────────────────────────────────────

    openModal(event) {
        this.modalSeguroId = event.currentTarget.dataset.id;
        this.modalPoliza   = event.currentTarget.dataset.poliza;
        this.modalCliente  = event.currentTarget.dataset.cliente;
        this.showModal     = true;
    }

    closeModal() {
        if (this.saving) return;
        this.showModal = false; this.modalSeguroId = null;
        this.modalPoliza = null; this.modalCliente = null;
    }

    async handleConfirmarNoRenovada() {
        if (!this.modalSeguroId) return;
        this.saving = true;
        try {
            await marcarNoRenovada({ seguroId: this.modalSeguroId });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Marcada como no renovada',
                message: `${this.modalPoliza} · ${this.modalCliente}`,
                variant: 'success'
            }));
            this.showModal = false; this.modalSeguroId = null;
            this.modalPoliza = null; this.modalCliente = null;
            await refreshApex(this._wiredResult);
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: e.body?.message || e.message || 'Error desconocido',
                variant: 'error'
            }));
        } finally {
            this.saving = false;
        }
    }
}
