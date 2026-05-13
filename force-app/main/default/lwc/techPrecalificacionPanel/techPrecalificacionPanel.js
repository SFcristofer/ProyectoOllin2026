import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TechPrecalificacionPanel extends LightningElement {
    @api contratistaId;
    @track isSaving = false;

    handleSuccess(event) {
        this.isSaving = false;
        this.dispatchEvent(new ShowToastEvent({
            title: 'Precalificación creada',
            message: event.detail.fields.Name?.value || 'Registro guardado correctamente',
            variant: 'success'
        }));
        this.dispatchEvent(new CustomEvent('success', { detail: { id: event.detail.id } }));
    }

    handleError(event) {
        this.isSaving = false;
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error al guardar',
            message: event.detail?.detail || event.detail?.message || 'Revisa los campos requeridos',
            variant: 'error'
        }));
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}