import { LightningElement, api, wire, track } from 'lwc';
import getContratistaInterfacesData from '@salesforce/apex/TechContratistaController.getContratistaInterfacesData';

const BAR_CHART_H = 148;
const BAR_TOP_Y   = 22;
const BAR_BOT_Y   = BAR_TOP_Y + BAR_CHART_H;
const DONUT_CIRC  = 2 * Math.PI * 70;

export default class TechContratistaInterfaces extends LightningElement {
    @api contratistaId;
    @api contratistaName = '';
    @track isLoading = true;

    // KPI
    @track totalAfianzado       = 0;
    @track contratosCount       = 0;
    @track fianzasVencidasCount = 0;

    // Tablas
    @track contratos       = [];
    @track fianzas         = [];
    @track fianzasVencidas = [];

    // Accordion state
    @track isContratosOpen = true;
    @track isFianzasOpen   = true;
    @track isVencidasOpen  = true;

    get contratosChevron() { return this.isContratosOpen ? 'utility:chevrondown' : 'utility:chevronright'; }
    get fianzasChevron()   { return this.isFianzasOpen   ? 'utility:chevrondown' : 'utility:chevronright'; }
    get vencidasChevron()  { return this.isVencidasOpen  ? 'utility:chevrondown' : 'utility:chevronright'; }

    toggleContratos() { this.isContratosOpen = !this.isContratosOpen; }
    toggleFianzas()   { this.isFianzasOpen   = !this.isFianzasOpen; }
    toggleVencidas()  { this.isVencidasOpen  = !this.isVencidasOpen; }

    @wire(getContratistaInterfacesData, { contratistaId: '$contratistaId' })
    wiredData({ data, error }) {
        if (data) {
            const d = JSON.parse(JSON.stringify(data));
            this.totalAfianzado       = d.totalAfianzado       || 0;
            this.contratosCount       = d.contratosCount       || 0;
            this.fianzasVencidasCount = d.fianzasVencidasCount || 0;
            this.contratos = (d.contratos || []).map((c, i) => ({
                rowKey: 'co-' + i, rowNum: i + 1,
                id: c.id, name: c.name, contratista: c.contratista,
                monto: c.monto, proyecto: c.proyecto,
                montoFmt: this._fmt(c.monto),
            }));
            this.fianzas = (d.fianzas || []).map((f, i) => ({
                rowKey: 'fi-' + i, rowNum: i + 1,
                id: f.id, name: f.name, contratista: f.contratista,
                contrato: f.contrato, monto: f.monto, estatus: f.estatus,
                montoFmt: f.monto != null ? this._fmt(f.monto) : '—',
                estatusClass: this._estatusCls(f.estatus),
            }));
            this.fianzasVencidas = (d.fianzasVencidas || []).map((fv, i) => ({
                rowKey: 'fv-' + i, rowNum: i + 1,
                id: fv.id, name: fv.name, contratista: fv.contratista,
                contrato: fv.contrato, montoAfianzado: fv.montoAfianzado,
                fechaFin: fv.fechaFin, diasVigencia: fv.diasVigencia,
                diasReclamo: fv.diasReclamo, finReclamo: fv.finReclamo,
                estatus: fv.estatus,
                montoFmt: fv.montoAfianzado != null ? this._fmt(fv.montoAfianzado) : '—',
                estatusLabel: fv.estatus === 'Cancelada' ? 'Fianza cancelada' : (fv.estatus || '—'),
                estatusClass: this._estatusCls(fv.estatus),
            }));
            this.isLoading = false;
        } else if (error) {
            console.error('Error loading data:', error);
            this.totalAfianzado = 0;
            this.contratosCount = 0;
            this.fianzasVencidasCount = 0;
            this.contratos = [];
            this.fianzas = [];
            this.fianzasVencidas = [];
            this.isLoading = false;
        }
    }

    get montoAfianzadoFmt()  { return this._fmt(this.totalAfianzado); }
    get montoContratosFmt()  { 
        const total = this.contratos.reduce((s, c) => s + (c.monto || 0), 0);
        return this._fmt(total);
    }
    get fianzasCount()       { return this.fianzas.length; }

    get hasContratos()         { return this.contratos.length       > 0; }
    get hasFianzas()           { return this.fianzas.length         > 0; }
    get hasFianzasVencidas()   { return this.fianzasVencidas.length > 0; }

    get montoVencidasFmt() {
        const total = this.fianzasVencidas.reduce((s, f) => s + (f.montoAfianzado || 0), 0);
        return this._fmt(total);
    }
    get sumaVigencia() { 
        return this.fianzasVencidas.reduce((s, f) => s + (f.diasVigencia || 0), 0); 
    }
    get sumaReclamo()  { 
        return this.fianzasVencidas.reduce((s, f) => s + (f.diasReclamo  || 0), 0); 
    }

