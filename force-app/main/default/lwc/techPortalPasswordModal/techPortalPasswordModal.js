import { LightningElement, api, track } from 'lwc';
import verifyAndGetPassword from '@salesforce/apex/TechInstitucionController.verifyAndGetPassword';

export default class TechPortalPasswordModal extends LightningElement {

    @api showModal  = false;
    @api accesoId   = null;
    @api portalName = '';
    /** 'reveal' → muestra contraseña al verificar | 'gate' → emite evento 'verified' y cierra */
    @api mode = 'reveal';

    @track usuario    = '';
    @track contrasena = '';
    @track isVerifying = false;
    @track errorMsg    = '';
    @track revealed    = false;
    @track revealedPassword = '';

    get headerTitle() {
        return this.mode === 'gate' ? 'Verificar identidad' : 'Verificar identidad';
    }

    get verifyBtnLabel() {
        if (this.isVerifying) return 'Verificando...';
        return this.mode === 'gate' ? 'Verificar' : 'Verificar y mostrar';
    }

    handleUsuario(e)    { this.usuario    = e.target.value; this.errorMsg = ''; }
    handleContrasena(e) { this.contrasena = e.target.value; this.errorMsg = ''; }

    handleVerify() {
        if (!this.usuario || !this.contrasena) {
            this.errorMsg = 'Ingresa usuario y contraseña.';
            return;
        }
        this.isVerifying = true;
        this.errorMsg    = '';
        verifyAndGetPassword({ accesoId: this.accesoId, usuario: this.usuario, contrasena: this.contrasena })
            .then(pass => {
                if (this.mode === 'gate') {
                    this._reset();
                    this.dispatchEvent(new CustomEvent('verified'));
                } else {
                    this.revealedPassword = pass;
                    this.revealed         = true;
                }
            })
            .catch(err => {
                this.errorMsg = err?.body?.message || 'Credenciales incorrectas.';
            })
            .finally(() => {
                this.isVerifying = false;
            });
    }

    handleClose() {
        this._reset();
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleBackdropClick(e) {
        if (e.target === e.currentTarget) this.handleClose();
    }

    _reset() {
        this.usuario          = '';
        this.contrasena       = '';
        this.errorMsg         = '';
        this.revealed         = false;
        this.revealedPassword = '';
        this.isVerifying      = false;
    }
}
