import { LightningElement, wire } from 'lwc';
import getFianzasList from '@salesforce/apex/TechFianzaController.getFianzasList';

export default class TechFianzas extends LightningElement {
    fianzas;
    error;

    @wire(getFianzasList)
    wiredFianzas({ error, data }) {
        if (data) {
            this.fianzas = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.fianzas = undefined;
            console.error('Error al cargar fianzas:', error);
        }
    }
}
