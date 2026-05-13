import { LightningElement, wire, track } from 'lwc';
import getKPIs from '@salesforce/apex/TechVentasController.getKPIs';
import getOportunidades from '@salesforce/apex/TechVentasController.getOportunidades';

const SPARK = {
    leads:    [18,22,19,25,21,28,24,30,26,31,28,34],
    nuevos:   [5,7,6,8,7,9,8,10,9,11,10,12],
    pipeline: [120,135,128,142,138,155,148,162,158,170,165,178],
    opps:     [15,18,16,20,18,22,20,24,22,25,23,26],
    ganados:  [8,10,9,11,10,13,12,14,13,15,14,16],
    tasa:     [42,45,43,47,44,48,46,50,48,51,49,53],
    ticket:   [85,92,88,95,91,98,94,102,98,105,101,108],
    tiempo:   [22,24,23,21,20,22,21,19,20,18,19,17],
    renov:    [3,4,3,5,4,6,5,7,6,8,7,9],
};
const MONTHS     = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
const MVALS      = [8,12,10,15,13,18,16,20,17,22,19,25];
const SRC_COLORS = ['#8b5cf6','#3b82f6','#10b981','#f59e0b','#ef4444'];
const EXEC_COLORS= ['#10b981','#3b82f6','#8b5cf6','#f59e0b'];

function sparkPath(vals) {
    const W = 80, H = 28;
    if (!vals || vals.length < 2) return '';
    const mn = Math.min(...vals);
    const rng = (Math.max(...vals) - mn) || 1;
    return vals.map((v, i) => {
        const x = ((i / (vals.length - 1)) * W).toFixed(1);
        const y = (H - ((v - mn) / rng) * H * 0.82 - 2).toFixed(1);
        return x + ',' + y;
    }).join(' ');
}

function fmtM(n) {
    if (!n) return '$0';
    if (n >= 1000000) return '$' + (n / 1000000).toFixed(1) + 'M';
    if (n >= 1000)    return '$' + Math.round(n / 1000) + 'K';
    return '$' + Math.round(n);
}

// Mapeo stageName Salesforce → clave interna del funnel
const STAGE_MAP = {
    'cotización':                      'cotizacion',
    'cotizacion':                      'cotizacion',
    'propuesta enviada':               'prospecto',
    'propuesta enviada / presentada':  'prospecto',
    'negociación':                     'negociacion',
    'negociacion':                     'negociacion',
    'seguimiento':                     'negociacion',
    'cierre ganado':                   'cierre',
    'closed won':                      'cierre',
    'cierre perdido':                  'perdido',
    'closed lost':                     'perdido',
};

const FUNNEL_DEFS = [
    { id:'captacion',   label:'Captación',   desc:'Leads generados',     color:'#8b5cf6', time:'—'   },
    { id:'prospecto',   label:'Prospecto',   desc:'Calificación inicial', color:'#6366f1', time:'3d'  },
    { id:'cotizacion',  label:'Cotización',  desc:'Propuesta enviada',    color:'#3b82f6', time:'7d'  },
    { id:'negociacion', label:'Negociación', desc:'En proceso',           color:'#f59e0b', time:'14d' },
    { id:'cierre',      label:'Cierre',      desc:'Contrato firmado',     color:'#10b981', time:'5d'  },
    { id:'postventa',   label:'Postventa',   desc:'Renovaciones',         color:'#06b6d4', time:'—'   },
];

export default class TechVentasDashboard extends LightningElement {
    @track kpis = { leadsActivos:0, oppsEnPipeline:0, cierresGanados:0, cierresPerdidos:0, tasaCierre:0, montoTotalPipeline:0 };
    @track oportunidades = [];
    @track selectedStage = null;

    // Filtros
    @track filterPeriod    = 'year';
    @track filterEjecutivo = 'all';
    @track filterOrigen    = 'all';

    // ── LIFECYCLE ──────────────────────────────────────────────
    connectedCallback() {
        // getOportunidades no es cacheable → llamada imperativa
        getOportunidades({ filtersJson: null })
            .then(data  => { this.oportunidades = data || []; })
            .catch(() => {});
    }

