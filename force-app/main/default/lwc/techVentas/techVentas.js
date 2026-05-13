import { LightningElement, track } from 'lwc';

const TABS = ['dashboard', 'leads', 'oportunidades', 'polizas', 'fianzas', 'catalogos'];

export default class TechVentas extends LightningElement {
    @track activeTab       = 'dashboard';
    @track dashSubTab      = 'gestion';
    @track polizasFocus    = null;
    @track modalOpen       = false;
    @track editRecord      = null;
    @track editLeadRecord  = null;
    @track prefillLeadData = null;
    @track modalInitialType = 'opp';

    handleTab(e)        { this.activeTab  = e.currentTarget.dataset.tab; }
    handleDashSubTab(e) { this.dashSubTab = e.currentTarget.dataset.subtab; }

    handleInternalNav(e) {
        const { id, tipo, numero } = e.detail;
        this.polizasFocus = { id, tipo, numero };
        this.activeTab    = 'polizas';
    }

    _tabClass(tab)      { return 'ot-tab'       + (this.activeTab  === tab ? ' ot-tab-active' : ''); }
    _panelClass(tab)    { return 'ot-panel'     + (this.activeTab  === tab ? '' : ' ot-hidden'); }
    _dshTabClass(tab)   { return 'ot-dash-tab'  + (this.dashSubTab === tab ? ' ot-dash-tab-active' : ''); }
    _dshPanelClass(tab) { return 'ot-dash-body' + (this.dashSubTab === tab ? '' : ' ot-hidden'); }

    get tabClass0()   { return this._tabClass(TABS[0]); }
    get tabClass1()   { return this._tabClass(TABS[1]); }
    get tabClass2()   { return this._tabClass(TABS[2]); }
    get tabClass3()   { return this._tabClass(TABS[3]); }
    get tabClass4()   { return this._tabClass(TABS[4]); }
    get tabClass5()   { return this._tabClass(TABS[5]); }
    get panelClass0() { return this._panelClass(TABS[0]); }
    get panelClass1() { return this._panelClass(TABS[1]); }
    get panelClass2() { return this._panelClass(TABS[2]); }
    get panelClass3() { return this._panelClass(TABS[3]); }
    get panelClass4() { return this._panelClass(TABS[4]); }
    get panelClass5() { return this._panelClass(TABS[5]); }

    get dshTabClass0()   { return this._dshTabClass('gestion'); }
    get dshTabClass1()   { return this._dshTabClass('embudo'); }
    get dshPanelClass0() { return this._dshPanelClass('gestion'); }
    get dshPanelClass1() { return this._dshPanelClass('embudo'); }

    handleNuevoLead()     { this.editRecord = null; this.editLeadRecord = null; this.prefillLeadData = null; this.modalInitialType = 'lead'; this.modalOpen = true; }
    handleNuevaOpp()      { this.editRecord = null; this.editLeadRecord = null; this.prefillLeadData = null; this.modalInitialType = 'opp';  this.modalOpen = true; }
    handleEditOpen(e)     { this.editLeadRecord = null; this.prefillLeadData = null; this.editRecord     = e.detail; this.modalOpen = true; }
    handleLeadEditOpen(e) { this.editRecord     = null; this.prefillLeadData = null; this.editLeadRecord = e.detail; this.modalOpen = true; }

    handleConvertirLeadAOpp(e) {
        this.editRecord      = null;
        this.editLeadRecord  = null;
        this.prefillLeadData = e.detail;
        this.modalOpen       = true;
        this.activeTab       = 'oportunidades';
    }

    handleModalClose() {
        this.modalOpen = false; this.editRecord = null; this.editLeadRecord = null; this.prefillLeadData = null;
    }

    handleSaved() {
        this.modalOpen = false; this.editRecord = null; this.editLeadRecord = null; this.prefillLeadData = null;
        this.template.querySelector('c-tech-ventas-dashboard')?.refresh?.();
        this.template.querySelector('c-tech-ventas-leads')?.refresh?.();
        this.template.querySelector('c-tech-ventas-pipeline')?.refresh?.();
    }
}
