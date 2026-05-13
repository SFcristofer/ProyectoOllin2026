/**
 * cognoHubGestion - v6.1
 * ---------------------------------------------------------------------------
 * Hub operativo del Modulo de Gestion.
 *
 * Cambios respecto a v5.2:
 *   - Cada KPI apunta a una list view que coincide 1:1 con el numero
 *     que muestra. Antes habia mismatch: "Renovaciones abril" mostraba 6
 *     pero al click abria list view con abril+mayo (23). "Por cobrar"
 *     abria filterName=Todos que daba "resource does not exist".
 *   - Nuevas list views (incluidas en este paquete):
 *       Por_cobrar_pendientes    (Estado=Pendiente AND Fecha>=TODAY)
 *       Pendientes_mes_actual    (Estado=Pendiente AND Fecha in THIS_MONTH)
 *       Pagados_mes_actual       (Estado=Pagado AND Fecha_pago in THIS_MONTH)
 *       Por_renovar_mes_actual   (Estatus IN Vigente/Por renovar AND
 *                                 Fin_del_seguro in THIS_MONTH)
 *   - List views existentes que se mantienen: Recibos_vencidos,
 *     Por_renovar_30d (para el KPI de "proximos 30d" si algun dia se agrega).
 *
 * Cambios respecto a v5:
 *   - CSS propio (cognoHubGestion.css) que fuerza rojo sólido en banner y
 *     header de atrasadas porque slds-theme_error renderiza rosa pastel
 *     en SLDS 2026.
 *   - Días siempre en positivo ("hace N días" para atrasadas).
 *   - aria-labels en KPIs y botones del modal (arregla errores O11Y).
 *   - Semáforo de recibos con left-border coloreado en vez de teñir toda
 *     la fila (ilegible con el pastel de 2026).
 *
 * Cambios respecto a v4 (mantenidos):
 *   - Renovaciones vista mensual con 3 buckets: Atrasadas · Mes actual · Mes siguiente.
 *   - Banner arriba cuando hay atrasadas.
 *   - KPIs clickeables.
 *   - Modal "Marcar como no renovada" conectado al Apex marcarNoRenovada.
 *   - Patrón frozen-object (JSON.parse(JSON.stringify)).
 *
 * Autor: Ollin Proteccion - 2026-04-19 (v6.1)
 * ---------------------------------------------------------------------------
 */
import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getHubData from '@salesforce/apex/HubGestionController.getHubData';
import marcarNoRenovadaApex from '@salesforce/apex/HubGestionController.marcarNoRenovada';

// List views (API names reales verificados en sandbox el 2026-04-19).
// v6.1: cada KPI apunta a una list view que coincide 1:1 con su numero.
const LISTVIEW_RECIBOS_VENCIDOS        = 'Recibos_vencidos';
const LISTVIEW_RECIBOS_POR_COBRAR      = 'Por_cobrar_pendientes';
const LISTVIEW_RECIBOS_PENDIENTES_MES  = 'Pendientes_mes_actual';
const LISTVIEW_RECIBOS_PAGADOS_MES     = 'Pagados_mes_actual';
const LISTVIEW_SEGUROS_POR_RENOVAR_MES = 'Por_renovar_mes_actual';

export default class CognoHubGestion extends NavigationMixin(LightningElement) {
    @track kpis = {};
    @track recibosVencidos = [];
    @track renovaciones = { atrasadas: [], mesActual: [], mesSiguiente: [] };
    @track motivosNoRenovacion = [];

    @track loading = true;
    @track error;

    // Modal state
    @track showModal = false;
    @track modalSeguroId;
    @track modalPoliza;
    @track modalCliente;
    @track modalMotivo = '';
    @track saving = false;

    wiredHub;

    @wire(getHubData)
    wiredGetHubData(result) {
        this.wiredHub = result;
        const { data, error } = result;
        if (data) {
            // Clonar para evitar frozen-object TypeError al mutar
            const clone = JSON.parse(JSON.stringify(data));
            this.kpis = clone.kpis || {};
            this.recibosVencidos = (clone.recibosVencidos || []).map(r => ({
                ...r,
                rowClass: this._semaforoClass(r.semaforo)
            }));
            this.renovaciones = clone.renovaciones || { atrasadas: [], mesActual: [], mesSiguiente: [] };
            this.motivosNoRenovacion = clone.motivosNoRenovacion || [];
            this.error = undefined;
        } else if (error) {
            this.error = error.body?.message || error.message || 'No se pudo cargar el Hub';
            this.kpis = {};
            this.recibosVencidos = [];
            this.renovaciones = { atrasadas: [], mesActual: [], mesSiguiente: [] };
        }
        this.loading = false;
    }

