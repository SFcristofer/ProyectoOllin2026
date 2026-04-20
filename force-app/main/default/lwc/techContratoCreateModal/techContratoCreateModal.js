import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContratoFields from '@salesforce/apex/TechContratoFieldsController.getContratoFields';
import saveContratoWithRelations from '@salesforce/apex/TechContratoController.saveContratoWithRelations';

export default class TechContratoCreateModal extends NavigationMixin(LightningElement) {
    @api showModal = false;
    @track fields = [];
    @track isLoading = false;
    
    selectedContratistaIds = [];
    selectedVendedorIds = [];

    @wire(getContratoFields)
    wiredFields({ error, data }) {
        if (data) {
            const specialFields = ['Contratista__c', 'Vendedor__c'];
            this.fields = data.map(f => ({
                ...f,
                isContratista: f.apiName === 'Contratista__c',
                isVendedor: f.apiName === 'Vendedor__c',
                isSpecial: specialFields.includes(f.apiName)
            }));
        }
    }

    handleContratistaChange(event) { this.selectedContratistaIds = event.detail.selectedIds; }
    handleVendedorChange(event) { this.selectedVendedorIds = event.detail.selectedIds; }

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
        
        if (this.selectedContratistaIds.length > 0) fields.Contratista__c = this.selectedContratistaIds[0];
        if (this.selectedVendedorIds.length > 0) fields.Vendedor__c = this.selectedVendedorIds[0];

        const relationsMap = {
            'Contratista': this.selectedContratistaIds,
            'Vendedor': this.selectedVendedorIds
        };

        saveContratoWithRelations({ contrato: { ...fields, sobjectType: 'Contrato__c' }, relationsMap: relationsMap })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Éxito', message: 'Contrato guardado correctamente', variant: 'success' }));
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
