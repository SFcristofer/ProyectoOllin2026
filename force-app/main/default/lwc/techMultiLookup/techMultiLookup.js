import { LightningElement, api, track, wire } from 'lwc';
import searchRecords from '@salesforce/apex/TechLookupController.searchRecords';

export default class TechMultiLookup extends LightningElement {
    @api label;
    @api objectApiName;
    @api placeholder = 'Buscar...';
    
    @track searchTerm = '';
    @track results = [];
    @track selectedRecords = []; // Aquí guardamos los múltiples seleccionados
    @track showDropdown = false;
    @track isLoading = false;

    // Buscar registros mientras el usuario escribe
    handleSearch(event) {
        this.searchTerm = event.target.value;
        if (this.searchTerm.length >= 2) {
            this.isLoading = true;
            this.showDropdown = true;
            searchRecords({ searchTerm: this.searchTerm, objectApiName: this.objectApiName })
                .then(data => {
                    this.results = data;
                    this.isLoading = false;
                })
                .catch(error => {
                    console.error('Error en búsqueda:', error);
                    this.isLoading = false;
                });
        } else {
            this.results = [];
            this.showDropdown = false;
        }
    }

    // Seleccionar un registro de la lista
    handleSelect(event) {
        const id = event.currentTarget.dataset.id;
        const label = event.currentTarget.dataset.label;

        // Evitar duplicados
        if (!this.selectedRecords.find(r => r.value === id)) {
            this.selectedRecords.push({ label: label, value: id });
            this.notifyParent();
        }
        this.clearSearch();
    }

    // Quitar un "chip" (pill)
    handleRemove(event) {
        const id = event.detail.name;
        this.selectedRecords = this.selectedRecords.filter(r => r.value !== id);
        this.notifyParent();
    }

    // Simular creación de nuevo registro (abre evento)
    handleCreateNew() {
        this.dispatchEvent(new CustomEvent('createnew', {
            detail: { objectApiName: this.objectApiName, searchTerm: this.searchTerm }
        }));
        this.clearSearch();
    }

    clearSearch() {
        this.searchTerm = '';
        this.results = [];
        this.showDropdown = false;
    }

    notifyParent() {
        // Enviamos todos los IDs seleccionados al padre
        const selectedIds = this.selectedRecords.map(r => r.value);
        this.dispatchEvent(new CustomEvent('selectionchange', {
            detail: { selectedIds: selectedIds }
        }));
    }

    // Cerrar dropdown si se hace clic fuera (simple)
    handleBlur() {
        setTimeout(() => { this.showDropdown = false; }, 200);
    }
}