    @wire(getKPIs)
    wireKPIs({ data }) { if (data) this.kpis = data; }

    // ── FILTROS ────────────────────────────────────────────────
    get hasActiveFilters() {
        return this.filterPeriod !== 'year' || this.filterEjecutivo !== 'all' || this.filterOrigen !== 'all';
    }

    get filteredOpps() {
        let opps = this.oportunidades;
        if (!opps || !opps.length) return [];

        if (this.filterPeriod !== 'year') {
            const now = new Date(), yr = now.getFullYear(), mo = now.getMonth();
            const Q_RANGE = { q1:[0,2], q2:[3,5], q3:[6,8], q4:[9,11] };
            opps = opps.filter(o => {
                if (!o.closeDate) return true;
                const d = new Date(o.closeDate), dm = d.getMonth();
                if (this.filterPeriod === 'month') return d.getFullYear() === yr && dm === mo;
                const range = Q_RANGE[this.filterPeriod];
                if (range) return d.getFullYear() === yr && dm >= range[0] && dm <= range[1];
                return true;
            });
        }
        if (this.filterEjecutivo !== 'all') {
            opps = opps.filter(o => o.vendedor === this.filterEjecutivo);
        }
        if (this.filterOrigen !== 'all') {
            opps = opps.filter(o => o.leadSource === this.filterOrigen);
        }
        return opps;
    }

    get computedKPIs() {
        const opps = this.filteredOpps;

        if (!this.hasActiveFilters && !opps.length) {
            return { ...this.kpis, revenueTotal: this.kpis.montoTotalPipeline };
        }

        let ganados = 0, perdidos = 0, pipeline = 0, monto = 0, revenue = 0;
        opps.forEach(o => {
            const s = (o.stageName || '').toLowerCase();
            const isGanado  = s.includes('ganado') || s.includes('won');
            const isPerdido = s.includes('perdido') || s.includes('lost');
            if (isGanado)       { ganados++; revenue += (o.amount || 0); }
            else if (isPerdido) { perdidos++; }
            else                { pipeline++; monto += (o.amount || 0); revenue += (o.amount || 0); }
        });
        const total = ganados + perdidos;

        if (!this.hasActiveFilters) {
            // Sin filtro: usar KPIs de Apex pero calcular revenueTotal desde opps
            return { ...this.kpis, revenueTotal: revenue };
        }

        return {
            leadsActivos:       this.kpis.leadsActivos,
            oppsEnPipeline:     pipeline,
            cierresGanados:     ganados,
            cierresPerdidos:    perdidos,
            tasaCierre:         total > 0 ? ((ganados / total) * 100).toFixed(1) : 0,
            montoTotalPipeline: monto,
            revenueTotal:       revenue,
        };
    }

    // ── OPCIONES DE FILTRO ─────────────────────────────────────
    get ejecutivoOptions() {
        const seen = new Set();
        const opts = [{ value:'all', label:'Todos los ejecutivos', selected: this.filterEjecutivo === 'all' }];
        (this.oportunidades || []).forEach(o => {
            if (o.vendedor && !seen.has(o.vendedor)) {
                seen.add(o.vendedor);
                opts.push({ value: o.vendedor, label: o.vendedor, selected: this.filterEjecutivo === o.vendedor });
            }
        });
        return opts;
    }

    get origenOptions() {
        const seen = new Set();
        const opts = [{ value:'all', label:'Todos los orígenes', selected: this.filterOrigen === 'all' }];
        (this.oportunidades || []).forEach(o => {
            if (o.leadSource && !seen.has(o.leadSource)) {
                seen.add(o.leadSource);
                opts.push({ value: o.leadSource, label: o.leadSource, selected: this.filterOrigen === o.leadSource });
            }
        });
        return opts;
    }

