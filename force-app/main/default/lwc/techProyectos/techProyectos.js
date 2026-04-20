import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getProyectosList from '@salesforce/apex/TechProyectoController.getProyectosList';

export default class TechProyectos extends LightningElement {
    @track proyectosOriginales = [];
    @track proyectosFiltrados = [];
    searchTerm = '';
    error;
    isLoading = true;
    isCreateModalOpen = false;
    wiredProyectosResult;

    @wire(getProyectosList)
    wiredProyectos(result) {
        this.wiredProyectosResult = result;
        const { error, data } = result;
        this.isLoading = true;
        if (data) {
            this.proyectosOriginales = data;
            this.filterData();
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.proyectosOriginales = [];
            console.error('Error al cargar proyectos:', error);
        }
        this.isLoading = false;
    }

    handleSearch(event) {
        this.searchTerm = event.target.value.toLowerCase();
        this.filterData();
    }

    filterData() {
        if (!this.searchTerm) {
            this.proyectosFiltrados = [...this.proyectosOriginales];
        } else {
            this.proyectosFiltrados = this.proyectosOriginales.filter(p => 
                (p.name && p.name.toLowerCase().includes(this.searchTerm)) ||
                (p.beneficiarios && p.beneficiarios.some(ben => ben.toLowerCase().includes(this.searchTerm))) ||
                (p.estatus && p.estatus.toLowerCase().includes(this.searchTerm))
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
        return refreshApex(this.wiredProyectosResult);
    }
}