    _barData() {
        const all   = this.fianzas;
        let vigente = 0, vencida = 0;
        all.forEach(f => {
            const m = f.monto || 0;
            if (f.estatus === 'Vencida' || f.estatus === 'Cancelada') vencida += m;
            else vigente += m;
        });
        const total = vigente + vencida || 1;
        const vencidaH  = Math.round((vencida  / total) * BAR_CHART_H);
        const vigenteH  = Math.round((vigente  / total) * BAR_CHART_H);
        return { vigente, vencida, total, vigenteH, vencidaH };
    }

    get barVencidaH() { return Math.max(this._barData().vencidaH, 2); }
    get barVigenteH() { return Math.max(this._barData().vigenteH, 2); }
    get barVencidaY() { return BAR_BOT_Y - this.barVencidaH; }
    get barVigenteY() { return this.barVencidaY - this.barVigenteH; }

    get barYLabels() {
        const { total } = this._barData();
        const labels = [];
        for (let i = 0; i <= 4; i++) {
            const val  = (total * i) / 4;
            const lineY = BAR_BOT_Y - Math.round((i / 4) * BAR_CHART_H);
            labels.push({
                key:   i,
                y:     lineY + 4,
                lineY: lineY,
                text:  this._fmtShort(val),
            });
        }
        return labels;
    }

    _donutData() {
        const all   = this.fianzasVencidas;
        const total = all.length || 1;
        const near  = all.filter(f => f.diasReclamo != null && f.diasReclamo <= 90).length;
        const nearPct  = Math.round((near  / total) * 100);
        const nearLen  = (near  / total) * DONUT_CIRC;
        return { nearPct, nearLen };
    }

    get donutNearDash() {
        const { nearLen } = this._donutData();
        return `${nearLen.toFixed(1)} ${DONUT_CIRC.toFixed(1)}`;
    }

    get donutNearPct() { return this._donutData().nearPct; }

