import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import crearContratoConFianzas      from '@salesforce/apex/TechContratoController.crearContratoConFianzas';
import actualizarContratoConFianzas from '@salesforce/apex/TechContratoController.actualizarContratoConFianzas';
import searchContratistas           from '@salesforce/apex/TechFianzaController.searchContratistas';
import searchAfianzadoras           from '@salesforce/apex/TechFianzaController.searchAfianzadoras';
import searchBeneficiarios          from '@salesforce/apex/TechFianzaController.searchBeneficiarios';
import getPrecalificacionesByContratista from '@salesforce/apex/TechPrecalificacionController.getPrecalificacionesByContratista';

const MONEY = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN', maximumFractionDigits: 0 });
const fmt = v => v == null || isNaN(v) ? '—' : MONEY.format(Number(v));

let _keyCounter = 0;
const newFianza = num => ({
    _key: ++_keyCounter, _num: num,
    tipoRiesgo: '', monto: '', primaNeta: '', fechaEmision: '', fechaVencimiento: '',
    tipoRiesgoCumplimiento: false, tipoRiesgoAnticipo: false, tipoRiesgoVicios: false,
    tipoRiesgoPasivos: false, tipoRiesgoOtro: false,
});

export default class TechFianzaWizard extends LightningElement {
    @track step     = 1;
    @track isSaving = false;

    _editMode    = false;
    _contratoId  = null;
    _initialized = false;
    _fianzasInit = false;

    @api
    set initialContrato(val) {
        if (val && val.id && !this._initialized) {
            this._initialized = true;
            this._editMode    = true;
            this._contratoId  = val.id;
            this.contratoData = {
                contratistaId:         val.contratistaId         || '',
                contratistaNombre:     val.contratistaNombre     || '',
                institucionId:         val.institucionId         || '',
                institucionNombre:     val.institucionNombre     || '',
                beneficiarioId:        val.beneficiarioId        || '',
                beneficiarioNombre:    val.beneficiarioNombre    || '',
                valorContrato:         val.valorContrato         || '',
                startDate:             val.startDate             || '',
                endDate:               val.endDate               || '',
                proyecto:              val.proyecto              || '',
                precalificacionId:     val.precalificacionId     || '',
                precalificacionNombre: val.precalificacionNombre || '',
            };
        }
    }
    get initialContrato() { return null; }

    @api
    set initialFianzas(val) {
        if (val && val.length > 0 && !this._fianzasInit) {
            this._fianzasInit = true;
            this.fianzas = val.map((f, i) => ({
                _key:    ++_keyCounter,
                _num:    i + 1,
                _existingId:          f.id              || null,
                tipoRiesgo:           f.tipoRiesgo      || '',
                monto:                f.monto      != null ? String(f.monto)     : '',
                primaNeta:            f.primaNeta  != null ? String(f.primaNeta) : '',
                fechaEmision:         f.fechaEmision     || '',
                fechaVencimiento:     f.fechaVencimiento || '',
                tipoRiesgoCumplimiento: f.tipoRiesgo === 'Cumplimiento',
                tipoRiesgoAnticipo:     f.tipoRiesgo === 'Anticipo',
                tipoRiesgoVicios:       f.tipoRiesgo === 'Vicios y Defectos Ocultos',
                tipoRiesgoPasivos:      f.tipoRiesgo === 'Pasivos Laborales',
                tipoRiesgoOtro:         f.tipoRiesgo === 'Otro',
            }));
        }
    }
    get initialFianzas() { return null; }

    get isEditMode()   { return this._editMode; }
    get wizardTitle()  { return this._editMode ? 'Editar Contrato + Fianzas' : 'Nuevo Contrato + Fianzas'; }
    get wizardSub()    { return this._editMode ? 'Modifica el contrato y agrega o edita sus fianzas' : 'Crea el contrato y sus fianzas asociadas en un solo flujo'; }
    get saveBtnLabel() { return (this._editMode ? 'Actualizar' : 'Crear') + ' Contrato y ' + this.fianzasCount + ' Fianza(s)'; }

