import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getContratosList from '@salesforce/apex/TechContratoController.getContratosList';

export default class TechContratos extends LightningElement {
    @track contratosOriginales = [];
    @track contratosFiltrados = [];
    searchTerm = '';
    error;
    isLoading = true;
    isCreateModalOpen = false;
    wiredContratosResult;

    @wire(getContratosList)
    wiredContratos(result) {
        this.wiredContratosResult = result;
        const { error, data } = result;
        this.isLoading = true;
        if (data) {
            this.contratosOriginales = data;
            this.filterData();
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.contratosOriginales = [];
            console.error('Error al cargar contratos:', error);
        }
        this.isLoading = false;
    }

    handleSearch(event) {
        this.searchTerm = event.target.value.toLowerCase();
        this.filterData();
    }

    filterData() {
        if (!this.searchTerm) {
            this.contratosFiltrados = [...this.contratosOriginales];
        } else {
            this.contratosFiltrados = this.contratosOriginales.filter(c => 
                (c.name && c.name.toLowerCase().includes(this.searchTerm)) ||
                (c.contratistas && c.contratistas.some(con => con.toLowerCase().includes(this.searchTerm))) ||
                (c.estatus && c.estatus.toLowerCase().includes(this.searchTerm))
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
        return refreshApex(this.wiredContratosResult);
    }
}
