import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveContratistaWithRelations from '@salesforce/apex/TechContratistaController.saveContratistaWithRelations';

export default class TechContratistaCreateModal extends LightningElement {
    @api showModal = false;
    @track isLoading = false;

    handleOverlayClick(event) { if (event.target === event.currentTarget) this.closeModal(); }

    handleSubmit(event) {
        event.preventDefault();
        this.isLoading = true;
        const fields = event.detail.fields;
        saveContratistaWithRelations({ contratista: { ...fields, sobjectType: 'Account' }, relationsMap: {} })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Éxito', message: 'Contratista creado correctamente', variant: 'success' }));
                this.isLoading = false;
                this.dispatchEvent(new CustomEvent('success'));
            })
            .catch(err => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err.body?.message || err.message, variant: 'error' }));
                this.isLoading = false;
            });
    }

    handleError(event) {
        this.isLoading = false;
        this.dispatchEvent(new ShowToastEvent({ title: 'Error de validación', message: event.detail.message, variant: 'error' }));
    }

    closeModal() { this.isLoading = false; this.dispatchEvent(new CustomEvent('close')); }
}
