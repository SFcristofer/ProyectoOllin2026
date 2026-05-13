import { LightningElement, api, track } from 'lwc';

export default class TechAccesoCreateModal extends LightningElement {

    @api showModal      = false;
    @api institucionId  = null;
    @api institucionName = '';

    @track errorMsg = '';

    handleSuccess() {
        this.errorMsg = '';
        this.dispatchEvent(new CustomEvent('success'));
    }

    handleError(e) {
        this.errorMsg = e.detail?.message || 'Error al guardar el acceso.';
    }

    handleClose() {
        this.errorMsg = '';
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleBackdropClick(e) {
        if (e.target === e.currentTarget) this.handleClose();
    }
}
