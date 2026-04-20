import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getFianzasList from '@salesforce/apex/TechFianzaController.getFianzasList';

export default class TechFianzas extends LightningElement {
    @track fianzasOriginales = [];
    @track fianzasFiltradas = [];
    searchTerm = '';
    error;
    isLoading = true;
    isCreateModalOpen = false;
    wiredFianzasResult;

    @wire(getFianzasList)
    wiredFianzas(result) {
        this.wiredFianzasResult = result;
        const { error, data } = result;
        this.isLoading = true;
        if (data) {
            this.fianzasOriginales = data;
            this.filterData();
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.fianzasOriginales = [];
        }
        this.isLoading = false;
    }

    handleSearch(event) {
        this.searchTerm = event.target.value.toLowerCase();
        this.filterData();
    }

    filterData() {
        if (!this.searchTerm) {
            this.fianzasFiltradas = [...this.fianzasOriginales];
        } else {
            this.fianzasFiltradas = this.fianzasOriginales.filter(f => 
                (f.name && f.name.toLowerCase().includes(this.searchTerm)) ||
                (f.contratista && f.contratista.toLowerCase().includes(this.searchTerm)) ||
                (f.estatus && f.estatus.toLowerCase().includes(this.searchTerm))
            );
        }
    }

    handleOpenCreateModal() {
        this.isCreateModalOpen = true;
    }

    handleCloseCreateModal() {
        this.isCreateModalOpen = false;
    }

    handleCreateSuccess() {
        this.isCreateModalOpen = false;
        // Refrescar los datos de la tabla automáticamente
        return refreshApex(this.wiredFianzasResult);
    }

    handleFilterMenu() {}
    handleSort() {}
}
