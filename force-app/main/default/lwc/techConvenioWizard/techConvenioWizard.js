import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import crearConvenioConEndosos from '@salesforce/apex/TechConvenioController.crearConvenioConEndosos';
import getFianzasByContrato    from '@salesforce/apex/TechContratoController.getFianzasByContrato';
import getContratoMonto        from '@salesforce/apex/TechContratoController.getContratoMonto';
import searchContratosForFianza from '@salesforce/apex/TechFianzaController.searchContratosForFianza';

const MONEY = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN', maximumFractionDigits: 0 });
const fmt = v => v == null || isNaN(v) ? '—' : MONEY.format(Number(v));

export default class TechConvenioWizard extends LightningElement {
    @track step    = 1;
    @track isSaving = false;
    _initDone = false;

    @api
    set initialContrato(val) {
        if (val && val.id && !this._initDone) {
            this._initDone = true;
            this.convenioData = { ...this.convenioData, contratoId: val.id, contratoNombre: val.name || '' };
            this.contratoSeleccionado = true;
        }
    }
    get initialContrato() { return null; }

    @track convenioData = {
        contratoId: '', contratoNombre: '',
        tipo: '', fecha: '', nuevoValor: '', nuevaFechaFin: '', descripcion: '',
        tipoAmpliacionMonto: false, tipoAmpliacionPlazo: false,
        tipoCambioAlcance: false, tipoReduccion: false,
    };

    @track contratoBusqueda   = '';
    @track resultadosContrato = [];
    @track contratoSeleccionado = false;
    _searchTimer = null;

    @track fianzasContrato = [];
    @track loadingFianzas  = false;

    // ── Steps ────────────────────────────────────────────────────────────────────

    get isStep1() { return this.step === 1; }
    get isStep2() { return this.step === 2; }
    get isStep3() { return this.step === 3; }

    get stepClass1() { return 'wz-step' + (this.step >= 1 ? ' wz-step-active' : '') + (this.step > 1 ? ' wz-step-done' : ''); }
    get stepClass2() { return 'wz-step' + (this.step >= 2 ? ' wz-step-active' : '') + (this.step > 2 ? ' wz-step-done' : ''); }
    get stepClass3() { return 'wz-step' + (this.step === 3 ? ' wz-step-active' : ''); }

    get showBtnBack() { return this.step > 1; }

    get isNextDisabled() {
        if (this.step === 1) return !this.convenioData.contratoId || !this.convenioData.tipo || !this.convenioData.fecha;
        if (this.step === 2) return !this.endososSeleccionados.length || this.endososSeleccionados.some(e => !e.tipoEndoso);
        return false;
    }

    async handleNext() {
        if (this.step === 1 && this.convenioData.contratoId) {
            this.step = 2;
            await this._loadFianzas();
        } else if (this.step < 3) {
            this.step++;
        }
    }

    handleBack() {
        if (this.step > 1) this.step--;
    }