    // ── CHIP CLASSES ───────────────────────────────────────────
    _chip(p) { return 'vdb-chip' + (this.filterPeriod === p ? ' vdb-chip-active' : ''); }
    get chipYearCls()  { return this._chip('year');  }
    get chipQ1Cls()    { return this._chip('q1');    }
    get chipQ2Cls()    { return this._chip('q2');    }
    get chipQ3Cls()    { return this._chip('q3');    }
    get chipQ4Cls()    { return this._chip('q4');    }
    get chipMonthCls() { return this._chip('month'); }

    // ── HANDLERS ──────────────────────────────────────────────
    handlePeriodFilter(evt)   { this.filterPeriod    = evt.currentTarget.dataset.period; }
    handleEjecutivoChange(evt){ this.filterEjecutivo = evt.target.value; }
    handleOrigenChange(evt)   { this.filterOrigen    = evt.target.value; }
    handleClearFilters()      { this.filterPeriod = 'year'; this.filterEjecutivo = 'all'; this.filterOrigen = 'all'; }

    handleStageClick(evt) {
        const id = evt.currentTarget.dataset.id;
        this.selectedStage = this.selectedStage === id ? null : id;
    }
    handleCloseDetail() { this.selectedStage = null; }

    // ── DETALLE DE ETAPA ───────────────────────────────────────
    get hasSelectedStage() { return !!this.selectedStage; }

    get selectedStageLabel() {
        const def = FUNNEL_DEFS.find(d => d.id === this.selectedStage);
        return def ? def.label : '';
    }

    get selectedStageDotStyle() {
        const def = FUNNEL_DEFS.find(d => d.id === this.selectedStage);
        return def ? 'background:' + def.color : '';
    }

    get selectedStageOpps() {
        if (!this.selectedStage) return [];
        return this.filteredOpps
            .filter(o => {
                const key = STAGE_MAP[(o.stageName || '').toLowerCase()] || 'captacion';
                return key === this.selectedStage;
            })
            .map(o => ({
                ...o,
                // Oportunidades en etapas tempranas usan Prospecto__r, no Account
                displayClient: o.clientName || o.prospectoName || '—',
            }));
    }

    get noStageOpps() { return this.selectedStageOpps.length === 0; }

    // ── KPI CARDS ─────────────────────────────────────────────
    get currentYear() { return new Date().getFullYear(); }

    get ticketPromedio() {
        const k = this.computedKPIs;
        return k.cierresGanados ? Math.round(k.montoTotalPipeline / k.cierresGanados) : 0;
    }

    get kpiCards() {
        const k       = this.computedKPIs;
        const tp      = this.ticketPromedio;
        const global  = this.hasActiveFilters; // Leads vienen de query separada, no filtran con opps
        const mk = (id, label, value, sub, trendVal, trendUp, color, sparkKey, isGlobal) => ({
            id, label, value, sub, trendVal,
            isGlobal:  !!isGlobal,
            trendCls:  'vdb-trend ' + (trendUp ? 'vdb-trend-up' : 'vdb-trend-dn'),
            cls:        'vdb-kpi ' + color,
            sparkPath:  sparkPath(SPARK[sparkKey]),
        });
        return [
            mk('leads',    'Leads activos',         k.leadsActivos,              '+12% vs mes ant.', '+12%', true,  'kpi-blue',    'leads',    global),
            mk('nuevos',   'Leads nuevos (mes)',     28,                          'Este mes',         '+8%',  true,  'kpi-indigo',  'nuevos',   global),
            mk('pipeline', 'Pipeline total',         fmtM(k.montoTotalPipeline),  k.oppsEnPipeline + ' opps abiertas', '+18%', true, 'kpi-violet', 'pipeline'),
            mk('revenue',  'Revenue total',          fmtM(k.revenueTotal || 0),   'Ganado + abierto', '+15%', true,  'kpi-teal',    'pipeline'),
            mk('opps',     'Opps abiertas',          k.oppsEnPipeline,            'En proceso',       '-3%',  false, 'kpi-sky',     'opps'),
            mk('ganados',  'Cierres ganados',        k.cierresGanados,            'Año en curso',     '+22%', true,  'kpi-green',   'ganados'),
            mk('tasa',     'Tasa de cierre',         k.tasaCierre + '%',          'Promedio acum.',   '+4%',  true,  'kpi-emerald', 'tasa'),
            mk('ticket',   'Ticket promedio',        fmtM(tp),                    'Por cierre',       '+7%',  true,  'kpi-amber',   'ticket'),
            mk('tiempo',   'Días prom. cierre',      19,                          'Lead → Póliza',    '−2d',  true,  'kpi-orange',  'tiempo'),
            mk('renov',    'Renovaciones próximas',  7,                           'Próx. 30 días',    '!',    false, 'kpi-rose',    'renov'),
        ];
    }

