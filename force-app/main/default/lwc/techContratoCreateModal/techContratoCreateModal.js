import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContratoFields from '@salesforce/apex/TechContratoFieldsController.getContratoFields';
import saveContratoWithRelations from '@salesforce/apex/TechContratoController.saveContratoWithRelations';

const TYPE_ICONS = { STRING: 'utility:text', CURRENCY: 'utility:currency', DATE: 'utility:event', DATETIME: 'utility:event', PICKLIST: 'utility:record', REFERENCE: 'utility:search', BOOLEAN: 'utility:check', DOUBLE: 'utility:number_input', INTEGER: 'utility:number_input', PERCENT: 'utility:percent', PHONE: 'utility:call', EMAIL: 'utility:email', URL: 'utility:link', TEXTAREA: 'utility:textbox' };
const SPECIAL_FIELDS = ['Contratista__c', 'Vendedor__c'];

export default class TechContratoCreateModal extends NavigationMixin(LightningElement) {
    @api showModal = false;
    @track fields = [];
    @track isLoading = false;
    selectedContratistaIds = [];
    selectedVendedorIds = [];

    @wire(getContratoFields)
    wiredFields({ data }) {
        if (data) {
            this.fields = data.map(f => ({
                ...f,
                typeIcon:      TYPE_ICONS[f.type] || 'utility:text',
                isContratista: f.apiName === 'Contratista__c',
                isVendedor:    f.apiName === 'Vendedor__c',
                isSpecial:     SPECIAL_FIELDS.includes(f.apiName)
            }));
        }
    }

    handleContratistaChange(event) { this.selectedContratistaIds = event.detail.selectedIds; }
    handleVendedorChange(event)    { this.selectedVendedorIds    = event.detail.selectedIds; }

    handleQuickCreate(event) {
        this[NavigationMixin.Navigate]({ type: 'standard__objectPage', attributes: { objectApiName: event.detail.objectApiName, actionName: 'new' } });
    }

    handleOverlayClick(event) { if (event.target === event.currentTarget) this.closeModal(); }

    handleSubmit(event) {
        event.preventDefault();
        this.isLoading = true;
        const fields = { ...event.detail.fields };
        if (this.selectedContratistaIds.length > 0) fields.Contratista__c = this.selectedContratistaIds[0];
        if (this.selectedVendedorIds.length > 0)    fields.Vendedor__c    = this.selectedVendedorIds[0];
        saveContratoWithRelations({ contrato: { ...fields, sobjectType: 'Contract' }, relationsMap: { 'Contratista': this.selectedContratistaIds, 'Vendedor': this.selectedVendedorIds } })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Éxito', message: 'Contrato guardado correctamente', variant: 'success' }));
                this._reset();
                this.dispatchEvent(new CustomEvent('success'));
            })
            .catch(err => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err.body?.message || err.message, variant: 'error' }));
                this.isLoading = false;
            });
    }

    _reset() { this.isLoading = false; this.selectedContratistaIds = []; this.selectedVendedorIds = []; }
    closeModal() { this._reset(); this.dispatchEvent(new CustomEvent('close')); }
}