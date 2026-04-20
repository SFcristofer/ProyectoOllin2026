import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContratistaFields from '@salesforce/apex/TechContratistaFieldsController.getContratistaFields';
import saveContratistaWithRelations from '@salesforce/apex/TechContratistaController.saveContratistaWithRelations';

export default class TechContratistaCreateModal extends NavigationMixin(LightningElement) {
    @api showModal = false;
    @track fields = [];
    @track isLoading = false;
    selectedFianzaIds = [];

    @wire(getContratistaFields)
    wiredFields({ error, data }) {
        if (data) {
            this.fields = data.map(f => ({
                ...f,
                isFianza: f.apiName === 'Fianza__c', // Ajustar si el campo tiene otro nombre
                isSpecial: f.apiName === 'Fianza__c'
            }));
        }
    }

    handleFianzaChange(event) { this.selectedFianzaIds = event.detail.selectedIds; }

    handleQuickCreate(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: event.detail.objectApiName, actionName: 'new' }
        });
    }

    handleSubmit(event) {
        event.preventDefault();
        this.isLoading = true;
        const fields = { ...event.detail.fields };
        const relationsMap = { 'Fianza': this.selectedFianzaIds };

        saveContratistaWithRelations({ contratista: { ...fields, sobjectType: 'Contratista__c' }, relationsMap: relationsMap })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Éxito', message: 'Contratista guardado correctamente', variant: 'success' }));
                this.isLoading = false;
                this.dispatchEvent(new CustomEvent('success'));
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: error.body ? error.body.message : error.message, variant: 'error' }));
                this.isLoading = false;
            });
    }

    closeModal() { this.dispatchEvent(new CustomEvent('close')); }
}