    /* ===================== Getters para el template ===================== */

    get hasAtrasadas() {
        return (this.kpis?.atrasadasCount ?? 0) > 0;
    }

    get bannerText() {
        const n = this.kpis?.atrasadasCount ?? 0;
        const monto = this._fmtMxn(this.kpis?.atrasadasAmount);
        return `${n} póliza${n === 1 ? '' : 's'} vencida${n === 1 ? '' : 's'} sin renovar — ${monto}`;
    }

    get mesActualLabel() {
        const d = new Date();
        return d.toLocaleString('es-MX', { month: 'long', year: 'numeric' });
    }

    get mesSiguienteLabel() {
        const d = new Date();
        d.setMonth(d.getMonth() + 1);
        return d.toLocaleString('es-MX', { month: 'long', year: 'numeric' });
    }

    get motivoOptions() {
        return (this.motivosNoRenovacion || []).map(m => ({ label: m.label, value: m.value }));
    }

    get saveDisabled() {
        return this.saving || !this.modalMotivo;
    }

    /* ===================== KPIs clickeables ===================== */

    handleKpiVencidos()          { this._navigateToRecibos(LISTVIEW_RECIBOS_VENCIDOS); }
    handleKpiPorCobrar()         { this._navigateToRecibos(LISTVIEW_RECIBOS_POR_COBRAR); }
    handleKpiPagadoMes()         { this._navigateToRecibos(LISTVIEW_RECIBOS_PAGADOS_MES); }
    handleKpiRenovaciones()      { this._navigateToSeguros(LISTVIEW_SEGUROS_POR_RENOVAR_MES); }
    handleKpiPendienteMes()      { this._navigateToRecibos(LISTVIEW_RECIBOS_PENDIENTES_MES); }

    _navigateToRecibos(filter) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: 'Recibo_de_Cobro__c', actionName: 'list' },
            state: { filterName: filter }
        });
    }

    _navigateToSeguros(filter) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: 'Seguro__c', actionName: 'list' },
            state: { filterName: filter }
        });
    }

    handleRowNav(event) {
        const recordId = event.currentTarget.dataset.id;
        const objectApiName = event.currentTarget.dataset.object || 'Seguro__c';
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId, objectApiName, actionName: 'view' }
        });
    }

    /* ===================== Modal marcar no renovada ===================== */

    openMarcarNoRenovada(event) {
        const id = event.currentTarget.dataset.id;
        const poliza = event.currentTarget.dataset.poliza;
        const cliente = event.currentTarget.dataset.cliente;
        this.modalSeguroId = id;
        this.modalPoliza = poliza;
        this.modalCliente = cliente;
        this.modalMotivo = '';
        this.showModal = true;
    }

    closeModal() {
        if (this.saving) return;
        this.showModal = false;
        this.modalSeguroId = null;
        this.modalPoliza = null;
        this.modalCliente = null;
        this.modalMotivo = '';
    }

    handleMotivoChange(event) {
        this.modalMotivo = event.detail.value;
    }

    async handleGuardarNoRenovada() {
        if (!this.modalSeguroId || !this.modalMotivo) return;
        this.saving = true;
        try {
            await marcarNoRenovadaApex({ seguroId: this.modalSeguroId, motivo: this.modalMotivo });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Póliza marcada como no renovada',
                message: `${this.modalPoliza} · ${this.modalCliente}`,
                variant: 'success'
            }));
            this.showModal = false;
            this.modalSeguroId = null;
            this.modalPoliza = null;
            this.modalCliente = null;
            this.modalMotivo = '';
            await refreshApex(this.wiredHub);
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error al marcar como no renovada',
                message: e.body?.message || e.message || 'Error desconocido',
                variant: 'error'
            }));
        } finally {
            this.saving = false;
        }
    }

    /* ===================== Utils ===================== */

    _semaforoClass(sem) {
        // Usamos left-border coloreado (definido en cognoHubGestion.css)
        // en vez de slds-theme_error (pastel, ilegible en 2026).
        if (sem === 'rojo')     return 'semaforo-rojo';
        if (sem === 'amarillo') return 'semaforo-amarillo';
        if (sem === 'naranja')  return 'semaforo-naranja';
        return '';
    }

    _fmtMxn(n) {
        if (n == null) return '$0';
        try {
            return new Intl.NumberFormat('es-MX', {
                style: 'currency', currency: 'MXN', maximumFractionDigits: 0
            }).format(n);
        } catch (e) {
            return `$${n}`;
        }
    }
}