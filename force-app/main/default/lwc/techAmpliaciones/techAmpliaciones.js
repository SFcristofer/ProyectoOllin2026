import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getAmpliacionesList from '@salesforce/apex/TechAmpliacionController.getAmpliacionesList';

export default class TechAmpliaciones extends LightningElement {
    @track originalData = [];
    @track filteredData = [];
    searchTerm = '';
    error;
    isLoading = true;
    isCreateModalOpen = false;
    wiredResult;

    @wire(getAmpliacionesList)
    wiredData(result) {
        this.wiredResult = result;
        const { error, data } = result;
        this.isLoading = true;
        if (data) {
            this.originalData = data;
            this.filterData();
            this.error = undefined;
        } else if (error) {
            this.error = error;
            console.error('Error al cargar ampliaciones:', error);
        }
        this.isLoading = false;
    }

    handleSearch(event) {
        this.searchTerm = event.target.value.toLowerCase();
        this.filterData();
    }

    filterData() {
        if (!this.searchTerm) {
            this.filteredData = [...this.originalData];
        } else {
            this.filteredData = this.originalData.filter(item => 
                (item.name && item.name.toLowerCase().includes(this.searchTerm)) ||
                (item.fianzas && item.fianzas.some(f => f.toLowerCase().includes(this.searchTerm)))
            );
        }
    }

    handleOpenCreateModal() { this.isCreateModalOpen = true; }
    handleCloseCreateModal() { this.isCreateModalOpen = false; }
    handleCreateSuccess() {
        this.isCreateModalOpen = false;
        return refreshApex(this.wiredResult);
    }
}
