import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAmpliacionFields from '@salesforce/apex/TechAmpliacionFieldsController.getAmpliacionFields';
import saveAmpliacionWithRelations from '@salesforce/apex/TechAmpliacionController.saveAmpliacionWithRelations';

export default class TechAmpliacionCreateModal extends NavigationMixin(LightningElement) {
    @api showModal = false;
    @track fields = [];
    @track isLoading = false;
    selectedFianzaIds = [];

    @wire(getAmpliacionFields)
    wiredFields({ error, data }) {
        if (data) {
            this.fields = data.map(f => ({
                ...f,
                isFianza: f.apiName === 'Fianza__c',
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
        if (this.selectedFianzaIds.length > 0) fields.Fianza__c = this.selectedFianzaIds[0];

        const relationsMap = { 'Fianza': this.selectedFianzaIds };

        saveAmpliacionWithRelations({ ampliacion: { ...fields, sobjectType: 'Endoso__c' }, relationsMap: relationsMap })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Éxito', message: 'Ampliación guardada correctamente', variant: 'success' }));
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
