import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProyectoFields from '@salesforce/apex/TechProyectoFieldsController.getProyectoFields';
import saveProyectoWithRelations from '@salesforce/apex/TechProyectoController.saveProyectoWithRelations';

export default class TechProyectoCreateModal extends NavigationMixin(LightningElement) {
    @api showModal = false;
    @track fields = [];
    @track isLoading = false;
    
    selectedContratoIds = [];
    selectedBeneficiarioIds = [];

    @wire(getProyectoFields)
    wiredFields({ error, data }) {
        if (data) {
            const specialFields = ['Contrato__c', 'Beneficiario__c']; // Ajustar si el campo tiene otro nombre
            this.fields = data.map(f => ({
                ...f,
                isContrato: f.apiName === 'Contrato__c',
                isBeneficiario: f.apiName === 'Beneficiario__c',
                isSpecial: specialFields.includes(f.apiName)
            }));
        }
    }

    handleContratoChange(event) { this.selectedContratoIds = event.detail.selectedIds; }
    handleBeneficiarioChange(event) { this.selectedBeneficiarioIds = event.detail.selectedIds; }

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
        
        if (this.selectedContratoIds.length > 0) fields.Contrato__c = this.selectedContratoIds[0];
        if (this.selectedBeneficiarioIds.length > 0) fields.Beneficiario__c = this.selectedBeneficiarioIds[0];

        const relationsMap = {
            'Contrato': this.selectedContratoIds,
            'Beneficiario': this.selectedBeneficiarioIds
        };

        saveProyectoWithRelations({ proyecto: { ...fields, sobjectType: 'Proyecto__c' }, relationsMap: relationsMap })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Éxito', message: 'Proyecto guardado correctamente', variant: 'success' }));
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