    // ── FUNNEL ────────────────────────────────────────────────
    get funnelStages() {
        const opps = this.filteredOpps;
        const cnt  = { captacion:0, prospecto:0, cotizacion:0, negociacion:0, cierre:0, postventa:0 };
        const mnt  = { captacion:0, prospecto:0, cotizacion:0, negociacion:0, cierre:0, postventa:0 };

        opps.forEach(o => {
            const key = STAGE_MAP[(o.stageName || '').toLowerCase()] || 'captacion';
            if (cnt[key] !== undefined) { cnt[key]++; mnt[key] += (o.amount || 0); }
        });

        // Captación = opps sin etapa reconocida + leads (solo para la barra visual)
        // NO inflamos con leadsActivos para no generar discrepancia en el detalle
        // Prospecto = solo opps reales mapeadas (sin estimaciones)

        const maxCnt = Math.max(...FUNNEL_DEFS.map(d => cnt[d.id] || 0), 1);

        return FUNNEL_DEFS.map((d, i) => {
            const c    = cnt[d.id] || 0;
            const m    = mnt[d.id] || 0;
            const prev = i > 0 ? (cnt[FUNNEL_DEFS[i-1].id] || 1) : c;
            const conv = prev > 0 ? Math.round((c / prev) * 100) : 100;
            const pct  = Math.round((c / maxCnt) * 100);
            const sel  = this.selectedStage === d.id;
            return {
                ...d,
                count: c, monto: fmtM(m), conv, pct,
                cls:      'vdb-fs' + (sel ? ' vdb-fs-sel' : ''),
                barStyle: 'width:' + pct + '%;background:' + d.color,
                convCls:  'vdb-conv ' + (conv >= 70 ? 'vdb-conv-g' : conv >= 45 ? 'vdb-conv-y' : 'vdb-conv-r'),
                dotStyle: 'background:' + d.color,
            };
        });
    }

    // ── CHARTS ────────────────────────────────────────────────
    get leadSources() {
        const opps = this.filteredOpps;
        const counts = {};
        opps.forEach(o => {
            if (o.leadSource) counts[o.leadSource] = (counts[o.leadSource] || 0) + 1;
        });
        const entries = Object.entries(counts).sort((a,b) => b[1] - a[1]).slice(0, 5);
        if (!entries.length) {
            return [
                { id:'ref', label:'Referidos',    count:35, style:'width:85%;background:#8b5cf6' },
                { id:'web', label:'Web / Digital', count:28, style:'width:68%;background:#3b82f6' },
                { id:'dir', label:'Venta directa', count:20, style:'width:50%;background:#10b981' },
                { id:'eve', label:'Eventos',        count:12, style:'width:30%;background:#f59e0b' },
                { id:'oth', label:'Otros',          count:5,  style:'width:12%;background:#d1d5db' },
            ];
        }
        const maxV = entries[0][1];
        return entries.map(([label, count], i) => ({
            id: label, label, count,
            style: 'width:' + Math.round((count/maxV)*100) + '%;background:' + SRC_COLORS[i],
        }));
    }