    async _loadFianzas() {
        this.loadingFianzas = true;
        try {
            const [raw, contratoInfo] = await Promise.all([
                getFianzasByContrato({ contratoId: this.convenioData.contratoId }),
                getContratoMonto({ contratoId: this.convenioData.contratoId }),
            ]);

            const montoContratoActual = (contratoInfo && contratoInfo.montoVigente) ? Number(contratoInfo.montoVigente) : 0;
            const nuevoValor          = parseFloat(this.convenioData.nuevoValor) || 0;
            const nuevaFechaFin       = this.convenioData.nuevaFechaFin || null;
            const tipoConvenio        = this.convenioData.tipo || '';

            const afectaMonto = nuevoValor > 0 && montoContratoActual > 0 && nuevoValor !== montoContratoActual;
            const factorMonto = afectaMonto ? nuevoValor / montoContratoActual : 1;

            this.fianzasContrato = (raw || []).map(f => {
                const primaActual          = f.primaVigente  != null ? Number(f.primaVigente)  : (f.primaNeta  != null ? Number(f.primaNeta)  : 0);
                const montoAfianzadoActual = f.montoVigente  != null ? Number(f.montoVigente)  : (f.monto      != null ? Number(f.monto)      : 0);
                const fechaVigente         = f.fechaVencimientoVig || f.fechaVencimiento || '';

                let nuevaPrima         = primaActual;
                let nuevoMontoAfianzado = montoAfianzadoActual;

                if (afectaMonto) {
                    nuevaPrima          = Math.round(primaActual          * factorMonto * 100) / 100;
                    nuevoMontoAfianzado = Math.round(montoAfianzadoActual * factorMonto * 100) / 100;
                }

                const afectaPrima    = nuevaPrima !== primaActual;
                const afectaVigencia = nuevaFechaFin != null && nuevaFechaFin !== '' && nuevaFechaFin !== fechaVigente;
                const selected       = afectaPrima || afectaVigencia;

                let tipoEndoso = '';
                if (selected) {
                    if (tipoConvenio === 'Ampliación de monto') {
                        tipoEndoso = afectaPrima ? 'Aumento monto' : 'Extensión vigencia';
                    } else if (tipoConvenio === 'Reducción') {
                        tipoEndoso = afectaPrima ? 'Reducción monto' : 'Extensión vigencia';
                    } else if (tipoConvenio === 'Ampliación de plazo') {
                        tipoEndoso = 'Extensión vigencia';
                    } else {
                        tipoEndoso = (afectaVigencia && !afectaPrima) ? 'Extensión vigencia' : 'Cambio de prima';
                    }
                }

                return {
                    id: f.id || f.Id, name: f.name || f.Name || '—',
                    tipoRiesgo: f.tipoRiesgo || '—',
                    montoVigente: montoAfianzadoActual,
                    montoVigenteFmt: fmt(montoAfianzadoActual),
                    fechaVencimientoVig: fechaVigente || '—',
                    selected,
                    cardClass:  'wz-fz-card'  + (selected ? ' wz-fz-card-selected'  : ''),
                    checkClass: 'wz-fz-check' + (selected ? ' wz-fz-check-active'   : ''),
                    tipoEndoso,
                    nuevoMonto:            (selected && afectaMonto)    ? String(nuevoMontoAfianzado) : '',
                    nuevaPrima:            (selected && afectaPrima)    ? String(nuevaPrima)          : '',
                    nuevaFechaVencimiento: (selected && afectaVigencia) ? nuevaFechaFin               : '',
                    tipoEndosoAumento:   tipoEndoso === 'Aumento monto',
                    tipoEndosoReduccion: tipoEndoso === 'Reducción monto',
                    tipoEndosoPrima:     tipoEndoso === 'Cambio de prima',
                    tipoEndosoExtension: tipoEndoso === 'Extensión vigencia',
                    tipoEndosoBenef:     tipoEndoso === 'Cambio datos',
                };
            });
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err?.body?.message || 'Error al cargar fianzas', variant: 'error' }));
        } finally {
            this.loadingFianzas = false;
        }
    }

    // ── Close ────────────────────────────────────────────────────────────────────

    handleClose() { this.dispatchEvent(new CustomEvent('close')); }
    handleOverlayClick() { this.handleClose(); }
    stopProp(e) { e.stopPropagation(); }

    // ── Contrato lookup ──────────────────────────────────────────────────────────

    handleBuscarContrato(e) {
        const kw = e.target.value;
        this.contratoBusqueda = kw;
        clearTimeout(this._searchTimer);
        if (!kw || kw.length < 2) { this.resultadosContrato = []; return; }
        this._searchTimer = setTimeout(async () => {
            try {
                const res = await searchContratosForFianza({ term: kw });
                this.resultadosContrato = res || [];
            } catch (err) { this.resultadosContrato = []; }
        }, 300);
    }

    handleSelectContrato(e) {
        e.stopPropagation();
        const id   = e.currentTarget.dataset.id;
        const name = e.currentTarget.dataset.name;
        this.convenioData = { ...this.convenioData, contratoId: id, contratoNombre: name };
        this.resultadosContrato  = [];
        this.contratoBusqueda    = '';
        this.contratoSeleccionado = true;
    }

    handleClearContrato(e) {
        e.stopPropagation();
        this.convenioData = { ...this.convenioData, contratoId: '', contratoNombre: '' };
        this.contratoSeleccionado = false;
        this.fianzasContrato = [];
    }

    // ── Convenio fields ──────────────────────────────────────────────────────────

    get tipoAmpliacionMonto() { return this.convenioData.tipo === 'Ampliación de monto'; }
    get tipoAmpliacionPlazo() { return this.convenioData.tipo === 'Ampliación de plazo'; }
    get tipoCambioAlcance()   { return this.convenioData.tipo === 'Cambio de alcance'; }
    get tipoReduccion()       { return this.convenioData.tipo === 'Reducción'; }

    handleConvenioField(e) {
        const field = e.currentTarget.dataset.field;
        this.convenioData = { ...this.convenioData, [field]: e.target.value };
    }

    get showDiferencia() { return !!this.convenioData.nuevoValor; }

    get diferenciaMostrar() {
        const nv = parseFloat(this.convenioData.nuevoValor) || 0;
        if (!nv) return '';
        return (nv >= 0 ? '+' : '') + fmt(nv);
    }

    get diferenciaClass() {
        const nv = parseFloat(this.convenioData.nuevoValor) || 0;
        return nv >= 0 ? 'wz-diff-pos' : 'wz-diff-neg';
    }

    get nuevoValorFmt() { return fmt(this.convenioData.nuevoValor); }

    // ── Fianza toggle ────────────────────────────────────────────────────────────

    handleToggleFianza(e) {
        const id = e.currentTarget.dataset.id;
        this.fianzasContrato = this.fianzasContrato.map(f => {
            if (f.id !== id) return f;
            const selected = !f.selected;
            return {
                ...f, selected,
                cardClass:  'wz-fz-card' + (selected ? ' wz-fz-card-selected' : ''),
                checkClass: 'wz-fz-check' + (selected ? ' wz-fz-check-active' : ''),
            };
        });
    }

    handleEndosoField(e) {
        e.stopPropagation();
        const id    = e.currentTarget.dataset.id;
        const field = e.currentTarget.dataset.field;
        const value = e.target.value;
        this.fianzasContrato = this.fianzasContrato.map(f => {
            if (f.id !== id) return f;
            const updated = { ...f, [field]: value };
            if (field === 'tipoEndoso') {
                updated.tipoEndosoAumento   = value === 'Aumento monto';
                updated.tipoEndosoReduccion = value === 'Reducción monto';
                updated.tipoEndosoPrima     = value === 'Cambio de prima';
                updated.tipoEndosoExtension = value === 'Extensión vigencia';
                updated.tipoEndosoBenef     = value === 'Cambio datos';
            }
            return updated;
        });
    }

    get endososSeleccionados() {
        return this.fianzasContrato
            .filter(f => f.selected)
            .map(f => ({
                ...f,
                nuevoMontoFmt: fmt(f.nuevoMonto),
            }));
    }

    // ── Save ─────────────────────────────────────────────────────────────────────

    async handleSave() {
        this.isSaving = true;
        try {
            const convenioPayload = {
                contratoId:    this.convenioData.contratoId    || null,
                tipo:          this.convenioData.tipo          || null,
                fecha:         this.convenioData.fecha         || null,
                nuevoValor:    this.convenioData.nuevoValor    ? parseFloat(this.convenioData.nuevoValor) : null,
                nuevaFechaFin: this.convenioData.nuevaFechaFin || null,
                descripcion:   this.convenioData.descripcion   || null,
            };
            const endososPayload = this.endososSeleccionados.map(f => ({
                fianzaId:              f.id,
                tipoEndoso:            f.tipoEndoso            || null,
                nuevoMonto:            f.nuevoMonto            ? parseFloat(f.nuevoMonto)    : null,
                nuevaPrima:            f.nuevaPrima            ? parseFloat(f.nuevaPrima)    : null,
                nuevaFechaVencimiento: f.nuevaFechaVencimiento || null,
            }));
            await crearConvenioConEndosos({ convenioData: convenioPayload, endososData: endososPayload });
            this.dispatchEvent(new CustomEvent('success'));
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err?.body?.message || 'Error al guardar', variant: 'error' }));
        } finally {
            this.isSaving = false;
        }
    }
}
