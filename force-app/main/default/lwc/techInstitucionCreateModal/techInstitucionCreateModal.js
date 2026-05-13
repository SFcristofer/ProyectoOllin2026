import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TechInstitucionCreateModal extends LightningElement {
    @api showModal = false;

    handleClose()         { this.dispatchEvent(new CustomEvent('close')); }
    handleBackdropClick() { this.handleClose(); }
    handleModalClick(e)   { e.stopPropagation(); }

    handleSuccess() {
        this.dispatchEvent(new CustomEvent('success'));
    }

    handleError(e) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error al guardar',
            message: e.detail?.detail || 'Revisa los campos e intenta de nuevo.',
            variant: 'error',
        }));
    }
}
