import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAfianzadoFields from '@salesforce/apex/TechAfianzadoFieldsController.getAfianzadoFields';
import saveAfianzadoWithRelations from '@salesforce/apex/TechAfianzadoController.saveAfianzadoWithRelations';

const TYPE_ICONS = { STRING: 'utility:text', CURRENCY: 'utility:currency', DATE: 'utility:event', DATETIME: 'utility:event', PICKLIST: 'utility:record', REFERENCE: 'utility:search', BOOLEAN: 'utility:check', DOUBLE: 'utility:number_input', INTEGER: 'utility:number_input', PERCENT: 'utility:percent', PHONE: 'utility:call', EMAIL: 'utility:email', URL: 'utility:link', TEXTAREA: 'utility:textbox' };

export default class TechAfianzadoCreateModal extends NavigationMixin(LightningElement) {
    @api showModal = false;
    @track fields = [];
    @track isLoading = false;
    selectedFianzaIds = [];

    @wire(getAfianzadoFields)
    wiredFields({ data }) {
        if (data) {
            this.fields = data.map(f => ({
                ...f,
                typeIcon:  TYPE_ICONS[f.type] || 'utility:text',
                isFianza:  f.apiName === 'Fianza__c',
                isSpecial: f.apiName === 'Fianza__c'
            }));
        }
    }

    handleFianzaChange(event) { this.selectedFianzaIds = event.detail.selectedIds; }

    handleQuickCreate(event) {
        this[NavigationMixin.Navigate]({ type: 'standard__objectPage', attributes: { objectApiName: event.detail.objectApiName, actionName: 'new' } });
    }

    handleOverlayClick(event) { if (event.target === event.currentTarget) this.closeModal(); }

    handleSubmit(event) {
        event.preventDefault();
        this.isLoading = true;
        const fields = { ...event.detail.fields };
        saveAfianzadoWithRelations({ account: { ...fields, sobjectType: 'Account' }, relationsMap: { 'Fianza': this.selectedFianzaIds } })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Éxito', message: 'Afianzado guardado correctamente', variant: 'success' }));
                this._reset();
                this.dispatchEvent(new CustomEvent('success'));
            })
            .catch(err => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err.body?.message || err.message, variant: 'error' }));
                this.isLoading = false;
            });
    }

    _reset() { this.isLoading = false; this.selectedFianzaIds = []; }
    closeModal() { this._reset(); this.dispatchEvent(new CustomEvent('close')); }
}