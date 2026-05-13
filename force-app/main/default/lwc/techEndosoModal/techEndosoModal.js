import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TechEndosoModal extends LightningElement {
    @api recordId;
    @api seguroId;
    @api fianzaId;
    @api contextLabel;

    @track isSaving = false;

    get isEditing()  { return !!this.recordId; }
    get isFianza()   { return !!this.fianzaId; }
    get modalTitle() { return this.isEditing ? 'Editar Endoso' : 'Nuevo Endoso'; }
    get saveLabel()  { return this.isSaving ? 'Guardando...' : (this.isEditing ? 'Guardar cambios' : 'Guardar'); }

    handleClose() {
        if (this.isSaving) return;
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleSubmit(event) {
        event.preventDefault();
        this.isSaving = true;
        const fields = { ...event.detail.fields };
        if (!this.isEditing) {
            if (this.seguroId) fields.Seguro__c = this.seguroId;
            if (this.fianzaId) fields.Fianza__c = this.fianzaId;
        }
        event.target.submit(fields);
    }

    handleSuccess(event) {
        this.isSaving = false;
        this.dispatchEvent(new ShowToastEvent({
            title: 'Endoso guardado', variant: 'success'
        }));
        this.dispatchEvent(new CustomEvent('success', { detail: event.detail.id }));
    }

    handleError(event) {
        this.isSaving = false;
        const msg = event.detail?.message || 'Error al guardar endoso';
        this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: msg, variant: 'error' }));
    }
}
