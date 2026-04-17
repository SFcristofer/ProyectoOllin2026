import { LightningElement, wire } from 'lwc';
import getProyectosList from '@salesforce/apex/TechProyectoController.getProyectosList';

export default class TechProyectos extends LightningElement {
    proyectos;
    error;

    @wire(getProyectosList)
    wiredProyectos({ error, data }) {
        if (data) {
            this.proyectos = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.proyectos = undefined;
            console.error('Error al cargar proyectos:', error);
        }
    }
}
