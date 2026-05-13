import { LightningElement, track } from 'lwc';

const TABS = [
    'fianzas', 'endosos', 'contratos', 'convenios', 'planpagos',
    'recibos', 'comisiones', 'proyectos', 'contratistas', 'beneficiarios', 'afianzados'
];

export default class TechProspeccion extends LightningElement {
    @track activeTab = 'fianzas';

    handleTab(e) {
        this.activeTab = e.currentTarget.dataset.tab;
    }

    _tabClass(tab)  { return 'ot-tab' + (this.activeTab === tab ? ' ot-tab-active' : ''); }
    _panelClass(tab){ return 'ot-panel' + (this.activeTab === tab ? '' : ' ot-hidden'); }

    get tabClass0()  { return this._tabClass(TABS[0]);  }
    get tabClass1()  { return this._tabClass(TABS[1]);  }
    get tabClass2()  { return this._tabClass(TABS[2]);  }
    get tabClass3()  { return this._tabClass(TABS[3]);  }
    get tabClass4()  { return this._tabClass(TABS[4]);  }
    get tabClass5()  { return this._tabClass(TABS[5]);  }
    get tabClass6()  { return this._tabClass(TABS[6]);  }
    get tabClass7()  { return this._tabClass(TABS[7]);  }
    get tabClass8()  { return this._tabClass(TABS[8]);  }
    get tabClass9()  { return this._tabClass(TABS[9]);  }
    get tabClass10() { return this._tabClass(TABS[10]); }

    get panelClass0()  { return this._panelClass(TABS[0]);  }
    get panelClass1()  { return this._panelClass(TABS[1]);  }
    get panelClass2()  { return this._panelClass(TABS[2]);  }
    get panelClass3()  { return this._panelClass(TABS[3]);  }
    get panelClass4()  { return this._panelClass(TABS[4]);  }
    get panelClass5()  { return this._panelClass(TABS[5]);  }
    get panelClass6()  { return this._panelClass(TABS[6]);  }
    get panelClass7()  { return this._panelClass(TABS[7]);  }
    get panelClass8()  { return this._panelClass(TABS[8]);  }
    get panelClass9()  { return this._panelClass(TABS[9]);  }
    get panelClass10() { return this._panelClass(TABS[10]); }
}