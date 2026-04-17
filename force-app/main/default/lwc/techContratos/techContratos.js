import { LightningElement, wire } from 'lwc';
import getContratosList from '@salesforce/apex/TechContratoController.getContratosList';

export default class TechContratos extends LightningElement {
    @wire(getContratosList)
    contratos;
}