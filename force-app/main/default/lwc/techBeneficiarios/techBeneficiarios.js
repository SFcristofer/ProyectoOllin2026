import { LightningElement, wire } from 'lwc';
import getBeneficiariosList from '@salesforce/apex/TechBeneficiarioController.getBeneficiariosList';

export default class TechBeneficiarios extends LightningElement {
    @wire(getBeneficiariosList)
    beneficiarios;
}