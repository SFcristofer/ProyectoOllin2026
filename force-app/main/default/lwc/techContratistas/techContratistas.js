import { LightningElement, wire } from 'lwc';
import getContratistasList from '@salesforce/apex/TechContratistaController.getContratistasList';

export default class TechContratistas extends LightningElement {
    @wire(getContratistasList)
    contratistas;
}