import { LightningElement, wire } from 'lwc';
import getAmpliacionesList from '@salesforce/apex/TechAmpliacionController.getAmpliacionesList';

export default class TechAmpliaciones extends LightningElement {
    @wire(getAmpliacionesList)
    ampliaciones;
}