    @track contratoData = (() => {
        const hoy = new Date();
        const pad = n => String(n).padStart(2, '0');
        const iso = d => `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())}`;
        const unAnio = new Date(hoy); unAnio.setFullYear(unAnio.getFullYear() + 1);
        return {
            contratistaId: '', contratistaNombre: '',
            institucionId: '', institucionNombre: '',
            beneficiarioId: '', beneficiarioNombre: '',
            valorContrato: '', startDate: iso(hoy), endDate: iso(unAnio), proyecto: '',
            precalificacionId: '', precalificacionNombre: '',
        };
    })();

    @track fianzas = [newFianza(1)];

    // Lookup state
    @track contratistaBusqueda    = '';
    @track resultadosContratista  = [];
    @track institucionBusqueda    = '';
    @track resultadosInstitucion  = [];
    @track beneficiarioBusqueda   = '';
    @track resultadosBeneficiario = [];
    _searchTimers = {};
    _blurTimer    = null;

    // Precalificación state
    @track precalificaciones        = [];
    @track precalificacionLoading   = false;
    @track showPrecalificacionModal = false;

    // ── Steps ────────────────────────────────────────────────────────────────────

    get isStep1() { return this.step === 1; }
    get isStep2() { return this.step === 2; }
    get isStep3() { return this.step === 3; }
    get isStep4() { return this.step === 4; }

    get stepClass1() { return 'wz-step' + (this.step >= 1 ? ' wz-step-active' : '') + (this.step > 1 ? ' wz-step-done' : ''); }
    get stepClass2() { return 'wz-step' + (this.step >= 2 ? ' wz-step-active' : '') + (this.step > 2 ? ' wz-step-done' : ''); }
    get stepClass3() { return 'wz-step' + (this.step >= 3 ? ' wz-step-active' : '') + (this.step > 3 ? ' wz-step-done' : ''); }
    get stepClass4() { return 'wz-step' + (this.step === 4 ? ' wz-step-active' : ''); }

    get showBtnBack() { return this.step > 1; }

    get isNextDisabled() {
        if (this.step === 1) {
            const c = this.contratoData;
            return !c.contratistaId || !c.institucionId || !c.valorContrato || !c.startDate || !c.endDate;
        }
        if (this.step === 3) {
            return this.fianzas.some(f => !f.tipoRiesgo || !f.monto);
        }
        return false;
    }

    get hasPrecalificaciones() { return this.precalificaciones.length > 0; }

    handleNext() {
        if (this.step === 1 && this.contratoData.contratistaId) {
            this._loadPrecalificaciones(this.contratoData.contratistaId);
        }
        if (this.step === 2 && !this._fianzasInit) {
            this._precargarFianzas();
        }
        if (this.step < 4) this.step++;
    }

    _addMonths(isoDate, months) {
        if (!isoDate) return '';
        const d = new Date(isoDate + 'T00:00:00');
        d.setMonth(d.getMonth() + months);
        return d.toISOString().slice(0, 10);
    }

    _precargarFianzas() {
        const monto = parseFloat(this.contratoData.valorContrato) || 0;
        const inicio = this.contratoData.startDate || '';
        const fin    = this.contratoData.endDate   || '';
        const finViciosOcultos = this._addMonths(fin, 12);
        const prima = v => parseFloat(((v * 0.01)).toFixed(2));

        const montoAnticipo     = parseFloat((monto * 0.30).toFixed(2));
        const montoCumplimiento = parseFloat((monto * 0.10).toFixed(2));
        const montoVicios       = parseFloat((monto * 0.10).toFixed(2));

        this.fianzas = [
            {
                _key: ++_keyCounter, _num: 1,
                tipoRiesgo: 'Anticipo', monto: String(montoAnticipo),
                primaNeta: String(prima(montoAnticipo)),
                fechaEmision: inicio, fechaVencimiento: fin,
                tipoRiesgoCumplimiento: false, tipoRiesgoAnticipo: true,
                tipoRiesgoVicios: false, tipoRiesgoPasivos: false, tipoRiesgoOtro: false,
            },
            {
                _key: ++_keyCounter, _num: 2,
                tipoRiesgo: 'Cumplimiento', monto: String(montoCumplimiento),
                primaNeta: String(prima(montoCumplimiento)),
                fechaEmision: inicio, fechaVencimiento: fin,
                tipoRiesgoCumplimiento: true, tipoRiesgoAnticipo: false,
                tipoRiesgoVicios: false, tipoRiesgoPasivos: false, tipoRiesgoOtro: false,
            },
            {
                _key: ++_keyCounter, _num: 3,
                tipoRiesgo: 'Vicios y Defectos Ocultos', monto: String(montoVicios),
                primaNeta: String(prima(montoVicios)),
                fechaEmision: fin, fechaVencimiento: finViciosOcultos,
                tipoRiesgoCumplimiento: false, tipoRiesgoAnticipo: false,
                tipoRiesgoVicios: true, tipoRiesgoPasivos: false, tipoRiesgoOtro: false,
            },
        ];
    }

