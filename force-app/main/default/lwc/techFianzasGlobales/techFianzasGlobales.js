import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getFianzasList from '@salesforce/apex/TechFianzaController.getFianzasList';

export default class TechFianzasGlobales extends NavigationMixin(LightningElement) {
    @track originalData = [];
    @track filteredData = [];
    @track isLoading = true;

    @wire(getFianzasList)
    wiredFianzas({ error, data }) {
        if (data) {
            this.originalData = data;
            this.filteredData = data;
            this.isLoading = false;
        } else if (error) {
            console.error('Error loading fianzas globales:', error);
            this.isLoading = false;
        }
    }

    handleSearch(event) {
        const searchTerm = event.target.value.toLowerCase();
        if (!searchTerm) {
            this.filteredData = [...this.originalData];
            return;
        }

        this.filteredData = this.originalData.filter(item => 
            (item.name && item.name.toLowerCase().includes(searchTerm)) ||
            (item.contratista && item.contratista.toLowerCase().includes(searchTerm))
        );
    }

    handleNew() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Fianza__c',
                actionName: 'new'
            }
        });
    }

    get hasResults() {
        return this.filteredData && this.filteredData.length > 0;
    }
}
