import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getAfianzadoList from '@salesforce/apex/TechAfianzadoController.getAfianzadoList';

export default class TechAfianzados extends LightningElement {
    @track originalData = [];
    @track filteredData = [];
    searchTerm = '';
    error;
    isLoading = true;
    isCreateModalOpen = false;
    wiredResult;

    @wire(getAfianzadoList)
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
            console.error('Error al cargar afianzados:', error);
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
                (item.rfc && item.rfc.toLowerCase().includes(this.searchTerm))
            );
        }
    }

    get hasResults() {
        return this.filteredData && this.filteredData.length > 0;
    }

    handleOpenCreateModal() { this.isCreateModalOpen = true; }
    handleCloseCreateModal() { this.isCreateModalOpen = false; }
    handleCreateSuccess() {
        this.isCreateModalOpen = false;
        return refreshApex(this.wiredResult);
    }
}
