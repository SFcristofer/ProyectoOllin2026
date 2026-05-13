import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFianzaFields from '@salesforce/apex/TechFianzaFieldsController.getFianzaFields';
import saveFianzaWithRelations from '@salesforce/apex/TechFianzaController.saveFianzaWithRelations';

const SPECIAL_FIELDS = ['No_Contrato__c', 'Endoso__c', 'Contratista__c', 'Vendedor__c', 'Estatus__c'];

const FIELD_TYPE_ICONS = {
    STRING:    { icon: 'utility:text',     label: 'Texto' },
    TEXTAREA:  { icon: 'utility:text',     label: 'Texto largo' },
    DOUBLE:    { icon: 'utility:number_input', label: 'Número' },
    CURRENCY:  { icon: 'utility:currency', label: 'Moneda' },
    PERCENT:   { icon: 'utility:percent',  label: 'Porcentaje' },
    DATE:      { icon: 'utility:event',    label: 'Fecha' },
    DATETIME:  { icon: 'utility:event',    label: 'Fecha/Hora' },
    BOOLEAN:   { icon: 'utility:check',    label: 'Casilla' },
    PICKLIST:  { icon: 'utility:record',   label: 'Lista' },
    REFERENCE: { icon: 'utility:search',   label: 'Relación' },
    EMAIL:     { icon: 'utility:email',    label: 'Email' },
    PHONE:     { icon: 'utility:call',     label: 'Teléfono' },
    URL:       { icon: 'utility:link',     label: 'URL' },
};

const STATUS_CLASSES = {
    'Activa':    'at-status-badge at-status-green',
    'Pendiente': 'at-status-badge at-status-orange',
    'Cancelada': 'at-status-badge at-status-red',
    'Vencida':   'at-status-badge at-status-gray',
};

export default class TechFianzaCreateModal extends NavigationMixin(LightningElement) {
    @api showModal    = false;
    @api editRecordId = null;
    @track fields     = [];
    @track isLoading  = false;
    @track currentEstatus = '';

    get isEditMode()   { return !!this.editRecordId; }
    get modalTitle()   { return this.isEditMode ? 'Editar registro' : 'Nuevo registro'; }

    selectedContratoIds    = [];
    selectedEndosoIds      = [];
    selectedContratistaIds = [];
    selectedVendedorIds    = [];

    @wire(getFianzaFields)
    wiredFields({ data }) {
        if (!data) return;
        this.fields = data.map(f => {
            const typeInfo = FIELD_TYPE_ICONS[f.type] || { icon: 'utility:text', label: 'Campo' };
            const isContrato    = f.apiName === 'No_Contrato__c';
            const isEndoso      = f.apiName === 'Endoso__c';
            const isContratista = f.apiName === 'Contratista__c';
            const isVendedor    = f.apiName === 'Vendedor__c';
            const isEstatusField = f.apiName === 'Estatus__c';
            return {
                ...f,
                typeIcon:     typeInfo.icon,
                typeLabel:    typeInfo.label,
                isContrato,
                isEndoso,
                isContratista,
                isVendedor,
                isEstatusField,
                isSpecial: SPECIAL_FIELDS.includes(f.apiName),
            };
        });
    }

    get currentEstatusClass() {
        return this.currentEstatus ? STATUS_CLASSES[this.currentEstatus] : null;
    }

    handleEstatusChange(event) {
        this.currentEstatus = event.detail?.value || event.target?.value || '';
    }

    handleContratoChange(event)    { this.selectedContratoIds    = event.detail.selectedIds; }
    handleEndosoChange(event)      { this.selectedEndosoIds      = event.detail.selectedIds; }
    handleContratistaChange(event) { this.selectedContratistaIds = event.detail.selectedIds; }
    handleVendedorChange(event)    { this.selectedVendedorIds    = event.detail.selectedIds; }

    handleQuickCreate(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: event.detail.objectApiName, actionName: 'new' },
        });
    }

    handleSubmit(event) {
        event.preventDefault();
        this.isLoading = true;

        const formFields = { ...event.detail.fields };
        if (this.selectedContratoIds.length    > 0) formFields.No_Contrato__c = this.selectedContratoIds[0];
        if (this.selectedEndosoIds.length      > 0) formFields.Endoso__c      = this.selectedEndosoIds[0];
        if (this.selectedContratistaIds.length > 0) formFields.Contratista__c = this.selectedContratistaIds[0];
        if (this.selectedVendedorIds.length    > 0) formFields.Vendedor__c    = this.selectedVendedorIds[0];

        if (this.isEditMode) {
            updateRecord({ fields: { Id: this.editRecordId, ...formFields } })
                .then(() => {
                    this.dispatchEvent(new ShowToastEvent({ title: 'Éxito', message: 'Fianza actualizada correctamente.', variant: 'success' }));
                    this.isLoading = false;
                    this._reset();
                    this.dispatchEvent(new CustomEvent('success'));
                })
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({ title: 'Error al guardar', message: error.body?.message || error.message, variant: 'error' }));
                    this.isLoading = false;
                });
            return;
        }

        const relationsMap = {
            Contrato:    this.selectedContratoIds,
            Endoso:      this.selectedEndosoIds,
            Contratista: this.selectedContratistaIds,
            Vendedor:    this.selectedVendedorIds,
        };

        saveFianzaWithRelations({ fianza: { ...formFields, sobjectType: 'Tech_Fianza__c' }, relationsMap })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Éxito', message: 'Fianza creada correctamente.', variant: 'success' }));
                this.isLoading = false;
                this._reset();
                this.dispatchEvent(new CustomEvent('success'));
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Error al guardar', message: error.body?.message || error.message, variant: 'error' }));
                this.isLoading = false;
            });
    }

    handleOverlayClick() {
        this.closeModal();
    }

    closeModal() {
        this._reset();
        this.dispatchEvent(new CustomEvent('close'));
    }

    _reset() {
        this.selectedContratoIds    = [];
        this.selectedEndosoIds      = [];
        this.selectedContratistaIds = [];
        this.selectedVendedorIds    = [];
        this.currentEstatus         = '';
    }
}