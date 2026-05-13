import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class WelcomeTab extends LightningElement {
    handleClick() {
        const event = new ShowToastEvent({
            title: '¡Listo para trabajar!',
            message: 'Este es el punto de partida de tu nueva aplicación.',
            variant: 'success',
        });
        this.dispatchEvent(event);
    }
}