import { LightningElement, wire } from 'lwc';
import getAfianzadosList from '@salesforce/apex/TechAfianzadoController.getAfianzadosList';

export default class TechAfianzados extends LightningElement {
    @wire(getAfianzadosList)
    afianzados;
}