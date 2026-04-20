import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBeneficiarioFields from '@salesforce/apex/TechBeneficiarioFieldsController.getBeneficiarioFields';
import saveBeneficiarioWithRelations from '@salesforce/apex/TechBeneficiarioController.saveBeneficiarioWithRelations';

export default class TechBeneficiarioCreateModal extends NavigationMixin(LightningElement) {
    @api showModal = false;
    @track fields = [];
    @track isLoading = false;
    selectedFianzaIds = [];

    @wire(getBeneficiarioFields)
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
        const relationsMap = { 'Fianza': this.selectedFianzaIds };

        saveBeneficiarioWithRelations({ beneficiario: { ...fields, sobjectType: 'Beneficiario__c' }, relationsMap: relationsMap })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Éxito', message: 'Beneficiario guardado correctamente', variant: 'success' }));
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
