import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TechPlanPagoCreateModal extends LightningElement {
    @api showModal = false;

    handleClose()   { this.dispatchEvent(new CustomEvent('close')); }
    handleSuccess() { this.dispatchEvent(new ShowToastEvent({ title: 'Creado', message: 'Plan de Pago creado.', variant: 'success' })); this.dispatchEvent(new CustomEvent('success')); }
    handleError(e)  { this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: e.detail?.detail || 'No se pudo crear.', variant: 'error' })); }
}