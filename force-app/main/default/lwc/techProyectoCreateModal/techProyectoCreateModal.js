import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProyectoFields from '@salesforce/apex/TechProyectoFieldsController.getProyectoFields';
import saveProyectoWithRelations from '@salesforce/apex/TechProyectoController.saveProyectoWithRelations';

const TYPE_ICONS = { STRING: 'utility:text', CURRENCY: 'utility:currency', DATE: 'utility:event', DATETIME: 'utility:event', PICKLIST: 'utility:record', REFERENCE: 'utility:search', BOOLEAN: 'utility:check', DOUBLE: 'utility:number_input', INTEGER: 'utility:number_input', PERCENT: 'utility:percent', PHONE: 'utility:call', EMAIL: 'utility:email', URL: 'utility:link', TEXTAREA: 'utility:textbox' };
const SPECIAL_FIELDS = ['Contrato__c', 'Beneficiario__c'];

export default class TechProyectoCreateModal extends NavigationMixin(LightningElement) {
    @api showModal = false;
    @track fields = [];
    @track isLoading = false;
    selectedContratoIds = [];
    selectedBeneficiarioIds = [];

    @wire(getProyectoFields)
    wiredFields({ data }) {
        if (data) {
            this.fields = data.map(f => ({
                ...f,
                typeIcon:       TYPE_ICONS[f.type] || 'utility:text',
                isContrato:     f.apiName === 'Contrato__c',
                isBeneficiario: f.apiName === 'Beneficiario__c',
                isSpecial:      SPECIAL_FIELDS.includes(f.apiName)
            }));
        }
    }

    handleContratoChange(event)     { this.selectedContratoIds     = event.detail.selectedIds; }
    handleBeneficiarioChange(event) { this.selectedBeneficiarioIds = event.detail.selectedIds; }

    handleQuickCreate(event) {
        this[NavigationMixin.Navigate]({ type: 'standard__objectPage', attributes: { objectApiName: event.detail.objectApiName, actionName: 'new' } });
    }

    handleOverlayClick(event) { if (event.target === event.currentTarget) this.closeModal(); }

    handleSubmit(event) {
        event.preventDefault();
        this.isLoading = true;
        const fields = { ...event.detail.fields };
        if (this.selectedContratoIds.length > 0)     fields.Contrato__c     = this.selectedContratoIds[0];
        if (this.selectedBeneficiarioIds.length > 0) fields.Beneficiario__c = this.selectedBeneficiarioIds[0];
        saveProyectoWithRelations({ proyecto: { ...fields, sobjectType: 'Proyecto__c' }, relationsMap: { 'Contrato': this.selectedContratoIds, 'Beneficiario': this.selectedBeneficiarioIds } })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Éxito', message: 'Proyecto guardado correctamente', variant: 'success' }));
                this._reset();
                this.dispatchEvent(new CustomEvent('success'));
            })
            .catch(err => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err.body?.message || err.message, variant: 'error' }));
                this.isLoading = false;
            });
    }

    _reset() { this.isLoading = false; this.selectedContratoIds = []; this.selectedBeneficiarioIds = []; }
    closeModal() { this._reset(); this.dispatchEvent(new CustomEvent('close')); }
}