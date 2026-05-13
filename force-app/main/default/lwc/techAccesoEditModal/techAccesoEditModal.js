import { LightningElement, api, track } from 'lwc';

export default class TechAccesoEditModal extends LightningElement {

    @api showModal = false;
    @api accesoId  = null;

    @track errorMsg = '';

    handleSuccess() {
        this.errorMsg = '';
        this.dispatchEvent(new CustomEvent('success'));
    }

    handleError(e) {
        this.errorMsg = e.detail?.message || 'Error al guardar.';
    }

    handleClose() {
        this.errorMsg = '';
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleBackdropClick(e) {
        if (e.target === e.currentTarget) this.handleClose();
    }
}