    handleBack() {
        if (this.step > 1) this.step--;
    }

    async _loadPrecalificaciones(contratistaId) {
        this.precalificacionLoading = true;
        try {
            const data = await getPrecalificacionesByContratista({ contratistaId });
            const selectedId = this.contratoData.precalificacionId;
            this.precalificaciones = (data || []).map(p => {
                const suficiente = p.capacidadAfianzamiento === 'Capacidad Suficiente';
                const selected   = p.id === selectedId;
                return {
                    id:           p.id,
                    name:         p.name,
                    estado:       p.estadoAutomatico || p.estado || '',
                    capacidad:    p.capacidadAfianzamiento || '—',
                    suficiente,
                    resultadoFmt: p.resultadoAfianzamiento != null ? fmt(p.resultadoAfianzamiento) : '—',
                    comentarios:  p.comentarios || '',
                    fecha:        p.fechaEstadosFinancieros ? String(p.fechaEstadosFinancieros) : '',
                    cardClass:    'wz-prec-card'
                                  + (!suficiente ? ' wz-prec-card-disabled' : '')
                                  + (selected && suficiente ? ' wz-prec-card-selected' : ''),
                };
            });
        } catch (e) {
            this.precalificaciones = [];
        } finally {
            this.precalificacionLoading = false;
        }
    }

    handleSelectPrecalificacion(e) {
        const p = this.precalificaciones.find(x => x.id === e.currentTarget.dataset.id);
        if (!p || !p.suficiente) return;
        const id   = p.id;
        const name = p.name;
        const toggle = this.contratoData.precalificacionId === id;
        this.contratoData = { ...this.contratoData,
            precalificacionId:     toggle ? '' : id,
            precalificacionNombre: toggle ? '' : name,
        };
        this._refreshCardClasses();
    }

    handleClearPrecalificacion() {
        this.contratoData = { ...this.contratoData, precalificacionId: '', precalificacionNombre: '' };
        this._refreshCardClasses();
    }

    _refreshCardClasses() {
        const selId = this.contratoData.precalificacionId;
        this.precalificaciones = this.precalificaciones.map(p => ({
            ...p,
            cardClass: 'wz-prec-card'
                       + (!p.suficiente ? ' wz-prec-card-disabled' : '')
                       + (p.id === selId && p.suficiente ? ' wz-prec-card-selected' : ''),
        }));
    }

    handleNuevaPrecalificacion() { this.showPrecalificacionModal = true; }
    handlePrecalificacionModalClose() { this.showPrecalificacionModal = false; }
    handlePrecalificacionModalSuccess(e) {
        this.showPrecalificacionModal = false;
        const newId = e.detail;
        this._loadPrecalificaciones(this.contratoData.contratistaId).then(() => {
            if (newId) {
                const p = this.precalificaciones.find(x => x.id === newId);
                if (p && p.suficiente) {
                    this.contratoData = { ...this.contratoData, precalificacionId: newId, precalificacionNombre: p.name };
                    this._refreshCardClasses();
                }
            }
        });
    }

    // ── Close ────────────────────────────────────────────────────────────────────

    handleClose() { this.dispatchEvent(new CustomEvent('close')); }
    handleOverlayClick() { this.handleClose(); }
    stopProp(e) { e.stopPropagation(); }

    // ── Lookup: búsqueda unificada ────────────────────────────────────────────────