    get topEjecutivos() {
        const opps = this.filteredOpps;
        const ejecs = {};
        opps.forEach(o => {
            if (!o.vendedor) return;
            if (!ejecs[o.vendedor]) ejecs[o.vendedor] = { name: o.vendedor, deals:0, monto:0 };
            const s = (o.stageName || '').toLowerCase();
            if (s.includes('ganado') || s.includes('won')) {
                ejecs[o.vendedor].deals++;
                ejecs[o.vendedor].monto += (o.amount || 0);
            }
        });
        const sorted = Object.values(ejecs).sort((a,b) => b.monto - a.monto).slice(0, 4);
        if (!sorted.length) {
            return [
                { id:1, initials:'CM', name:'Carlos M.', deals:12, monto:'$1.2M', pct:94, avatarStyle:'background:#10b981', barStyle:'width:94%;background:#10b981' },
                { id:2, initials:'AR', name:'Ana R.',    deals:9,  monto:'$890K', pct:78, avatarStyle:'background:#3b82f6', barStyle:'width:78%;background:#3b82f6' },
                { id:3, initials:'LP', name:'Luis P.',   deals:7,  monto:'$720K', pct:65, avatarStyle:'background:#8b5cf6', barStyle:'width:65%;background:#8b5cf6' },
                { id:4, initials:'MG', name:'Maria G.',  deals:5,  monto:'$510K', pct:48, avatarStyle:'background:#f59e0b', barStyle:'width:48%;background:#f59e0b' },
            ];
        }
        const maxM = sorted[0].monto || 1;
        return sorted.map((e, i) => {
            const initials = e.name.split(' ').slice(0,2).map(n => n.charAt(0)).join('').toUpperCase();
            const pct = Math.round((e.monto / maxM) * 100);
            const col = EXEC_COLORS[i] || '#6b7280';
            return {
                id: i+1, initials, name: e.name, deals: e.deals, monto: fmtM(e.monto), pct,
                avatarStyle: 'background:' + col,
                barStyle:    'width:' + pct + '%;background:' + col,
            };
        });
    }

    get alerts() {
        return [
            { id:1, dot:'vdb-adot dot-r', label:'Seguimientos vencidos', detail:'5 opps sin actividad > 7 días',  count:5, cls:'vdb-alert-row alert-r' },
            { id:2, dot:'vdb-adot dot-y', label:'Pólizas por vencer',    detail:'3 vencen en los próx. 30 días',  count:3, cls:'vdb-alert-row alert-y' },
            { id:3, dot:'vdb-adot dot-b', label:'Baja conversión',        detail:'Negociación bajo 40%',           count:1, cls:'vdb-alert-row alert-b' },
            { id:4, dot:'vdb-adot dot-y', label:'Opps estancadas',        detail:'8 sin avanzar > 14 días',        count:8, cls:'vdb-alert-row alert-y' },
        ];
    }

    get actividad() {
        return [
            { id:1, tipo:'Cierre ganado',      nombre:'Póliza Auto — Juan Torres',    tiempo:'Hace 2h',   dot:'vdb-adot dot-g' },
            { id:2, tipo:'Nuevo lead',          nombre:'Prospecto referido — ACME SA', tiempo:'Hace 4h',   dot:'vdb-adot dot-b' },
            { id:3, tipo:'Cotización enviada',  nombre:'GMM Colectivo — Empresa XYZ', tiempo:'Ayer',      dot:'vdb-adot dot-v' },
            { id:4, tipo:'Seguimiento vencido', nombre:'Vida Individual — Pedro R.',  tiempo:'Hace 2d',   dot:'vdb-adot dot-r' },
            { id:5, tipo:'Renovación próxima',  nombre:'Autos Flotilla — Grupo ABC',  tiempo:'En 5 días', dot:'vdb-adot dot-y' },
        ];
    }

    get monthlyTrend() {
        const now  = new Date().getMonth();
        const maxV = Math.max(...MVALS);
        return MONTHS.slice(0, now + 1).map((m, i) => ({
            id: m, label: m, value: MVALS[i],
            barStyle: 'height:' + Math.round((MVALS[i] / maxV) * 100) + '%',
        }));
    }
}
