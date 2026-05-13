import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TechConvenioCreateModal extends LightningElement {
    @api showModal = false;
    @track isLoading = false;

    handleOverlayClick(event) { if (event.target === event.currentTarget) this.closeModal(); }

    handleSuccess() {
        this.isLoading = false;
        this.dispatchEvent(new ShowToastEvent({ title: 'Éxito', message: 'Convenio guardado correctamente', variant: 'success' }));
        this.dispatchEvent(new CustomEvent('success'));
    }

    handleError(event) {
        this.isLoading = false;
        this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: event.detail?.detail || 'Error al guardar', variant: 'error' }));
    }

    closeModal() { this.isLoading = false; this.dispatchEvent(new CustomEvent('close')); }
}