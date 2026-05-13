import { LightningElement, track } from 'lwc';

const TABS = ['contratista', 'precalificaciones', 'institucion', 'beneficiario', 'vendedor', 'cuentas'];

export default class TechVentasCatalogos extends LightningElement {
    @track activeTab = 'contratista';

    handleSubTab(e) { this.activeTab = e.currentTarget.dataset.tab; }

    _cls(tab) { return 'vc-subtab' + (this.activeTab === tab ? ' vc-subtab-active' : ''); }

    get stClassContratista()       { return this._cls(TABS[0]); }
    get stClassPrecalificaciones() { return this._cls(TABS[1]); }
    get stClassInstitucion()       { return this._cls(TABS[2]); }
    get stClassBeneficiario()      { return this._cls(TABS[3]); }
    get stClassVendedor()          { return this._cls(TABS[4]); }
    get stClassCuentas()           { return this._cls(TABS[5]); }

    get isTabContratista()       { return this.activeTab === TABS[0]; }
    get isTabPrecalificaciones() { return this.activeTab === TABS[1]; }
    get isTabInstitucion()       { return this.activeTab === TABS[2]; }
    get isTabBeneficiario()      { return this.activeTab === TABS[3]; }
    get isTabVendedor()          { return this.activeTab === TABS[4]; }
    get isTabCuentas()           { return this.activeTab === TABS[5]; }
}
