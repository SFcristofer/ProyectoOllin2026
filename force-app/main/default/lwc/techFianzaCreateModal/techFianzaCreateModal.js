import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFianzaFields from '@salesforce/apex/TechFianzaFieldsController.getFianzaFields';
import saveFianzaWithRelations from '@salesforce/apex/TechFianzaController.saveFianzaWithRelations';

export default class TechFianzaCreateModal extends NavigationMixin(LightningElement) {
    @api showModal = false;
    @track fields = [];
    @track isLoading = false;
    
    selectedContratoIds = [];
    selectedEndosoIds = [];
    selectedContratistaIds = [];
    selectedVendedorIds = [];

    @wire(getFianzaFields)
    wiredFields({ error, data }) {
        if (data) {
            const specialFields = ['No_Contrato__c', 'Endoso__c', 'Contratista__c', 'Vendedor__c'];
            this.fields = data.map(f => ({
                ...f,
                isContrato: f.apiName === 'No_Contrato__c',
                isEndoso: f.apiName === 'Endoso__c',
                isContratista: f.apiName === 'Contratista__c',
                isVendedor: f.apiName === 'Vendedor__c',
                isSpecial: specialFields.includes(f.apiName)
            }));
        }
    }

    handleContratoChange(event) { this.selectedContratoIds = event.detail.selectedIds; }
    handleEndosoChange(event) { this.selectedEndosoIds = event.detail.selectedIds; }
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

        // Clonamos los campos del formulario
        const fields = { ...event.detail.fields };
        
        // INYECTAMOS LOS IDS MANUALMENTE (Tomamos el primero para el campo principal)
        if (this.selectedContratoIds.length > 0) fields.No_Contrato__c = this.selectedContratoIds[0];
        if (this.selectedEndosoIds.length > 0) fields.Endoso__c = this.selectedEndosoIds[0];
        if (this.selectedContratistaIds.length > 0) fields.Contratista__c = this.selectedContratistaIds[0];
        if (this.selectedVendedorIds.length > 0) fields.Vendedor__c = this.selectedVendedorIds[0];

        const relationsMap = {
            'Contrato': this.selectedContratoIds,
            'Endoso': this.selectedEndosoIds,
            'Contratista': this.selectedContratistaIds,
            'Vendedor': this.selectedVendedorIds
        };

        saveFianzaWithRelations({ fianza: { ...fields, sobjectType: 'Fianza__c' }, relationsMap: relationsMap })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Éxito',
                    message: 'Fianza creada correctamente con todas sus relaciones.',
                    variant: 'success'
                }));
                this.isLoading = false;
                this.dispatchEvent(new CustomEvent('success'));
            })
            .catch(error => {
                console.error('Error detallado:', error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error al guardar',
                    message: error.body ? error.body.message : error.message,
                    variant: 'error'
                }));
                this.isLoading = false;
            });
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}
