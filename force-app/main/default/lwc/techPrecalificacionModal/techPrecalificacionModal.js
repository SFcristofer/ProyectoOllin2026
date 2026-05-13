import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TechPrecalificacionModal extends LightningElement {
    @api recordId;
    @api prospectoId;
    @api contratistaId;
    @api contextLabel;

    @track isSaving = false;

    get isEditing()   { return !!this.recordId; }
    get modalTitle()  { return this.isEditing ? 'Editar Precalificación' : 'Nueva Precalificación'; }
    get saveLabel()   { return this.isSaving ? 'Guardando...' : 'Guardar'; }

    handleClose() {
        if (this.isSaving) return;
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleSubmit(event) {
        event.preventDefault();
        this.isSaving = true;
        const fields = { ...event.detail.fields };
        if (!this.isEditing) {
            if (this.prospectoId)   fields.Prospecto__c  = this.prospectoId;
            if (this.contratistaId) fields.Contratista__c = this.contratistaId;
        }
        event.target.submit(fields);
    }

    handleSuccess(event) {
        this.isSaving = false;
        this.dispatchEvent(new ShowToastEvent({
            title: 'Guardado', message: 'Precalificación creada', variant: 'success'
        }));
        this.dispatchEvent(new CustomEvent('success', { detail: event.detail.id }));
    }

    handleError(event) {
        this.isSaving = false;
        const msg = (event.detail && event.detail.message) ? event.detail.message : 'Error al guardar';
        this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: msg, variant: 'error' }));
    }
}