    _fmt(val) {
        if (val == null) return '$0.00';
        return '$' + Number(val).toLocaleString('es-MX', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    _fmtShort(val) {
        if (val === 0) return '$0';
        if (val >= 1_000_000) return '$' + (val / 1_000_000).toFixed(0) + 'M';
        if (val >= 1_000)     return '$' + (val / 1_000).toFixed(0) + 'K';
        return '$' + val.toFixed(0);
    }

    _estatusCls(s) {
        if (s === 'Cancelada') return 'if-badge if-badge-red';
        if (s === 'Vencida')   return 'if-badge if-badge-orange';
        if (s === 'Vigente' || s === 'En plazo') return 'if-badge if-badge-green';
        return 'if-badge if-badge-gray';
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    stopPropagation(event) { event.stopPropagation(); }

    handleDownloadPDF() {
        const win = window.open('', '_blank', 'width=1100,height=800');
        if (!win) return;
        win.document.documentElement.innerHTML = this._buildPrintHTML();
        win.document.close();
        win.focus();
        setTimeout(() => { win.print(); }, 400);
    }

    _buildPrintHTML() {
        const e = s => s != null ? String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;') : '—';
        const badgeStyle = s => {
            if (s === 'Cancelada') return 'background:#fee2e2;color:#991b1b;padding:2px 7px;border-radius:8px;font-size:10px;font-weight:500';
            if (s === 'Vencida')   return 'background:#fef3c7;color:#92400e;padding:2px 7px;border-radius:8px;font-size:10px;font-weight:500';
            if (s === 'Vigente' || s === 'En plazo') return 'background:#d1fae5;color:#065f46;padding:2px 7px;border-radius:8px;font-size:10px;font-weight:500';
            return 'background:#f3f4f6;color:#374151;padding:2px 7px;border-radius:8px;font-size:10px;font-weight:500';
        };

        const contratosRows = this.contratos.length
            ? this.contratos.map((c, i) => `<tr>
                <td style="text-align:center;color:#9ca3af">${i+1}</td>
                <td style="font-weight:500;color:#1e40af">${e(c.name)}</td>
                <td style="text-align:right;color:#065f46;font-weight:600">${e(c.montoFmt)}</td>
                <td>${e(c.contratista)}</td>
                <td style="color:#6b7280">${e(c.proyecto)}</td>
              </tr>`).join('')
            : '<tr><td colspan="5" style="text-align:center;color:#9ca3af;font-style:italic;padding:14px">Sin contratos vinculados</td></tr>';

        const fianzasRows = this.fianzas.length
            ? this.fianzas.map((f, i) => `<tr>
                <td style="text-align:center;color:#9ca3af">${i+1}</td>
                <td style="font-weight:500;color:#1e40af">${e(f.name)}</td>
                <td>${e(f.contratista)}</td>
                <td>${e(f.contrato)}</td>
                <td style="text-align:right;color:#065f46;font-weight:600">${e(f.montoFmt)}</td>
                <td><span style="${badgeStyle(f.estatus)}">${e(f.estatus)}</span></td>
              </tr>`).join('')
            : '<tr><td colspan="6" style="text-align:center;color:#9ca3af;font-style:italic;padding:14px">Sin fianzas vinculadas</td></tr>';

        const vencidasRows = this.fianzasVencidas.length
            ? this.fianzasVencidas.map((fv, i) => `<tr>
                <td style="text-align:center;color:#9ca3af">${i+1}</td>
                <td style="font-weight:500;color:#1e40af">${e(fv.name)}</td>
                <td style="text-align:right;color:#065f46;font-weight:600">${e(fv.montoFmt)}</td>
                <td style="color:#6b7280">${e(fv.fechaFin)}</td>
                <td style="text-align:right;color:#991b1b">${fv.diasVigencia != null ? fv.diasVigencia : '—'}</td>
                <td style="text-align:right;color:#991b1b">${fv.diasReclamo  != null ? fv.diasReclamo  : '—'}</td>
                <td style="color:#6b7280">${e(fv.finReclamo)}</td>
                <td><span style="${badgeStyle(fv.estatus)}">${e(fv.estatusLabel)}</span></td>
              </tr>`).join('')
            : '<tr><td colspan="8" style="text-align:center;color:#9ca3af;font-style:italic;padding:14px">Sin fianzas vencidas</td></tr>';

        const fecha = new Date().toLocaleDateString('es-MX', { year:'numeric', month:'long', day:'numeric' });

        // Bar chart SVG
        const barLabels = this.barYLabels.map(lbl =>
            `<text x="68" y="${lbl.y}" style="font-size:9px;fill:#999" text-anchor="end">${lbl.text}</text>` +
            `<line x1="72" y1="${lbl.lineY}" x2="290" y2="${lbl.lineY}" style="stroke:#eee;stroke-width:1"/>`
        ).join('');
        const barSvg = `<svg viewBox="0 0 340 200" width="300" height="176" xmlns="http://www.w3.org/2000/svg">
            ${barLabels}
            <rect x="120" y="${this.barVigenteY}" width="70" height="${this.barVigenteH}" fill="#06b6d4" rx="2"/>
            <rect x="120" y="${this.barVencidaY}" width="70" height="${this.barVencidaH}" fill="#eab308" rx="2"/>
            <text x="155" y="${BAR_BOT_Y + 16}" style="font-size:10px;fill:#666" text-anchor="middle">${e(this.contratistaName)}</text>
            <rect x="200" y="24" width="10" height="10" fill="#06b6d4" rx="2"/>
            <text x="214" y="34" style="font-size:10px;fill:#555">En plazo</text>
            <rect x="200" y="40" width="10" height="10" fill="#eab308" rx="2"/>
            <text x="214" y="50" style="font-size:10px;fill:#555">Vencida</text>
            <text x="240" y="16" style="font-size:9px;fill:#aaa">VIGENCIA</text>
        </svg>`;

        // Donut chart SVG
        const donutSvg = `<svg viewBox="0 0 200 200" width="120" height="120" xmlns="http://www.w3.org/2000/svg">
            <circle cx="100" cy="100" r="70" fill="none" stroke="#3b82f6" stroke-width="30"/>
            <circle cx="100" cy="100" r="70" fill="none" stroke="#ef4444" stroke-width="30"
                    stroke-dasharray="${this.donutNearDash}" transform="rotate(-90 100 100)"/>
            <text x="100" y="96" style="font-size:24px;font-weight:700;fill:#1a1a2e" text-anchor="middle">${this.donutNearPct}%</text>
            <text x="100" y="115" style="font-size:11px;fill:#6b7280" text-anchor="middle">-90 días</text>
        </svg>`;

        return `<!DOCTYPE html>
<html lang="es"><head><meta charset="utf-8">
<title>Informe – ${e(this.contratistaName)}</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;font-size:12px;color:#1a1a2e;padding:28px 36px}
h1{font-size:20px;color:#1b8c5a;margin-bottom:2px}
.sub{color:#6b7280;font-size:10px;margin-bottom:20px}
.kpi-row{display:flex;gap:10px;margin-bottom:16px}
.kpi{flex:1;border-radius:7px;padding:10px 14px;border:1.5px solid #e0e0e0}
.kpi-lbl{font-size:9px;color:#6b7280;text-transform:uppercase;letter-spacing:.05em;margin-bottom:3px}
.kpi-val{font-size:16px;font-weight:700}
.kpi-blue{background:#eef2ff;border-color:#c7d2fe}
.kpi-sky{background:#eff6ff;border-color:#bfdbfe}
.kpi-gray{background:#f9fafb;border-color:#d1d5db}
.kpi-red{background:#fff1f2;border-color:#fca5a5}
.charts-row{display:flex;gap:10px;margin-bottom:16px}
.chart-card{flex:1;border:1px solid #e0e0e0;border-radius:7px;padding:10px 14px}
.chart-title{font-size:9px;font-weight:700;color:#6b7280;text-transform:uppercase;letter-spacing:.07em;margin-bottom:8px}
.donut-wrap{display:flex;flex-direction:column;align-items:center;gap:6px}
.legend{display:flex;gap:12px;font-size:10px;color:#1a1a2e}
.dot{display:inline-block;width:8px;height:8px;border-radius:50%;margin-right:4px;vertical-align:middle}
.sec{margin-bottom:16px;page-break-inside:avoid}
.sec-title{font-size:10px;font-weight:700;color:#374151;margin-bottom:6px;text-transform:uppercase;letter-spacing:.05em;border-left:3px solid #1b8c5a;padding-left:7px}
table{width:100%;border-collapse:collapse;font-size:11px}
th{background:#f3f4f6;padding:6px 9px;text-align:left;font-weight:600;color:#4b5563;border-bottom:2px solid #d1d5db;border-right:1px solid #e5e7eb;font-size:10px}
td{padding:5px 9px;border-bottom:1px solid #e5e7eb;border-right:1px solid #e5e7eb}
tr:nth-child(even) td{background:#f9fafb}
@page{size:A4 landscape;margin:1.5cm}
@media print{body{padding:0}}
</style></head><body>
<h1>Informe para ${e(this.contratistaName)}</h1>
<div class="sub">Generado el ${fecha}</div>
<div class="kpi-row">
  <div class="kpi kpi-blue"><div class="kpi-lbl">Monto de contratos</div><div class="kpi-val">${e(this.montoContratosFmt)}</div></div>
  <div class="kpi kpi-sky"><div class="kpi-lbl">Monto afianzado</div><div class="kpi-val">${e(this.montoAfianzadoFmt)}</div></div>
  <div class="kpi kpi-gray"><div class="kpi-lbl">Contratos</div><div class="kpi-val">${this.contratosCount}</div></div>
  <div class="kpi kpi-red"><div class="kpi-lbl">Fianzas vencidas</div><div class="kpi-val">${this.fianzasVencidasCount}</div></div>
</div>
<div class="charts-row">
  <div class="chart-card">
    <div class="chart-title">Total afianzado por contratista</div>
    ${barSvg}
  </div>
  <div class="chart-card">
    <div class="chart-title">Reclamaciones cercanas a la expiración</div>
    <div class="donut-wrap">
      ${donutSvg}
      <div class="legend">
        <span><span class="dot" style="background:#3b82f6"></span>-90 días</span>
        <span><span class="dot" style="background:#ef4444"></span>En plazo</span>
      </div>
      <div style="font-size:8px;text-transform:uppercase;color:#6b7280;font-weight:600">RECLAMACIÓN</div>
    </div>
  </div>
</div>
<div class="sec">
  <div class="sec-title">Contratos — ${this.contratosCount} registro(s)</div>
  <table><thead><tr><th>#</th><th>No Contrato</th><th style="text-align:right">Valor Contrato</th><th>Contratista</th><th>Proyectos</th></tr></thead>
  <tbody>${contratosRows}</tbody></table>
</div>
<div class="sec">
  <div class="sec-title">Todas las fianzas — ${this.fianzasCount} registro(s) · ${e(this.montoAfianzadoFmt)}</div>
  <table><thead><tr><th>#</th><th>Referencia de fianza</th><th>Contratista</th><th>Contrato</th><th style="text-align:right">Afianzado</th><th>Estatus</th></tr></thead>
  <tbody>${fianzasRows}</tbody></table>
</div>
<div class="sec">
  <div class="sec-title">Fianzas Vencidas — ${this.fianzasVencidasCount} registro(s) · ${e(this.montoVencidasFmt)}</div>
  <table><thead><tr><th>#</th><th>Referencia</th><th style="text-align:right">Afianzado</th><th>Fin Vencimiento</th><th style="text-align:right">Días Vigencia</th><th style="text-align:right">Días Reclamo</th><th>Fin Reclamo</th><th>Estatus</th></tr></thead>
  <tbody>${vencidasRows}</tbody></table>
</div>
</body></html>`;
    }
}