    async _doSearch(tipo, kw) {
        try {
            let res;
            if      (tipo === 'contratista')  res = await searchContratistas ({ term: kw });
            else if (tipo === 'institucion')  res = await searchAfianzadoras ({ term: kw });
            else if (tipo === 'beneficiario') res = await searchBeneficiarios({ term: kw });
            if      (tipo === 'contratista')  this.resultadosContratista  = res || [];
            else if (tipo === 'institucion')  this.resultadosInstitucion  = res || [];
            else if (tipo === 'beneficiario') this.resultadosBeneficiario = res || [];
        } catch (err) { /* silencioso */ }
    }

    _kw(tipo) {
        if (tipo === 'contratista')  return this.contratistaBusqueda;
        if (tipo === 'institucion')  return this.institucionBusqueda;
        return this.beneficiarioBusqueda;
    }

    handleFocusLookup(e) {
        clearTimeout(this._blurTimer);
        const tipo = e.currentTarget.dataset.tipo;
        this._doSearch(tipo, this._kw(tipo));
    }

    handleBlurLookup(e) {
        const tipo = e.currentTarget.dataset.tipo;
        this._blurTimer = setTimeout(() => {
            if      (tipo === 'contratista')  this.resultadosContratista  = [];
            else if (tipo === 'institucion')  this.resultadosInstitucion  = [];
            else if (tipo === 'beneficiario') this.resultadosBeneficiario = [];
        }, 200);
    }

    handleBuscarContratista(e) {
        const kw = e.target.value;
        this.contratistaBusqueda = kw;
        clearTimeout(this._searchTimers.contratista);
        this._searchTimers.contratista = setTimeout(() => this._doSearch('contratista', kw), 250);
    }

    handleBuscarInstitucion(e) {
        const kw = e.target.value;
        this.institucionBusqueda = kw;
        clearTimeout(this._searchTimers.institucion);
        this._searchTimers.institucion = setTimeout(() => this._doSearch('institucion', kw), 250);
    }

    handleBuscarBeneficiario(e) {
        const kw = e.target.value;
        this.beneficiarioBusqueda = kw;
        clearTimeout(this._searchTimers.beneficiario);
        this._searchTimers.beneficiario = setTimeout(() => this._doSearch('beneficiario', kw), 250);
    }

    _fmtDate(iso) {
        if (!iso) return '';
        const [y, m, d] = iso.split('-');
        return `${d}/${m}/${y}`;
    }

    _autoProyecto(nombre, fecha) {
        if (!nombre) return this.contratoData.proyecto;
        return fecha ? `${nombre} ${this._fmtDate(fecha)}` : nombre;
    }

    handleSelectLookup(e) {
        e.stopPropagation();
        const id   = e.currentTarget.dataset.id;
        const name = e.currentTarget.dataset.name;
        const tipo = e.currentTarget.dataset.tipo;
        if (tipo === 'contratista') {
            const proyecto = this._autoProyecto(name, this.contratoData.startDate);
            this.contratoData = { ...this.contratoData, contratistaId: id, contratistaNombre: name, proyecto };
            this.contratistaBusqueda = ''; this.resultadosContratista = [];
        } else if (tipo === 'institucion') {
            this.contratoData = { ...this.contratoData, institucionId: id, institucionNombre: name };
            this.institucionBusqueda = ''; this.resultadosInstitucion = [];
        } else if (tipo === 'beneficiario') {
            this.contratoData = { ...this.contratoData, beneficiarioId: id, beneficiarioNombre: name };
            this.beneficiarioBusqueda = ''; this.resultadosBeneficiario = [];
        }
    }

    handleClearLookup(e) {
        e.stopPropagation();
        const tipo = e.currentTarget.dataset.tipo;
        if (tipo === 'contratista') {
            this.contratoData = { ...this.contratoData, contratistaId: '', contratistaNombre: '' };
            this.precalificaciones = [];
        } else if (tipo === 'institucion') {
            this.contratoData = { ...this.contratoData, institucionId: '', institucionNombre: '' };
        } else if (tipo === 'beneficiario') {
            this.contratoData = { ...this.contratoData, beneficiarioId: '', beneficiarioNombre: '' };
        }
    }

    // ── Contrato fields ──────────────────────────────────────────────────────────

    handleContratoField(e) {
        const field = e.currentTarget.dataset.field;
        const value = e.target.value;
        const updated = { ...this.contratoData, [field]: value };
        if (field === 'startDate') {
            updated.proyecto = this._autoProyecto(updated.contratistaNombre, value);
        }
        this.contratoData = updated;
    }

    // ── Fianza cards ─────────────────────────────────────────────────────────────

    handleAddFianza() {
        this.fianzas = [...this.fianzas, newFianza(this.fianzas.length + 1)];
    }

    handleRemoveFianza(e) {
        e.stopPropagation();
        const key = parseInt(e.currentTarget.dataset.key, 10);
        this.fianzas = this.fianzas.filter(f => f._key !== key).map((f, i) => ({ ...f, _num: i + 1 }));
    }

    handleFianzaField(e) {
        const key   = parseInt(e.currentTarget.dataset.key, 10);
        const field = e.currentTarget.dataset.field;
        const value = e.target.value;
        this.fianzas = this.fianzas.map(f => {
            if (f._key !== key) return f;
            const updated = { ...f, [field]: value };
            if (field === 'tipoRiesgo') {
                updated.tipoRiesgoCumplimiento = value === 'Cumplimiento';
                updated.tipoRiesgoAnticipo     = value === 'Anticipo';
                updated.tipoRiesgoVicios       = value === 'Vicios y Defectos Ocultos';
                updated.tipoRiesgoPasivos      = value === 'Pasivos Laborales';
                updated.tipoRiesgoOtro         = value === 'Otro';
            }
            return updated;
        });
    }

    get canRemoveFianza() { return this.fianzas.length > 1; }

    // ── Review helpers ────────────────────────────────────────────────────────────

    get fianzasCount()     { return this.fianzas.length; }
    get contratoValorFmt() { return fmt(this.contratoData.valorContrato); }

    get sumaMontosFmt() {
        const total = this.fianzas.reduce((s, f) => s + (parseFloat(f.monto) || 0), 0);
        return fmt(total);
    }

    get fianzasResumen() {
        return this.fianzas.map(f => ({
            ...f,
            montoFmt:         fmt(f.monto),
            primaFmt:         fmt(f.primaNeta) || '—',
            fechaEmision:     f.fechaEmision    || '—',
            fechaVencimiento: f.fechaVencimiento || '—',
        }));
    }

    // ── Save ─────────────────────────────────────────────────────────────────────

    async handleSave() {
        this.isSaving = true;
        try {
            const contratoPayload = {
                contratistaId:     this.contratoData.contratistaId  || null,
                institucionId:     this.contratoData.institucionId  || null,
                beneficiarioId:    this.contratoData.beneficiarioId || null,
                valorContrato:     this.contratoData.valorContrato  ? parseFloat(this.contratoData.valorContrato)  : null,
                startDate:         this.contratoData.startDate      || null,
                endDate:           this.contratoData.endDate        || null,
                proyecto:          this.contratoData.proyecto       || null,
                precalificacionId: this.contratoData.precalificacionId || null,
            };
            const fianzasPayload = this.fianzas.map(f => ({
                id:               f._existingId     || null,
                tipoRiesgo:       f.tipoRiesgo      || null,
                monto:            f.monto           ? parseFloat(f.monto)     : null,
                primaNeta:        f.primaNeta       ? parseFloat(f.primaNeta) : null,
                fechaEmision:     f.fechaEmision    || null,
                fechaVencimiento: f.fechaVencimiento || null,
            }));
            if (this._editMode) {
                await actualizarContratoConFianzas({
                    contratoId:   this._contratoId,
                    contratoData: contratoPayload,
                    fianzasData:  fianzasPayload,
                });
            } else {
                await crearContratoConFianzas({ contratoData: contratoPayload, fianzasData: fianzasPayload });
            }
            this.dispatchEvent(new CustomEvent('success'));
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err?.body?.message || 'Error al guardar', variant: 'error' }));
        } finally {
            this.isSaving = false;
        }
    }
}
