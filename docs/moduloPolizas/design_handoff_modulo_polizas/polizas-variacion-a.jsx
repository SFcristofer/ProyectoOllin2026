// Variación A v2 — Tabla Airtable con árbol expandible
// + Endosos, badge Renovación, columna Comisión, viabilidad LWC anotada

const { useState, useCallback } = React;

// ─── Tokens ───────────────────────────────────────────────────────────────────
const C = {
  charcoal: "#2a2a2a", charcoalHover: "#404040",
  blue: "#1a56db", blueHover: "#1549c0",
  tabInactive: "#4b5563",
  green: { bg: "#d1fae5", text: "#065f46" },
  red:   { bg: "#fee2e2", text: "#991b1b" },
  amber: { bg: "#fef3c7", text: "#92400e" },
  blueLight: { bg: "#dbeafe", text: "#1a56db" },
  purple: { bg: "#ede9fe", text: "#5b21b6" },
  pink:   { bg: "#fce7f3", text: "#9d174d" },
  teal:   { bg: "#e0f2fe", text: "#0369a1" },
  border: "#e5e7eb", surface: "#f9fafb", white: "#ffffff",
};

// ─── Badge ────────────────────────────────────────────────────────────────────
function Badge({ status }) {
  const map = {
    Pagado:    { bg: C.green.bg,      color: C.green.text,      label: "Pagado" },
    Pendiente: { bg: C.amber.bg,      color: C.amber.text,      label: "Pendiente" },
    Vencido:   { bg: C.red.bg,        color: C.red.text,        label: "Vencido" },
    Emitida:   { bg: C.blueLight.bg,  color: C.blueLight.text,  label: "Emitida" },
    Activo:    { bg: C.green.bg,      color: C.green.text,      label: "Activo" },
    Auto:      { bg: C.purple.bg,     color: C.purple.text,     label: "Auto" },
    PPR:       { bg: C.pink.bg,       color: C.pink.text,       label: "PPR" },
    Fianza:    { bg: C.teal.bg,       color: C.teal.text,       label: "Fianza" },
  };
  const s = map[status] || { bg: C.border, color: C.tabInactive, label: status };
  return (
    <span style={{
      display: "inline-flex", alignItems: "center", padding: "2px 8px",
      borderRadius: 4, fontSize: 11, fontWeight: 600, letterSpacing: "0.02em",
      background: s.bg, color: s.color, whiteSpace: "nowrap"
    }}>{s.label}</span>
  );
}

// ─── Renovación badge ─────────────────────────────────────────────────────────
function RenovacionBadge({ dias, onRenovar }) {
  if (dias === undefined || dias === null) return null;
  const urgent = dias <= 60;
  const warning = dias <= 90;
  if (!urgent && !warning) return null;
  const color = urgent ? C.red : C.amber;
  return (
    <span
      onClick={e => { e.stopPropagation(); onRenovar && onRenovar(); }}
      title="Iniciar renovación"
      style={{
        display: "inline-flex", alignItems: "center", gap: 4, padding: "2px 7px",
        borderRadius: 4, fontSize: 10, fontWeight: 700, letterSpacing: "0.02em",
        background: color.bg, color: color.text, whiteSpace: "nowrap",
        cursor: "pointer", border: `1px solid ${color.text}33`
      }}
    >
      ⟳ Vence en {dias}d
    </span>
  );
}

// ─── Chevron ──────────────────────────────────────────────────────────────────
function Chevron({ open }) {
  return (
    <svg width="13" height="13" viewBox="0 0 13 13" fill="none"
      style={{ transition: "transform 0.15s", transform: open ? "rotate(90deg)" : "rotate(0deg)", flexShrink: 0 }}>
      <path d="M4.5 2.5l4 4-4 4" stroke={C.tabInactive} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
}

// ─── Progress bar ─────────────────────────────────────────────────────────────
function ProgressBar({ paid, total }) {
  const pct = total > 0 ? (paid / total) * 100 : 0;
  const color = pct === 100 ? C.green.text : pct > 0 ? C.blue : C.border;
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
      <div style={{ flex: 1, height: 5, background: C.border, borderRadius: 99, overflow: "hidden", minWidth: 60 }}>
        <div style={{ height: "100%", width: `${pct}%`, background: color, borderRadius: 99, transition: "width 0.3s" }} />
      </div>
      <span style={{ fontSize: 11, color: C.tabInactive, whiteSpace: "nowrap" }}>{paid}/{total}</span>
    </div>
  );
}

// ─── LWC Viability tooltip ────────────────────────────────────────────────────
function LWCTag({ note }) {
  const [show, setShow] = useState(false);
  return (
    <span style={{ position: "relative", display: "inline-flex" }}>
      <span
        onMouseEnter={() => setShow(true)}
        onMouseLeave={() => setShow(false)}
        style={{
          display: "inline-flex", alignItems: "center", justifyContent: "center",
          width: 14, height: 14, borderRadius: 99, background: C.blueLight.bg,
          color: C.blueLight.text, fontSize: 9, fontWeight: 700, cursor: "help",
          flexShrink: 0, marginLeft: 4
        }}
      >i</span>
      {show && (
        <div style={{
          position: "absolute", bottom: "100%", left: "50%", transform: "translateX(-50%)",
          marginBottom: 6, background: C.charcoal, color: C.white,
          fontSize: 11, padding: "6px 10px", borderRadius: 6, whiteSpace: "nowrap",
          zIndex: 100, boxShadow: "0 2px 8px rgba(0,0,0,0.2)", lineHeight: 1.5,
          maxWidth: 260, whiteSpace: "normal", textAlign: "left"
        }}>
          <strong style={{ display: "block", marginBottom: 3, color: "#93c5fd" }}>LWC — Viabilidad técnica</strong>
          {note}
        </div>
      )}
    </span>
  );
}

// ─── Detail Panel ─────────────────────────────────────────────────────────────
function DetailPanel({ item, type, onClose, onMarkPaid, onRenovar }) {
  const [activeTab, setActiveTab] = useState("detalles");
  if (!item) return null;

  const isRecibo  = type === "recibo";
  const isPlan    = type === "plan";
  const isPoliza  = type === "poliza";
  const isEndoso  = type === "endoso";

  const fieldRow = (k, v) => (
    <div key={k} style={{
      display: "grid", gridTemplateColumns: "130px 1fr", alignItems: "start",
      padding: "8px 0", borderBottom: `1px solid ${C.border}`, gap: 8, fontSize: 12
    }}>
      <span style={{ color: C.tabInactive, fontWeight: 500 }}>{k}</span>
      <span style={{ color: C.charcoal }}>{v || "—"}</span>
    </div>
  );

  const tabStyle = (t) => ({
    background: "none", border: "none", cursor: "pointer",
    padding: "10px 12px 9px", fontSize: 12, fontWeight: 500,
    color: activeTab === t ? C.blue : C.tabInactive,
    borderBottom: activeTab === t ? `2px solid ${C.blue}` : "2px solid transparent",
  });

  return (
    <div style={{
      position: "absolute", top: 0, right: 0, bottom: 0, width: 360,
      background: C.white, borderLeft: `1px solid ${C.border}`,
      display: "flex", flexDirection: "column", zIndex: 10,
      boxShadow: "-4px 0 20px rgba(0,0,0,0.07)"
    }}>
      {/* Header */}
      <div style={{ padding: "16px 20px 12px", borderBottom: `1px solid ${C.border}` }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
          <div style={{ fontSize: 10, color: C.tabInactive, textTransform: "uppercase", letterSpacing: "0.06em", marginBottom: 4 }}>
            {isPoliza ? "Póliza" : isPlan ? "Plan de Pago" : isEndoso ? "Endoso" : "Recibo de Pago"}
          </div>
          <button onClick={onClose} style={{ background: "none", border: "none", cursor: "pointer", padding: 2, color: C.tabInactive }}>
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none"><path d="M2 2l10 10M12 2L2 12" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/></svg>
          </button>
        </div>
        <div style={{ fontSize: 14, fontWeight: 700, color: C.charcoal, lineHeight: 1.3, marginBottom: 6, wordBreak: "break-word" }}>{item.folio}</div>
        <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
          {isPoliza && <Badge status={item.estatus} />}
          {isPoliza && item.ramo && <Badge status={item.ramo} />}
          {isPoliza && item.diasParaVencer <= 90 && (
            <RenovacionBadge dias={item.diasParaVencer} onRenovar={onRenovar} />
          )}
          {isRecibo && <Badge status={item.estatus} />}
          {isEndoso && <Badge status={item.estatus} />}
        </div>
      </div>

      {/* Tabs — only for poliza */}
      {isPoliza && (
        <div style={{ display: "flex", borderBottom: `1px solid ${C.border}`, padding: "0 20px", gap: 4 }}>
          {["detalles", "endosos", "plan"].map(t => (
            <button key={t} style={tabStyle(t)} onClick={() => setActiveTab(t)}>
              {t === "detalles" ? "Detalles" : t === "endosos" ? `Endosos (${item.endosos?.length || 0})` : "Plan de Pago"}
            </button>
          ))}
        </div>
      )}

      {/* Body */}
      <div style={{ flex: 1, overflow: "auto", padding: "4px 20px 16px" }}>
        {isPoliza && activeTab === "detalles" && (
          <div>
            {[
              ["Cliente",        item.cliente],
              ["Aseguradora",    item.aseguradora],
              ["Ramo",           item.ramo],
              ["Producto",       item.producto],
              ["Vendedor",       item.vendedor],
              ["Prima neta",     `$${item.prima?.toLocaleString()}`],
              ["% Comisión",     item.comision > 0 ? `${item.comision}%` : "—"],
              ["Comisión est.",  item.comision > 0 ? `$${((item.prima * item.comision) / 100).toLocaleString()}` : "—"],
              ["Inicio vigencia",item.vigenciaInicio],
              ["Fin vigencia",   item.vigenciaFin],
              ["Estatus",        item.estatus],
            ].map(([k, v]) => fieldRow(k, v))}
          </div>
        )}

        {isPoliza && activeTab === "endosos" && (
          <div style={{ paddingTop: 8 }}>
            {item.endosos?.length > 0 ? item.endosos.map(e => (
              <div key={e.id} style={{
                border: `1px solid ${C.border}`, borderRadius: 7, padding: "10px 12px",
                marginBottom: 8, background: C.surface
              }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
                  <span style={{ fontSize: 12, fontWeight: 600, color: C.blue }}>{e.folio}</span>
                  <Badge status={e.estatus} />
                </div>
                <div style={{ fontSize: 11, color: C.tabInactive, marginBottom: 4 }}>{e.tipo}</div>
                <div style={{ display: "flex", gap: 12, fontSize: 11, color: C.charcoal }}>
                  <span>Efectiva: {e.fechaEfectiva}</span>
                  {e.diferenciaMonto !== 0 && <span>Δ ${e.diferenciaMonto?.toLocaleString()}</span>}
                </div>
              </div>
            )) : (
              <div style={{ padding: "24px 0", textAlign: "center", color: C.tabInactive, fontSize: 12 }}>Sin endosos registrados</div>
            )}
            <button style={{ width: "100%", padding: "7px 0", border: `1px dashed ${C.border}`, borderRadius: 7, background: "none", cursor: "pointer", color: C.blue, fontSize: 12, fontWeight: 600, marginTop: 4 }}>
              + Crear endoso
            </button>
          </div>
        )}

        {isPoliza && activeTab === "plan" && item.planPago && (
          <div style={{ paddingTop: 8 }}>
            <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 7, padding: 12, marginBottom: 10 }}>
              <div style={{ fontSize: 12, fontWeight: 600, color: C.charcoal, marginBottom: 6 }}>{item.planPago.folio}</div>
              {[
                ["Período", item.planPago.periodoPago],
                ["Método pago", item.planPago.metodoPago],
                ["Fecha inicio", item.planPago.fechaInicio],
                ["Núm. recibos", item.planPago.numRecibos],
              ].map(([k, v]) => (
                <div key={k} style={{ display: "flex", justifyContent: "space-between", fontSize: 11, padding: "4px 0", borderBottom: `1px solid ${C.border}` }}>
                  <span style={{ color: C.tabInactive }}>{k}</span>
                  <span style={{ color: C.charcoal }}>{v}</span>
                </div>
              ))}
            </div>
            <div style={{ fontSize: 11, fontWeight: 600, color: C.tabInactive, textTransform: "uppercase", letterSpacing: "0.05em", marginBottom: 6 }}>Recibos</div>
            <ProgressBar
              paid={item.planPago.recibos.filter(r => r.estatus === "Pagado").length}
              total={item.planPago.recibos.length}
            />
          </div>
        )}

        {isPlan && (
          <div>
            {[
              ["Folio",        item.folio],
              ["Estado",       item.estatus],
              ["Método pago",  item.metodoPago],
              ["Período pago", item.periodoPago],
              ["Fecha inicio", item.fechaInicio],
              ["Núm. recibos", item.numRecibos],
            ].map(([k, v]) => fieldRow(k, v))}
          </div>
        )}

        {isRecibo && (
          <div>
            {[
              ["Folio",       item.folio],
              ["Monto",       `$${item.monto?.toLocaleString()}`],
              ["Vencimiento", item.fechaVencimiento],
              ["Estatus",     item.estatus],
            ].map(([k, v]) => fieldRow(k, v))}
            {item.estatus !== "Pagado" && (
              <button onClick={() => onMarkPaid(item.id)} style={{
                marginTop: 16, width: "100%", padding: "9px 0",
                background: C.charcoal, color: C.white,
                border: "none", borderRadius: 6, fontSize: 13, fontWeight: 600, cursor: "pointer"
              }}>Marcar como Pagado</button>
            )}
          </div>
        )}

        {isEndoso && (
          <div>
            {[
              ["Folio",         item.folio],
              ["Tipo",          item.tipo],
              ["Fecha efectiva",item.fechaEfectiva],
              ["Dif. monto",    item.diferenciaMonto !== 0 ? `$${item.diferenciaMonto?.toLocaleString()}` : "Sin cambio"],
              ["Estatus",       item.estatus],
            ].map(([k, v]) => fieldRow(k, v))}
          </div>
        )}
      </div>

      {/* Footer actions */}
      {isPoliza && (
        <div style={{ padding: "12px 20px", borderTop: `1px solid ${C.border}`, display: "flex", gap: 8 }}>
          <button onClick={onRenovar} style={{ flex: 1, padding: "8px 0", background: C.charcoal, color: C.white, border: "none", borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: "pointer" }}>
            ⟳ Renovar póliza
          </button>
          <button style={{ flex: 1, padding: "8px 0", background: C.white, color: C.charcoal, border: `1px solid ${C.border}`, borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: "pointer" }}>
            Crear endoso
          </button>
        </div>
      )}
    </div>
  );
}

// ─── Table rows ───────────────────────────────────────────────────────────────
function ReciboRow({ recibo, onSelect, selected }) {
  const bg = selected ? "#eff6ff" : "transparent";
  const tdBase = { padding: "6px 10px", borderBottom: `1px solid ${C.border}`, fontSize: 12 };
  return (
    <tr onClick={() => onSelect(recibo, "recibo")} style={{ background: bg, cursor: "pointer" }}
      onMouseEnter={e => { if (!selected) e.currentTarget.style.background = C.surface; }}
      onMouseLeave={e => { if (!selected) e.currentTarget.style.background = bg; }}>
      {/* name col */}
      <td style={{ ...tdBase, paddingLeft: 72, display: "flex", alignItems: "center", gap: 5 }}>
        <svg width="11" height="11" viewBox="0 0 11 11" fill="none" style={{ flexShrink: 0 }}>
          <rect x="0.5" y="1.5" width="10" height="8" rx="1.5" stroke={C.tabInactive} strokeWidth="1"/>
          <path d="M2.5 4.5h6M2.5 6.5h4" stroke={C.tabInactive} strokeWidth="1" strokeLinecap="round"/>
        </svg>
        <span style={{ color: C.blue, fontWeight: 500 }}>{recibo.folio}</span>
      </td>
      <td style={tdBase}>{recibo.fechaVencimiento}</td>
      <td style={tdBase}><Badge status={recibo.estatus} /></td>
      <td style={tdBase}>${recibo.monto?.toLocaleString()}</td>
      <td style={tdBase}>—</td>
      <td style={tdBase}>—</td>
    </tr>
  );
}

function EndosoRow({ endoso, onSelect, selected }) {
  const bg = selected ? "#eff6ff" : "transparent";
  const tdBase = { padding: "6px 10px", borderBottom: `1px solid ${C.border}`, fontSize: 12 };
  return (
    <tr onClick={() => onSelect(endoso, "endoso")} style={{ background: bg, cursor: "pointer" }}
      onMouseEnter={e => { if (!selected) e.currentTarget.style.background = C.surface; }}
      onMouseLeave={e => { if (!selected) e.currentTarget.style.background = bg; }}>
      <td style={{ ...tdBase, paddingLeft: 56, display: "flex", alignItems: "center", gap: 5 }}>
        <svg width="11" height="11" viewBox="0 0 11 11" fill="none" style={{ flexShrink: 0 }}>
          <path d="M2 9L5.5 2 9 9" stroke={C.tabInactive} strokeWidth="1" strokeLinecap="round" strokeLinejoin="round"/>
          <path d="M3 7h5" stroke={C.tabInactive} strokeWidth="1" strokeLinecap="round"/>
        </svg>
        <span style={{ color: C.blue, fontWeight: 500 }}>{endoso.folio}</span>
        <span style={{ fontSize: 10, color: C.tabInactive }}>— {endoso.tipo}</span>
      </td>
      <td style={tdBase}>{endoso.fechaEfectiva}</td>
      <td style={tdBase}><Badge status={endoso.estatus} /></td>
      <td style={tdBase}>{endoso.diferenciaMonto !== 0 ? `$${endoso.diferenciaMonto?.toLocaleString()}` : "—"}</td>
      <td style={tdBase}>—</td>
      <td style={tdBase}>—</td>
    </tr>
  );
}

function PlanRow({ plan, expanded, onToggle, onSelect, selected, onMarkPaid, selectedItem }) {
  const bg = selected ? "#eff6ff" : "transparent";
  const paid = plan.recibos.filter(r => r.estatus === "Pagado").length;
  const tdBase = { padding: "8px 10px", borderBottom: `1px solid ${C.border}`, fontSize: 12 };
  return (
    <>
      <tr onClick={() => { onToggle(); onSelect(plan, "plan"); }} style={{ background: bg, cursor: "pointer" }}
        onMouseEnter={e => { if (!selected) e.currentTarget.style.background = C.surface; }}
        onMouseLeave={e => { if (!selected) e.currentTarget.style.background = bg; }}>
        <td style={{ ...tdBase, paddingLeft: 40, display: "flex", alignItems: "center", gap: 5 }}>
          <Chevron open={expanded} />
          <svg width="12" height="12" viewBox="0 0 12 12" fill="none" style={{ flexShrink: 0 }}>
            <rect x="1" y="1" width="10" height="10" rx="2" stroke={C.tabInactive} strokeWidth="1.1"/>
            <path d="M3 6h6M3 4h6M3 8h4" stroke={C.tabInactive} strokeWidth="1.1" strokeLinecap="round"/>
          </svg>
          <span style={{ color: C.blue, fontWeight: 500 }}>{plan.folio}</span>
        </td>
        <td style={tdBase}>{plan.periodoPago}</td>
        <td style={tdBase}><Badge status={plan.estatus} /></td>
        <td colSpan={2} style={tdBase}><ProgressBar paid={paid} total={plan.recibos.length} /></td>
        <td style={tdBase}>—</td>
      </tr>
      {expanded && plan.recibos.map(r => (
        <ReciboRow key={r.id} recibo={r} onSelect={onSelect} selected={selectedItem?.id === r.id} />
      ))}
    </>
  );
}

function PolizaRow({ poliza, expanded, onToggle, onSelect, selected,
  planExpanded, onPlanToggle, endososExpanded, onEndososToggle,
  onMarkPaid, selectedItem, onRenovar, reciboEstatus }) {

  const bg = selected ? "#eff6ff" : "transparent";
  const tdBase = { padding: "10px 10px", borderBottom: `1px solid ${C.border}`, fontSize: 12, verticalAlign: "middle" };

  const getRecibo = r => ({ ...r, estatus: reciboEstatus[r.id] || r.estatus });
  const recibos   = poliza.planPago?.recibos.map(getRecibo) || [];
  const paid      = recibos.filter(r => r.estatus === "Pagado").length;
  const total     = recibos.length;

  const planWithOverrides = poliza.planPago ? { ...poliza.planPago, recibos } : null;

  return (
    <>
      <tr onClick={() => { onToggle(); onSelect(poliza, "poliza"); }}
        style={{ background: bg, cursor: "pointer" }}
        onMouseEnter={e => { if (!selected) e.currentTarget.style.background = "#f8faff"; }}
        onMouseLeave={e => { if (!selected) e.currentTarget.style.background = bg; }}>

        {/* Nombre */}
        <td style={{ ...tdBase, minWidth: 240 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 6, paddingLeft: 8 }}>
            <Chevron open={expanded} />
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none" style={{ flexShrink: 0 }}>
              <path d="M7 1L2 3.5v4C2 10.5 4.5 13 7 13s5-2.5 5-5.5v-4L7 1z" stroke={C.charcoal} strokeWidth="1.2" fill="none"/>
            </svg>
            <div style={{ minWidth: 0 }}>
              <div style={{ fontSize: 12, fontWeight: 600, color: C.blue, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", maxWidth: 200 }}>
                {poliza.folio}
              </div>
              <div style={{ display: "flex", gap: 4, marginTop: 3, flexWrap: "wrap" }}>
                <Badge status={poliza.ramo} />
                {poliza.diasParaVencer <= 90 && <RenovacionBadge dias={poliza.diasParaVencer} onRenovar={() => onRenovar(poliza)} />}
              </div>
            </div>
          </div>
        </td>

        {/* Cliente */}
        <td style={{ ...tdBase, fontSize: 12, color: C.charcoal, whiteSpace: "nowrap" }}>{poliza.cliente}</td>

        {/* Aseguradora */}
        <td style={{ ...tdBase, fontSize: 11, color: C.tabInactive, whiteSpace: "nowrap" }}>{poliza.aseguradora}</td>

        {/* Estatus */}
        <td style={tdBase}><Badge status={poliza.estatus} /></td>

        {/* Recibos pagados */}
        <td style={{ ...tdBase, minWidth: 120 }}><ProgressBar paid={paid} total={total} /></td>

        {/* Comisión */}
        <td style={{ ...tdBase, textAlign: "center" }}>
          {poliza.comision > 0
            ? <span style={{ fontSize: 12, fontWeight: 600, color: C.green.text }}>{poliza.comision}%</span>
            : <span style={{ fontSize: 12, color: C.tabInactive }}>—</span>
          }
        </td>

        {/* Endosos */}
        <td style={{ ...tdBase, textAlign: "center" }}>
          {(poliza.endosos?.length || 0) > 0
            ? <span style={{ fontSize: 11, fontWeight: 600, color: C.purple.text, background: C.purple.bg, borderRadius: 4, padding: "2px 7px" }}>{poliza.endosos.length}</span>
            : <span style={{ fontSize: 11, color: C.tabInactive }}>—</span>
          }
        </td>
      </tr>

      {/* Children when expanded */}
      {expanded && (
        <>
          {/* Endosos section */}
          {(poliza.endosos?.length || 0) > 0 && (
            <>
              <tr onClick={() => onEndososToggle()} style={{ background: "#faf5ff", cursor: "pointer" }}
                onMouseEnter={e => e.currentTarget.style.background = "#f3e8ff"}
                onMouseLeave={e => e.currentTarget.style.background = "#faf5ff"}>
                <td colSpan={7} style={{ padding: "6px 10px 6px 32px", borderBottom: `1px solid ${C.border}`, display: "flex", alignItems: "center", gap: 6, fontSize: 11, fontWeight: 600, color: C.purple.text }}>
                  <Chevron open={endososExpanded} />
                  Endosos ({poliza.endosos.length})
                </td>
              </tr>
              {endososExpanded && poliza.endosos.map(e => (
                <EndosoRow key={e.id} endoso={e} onSelect={onSelect} selected={selectedItem?.id === e.id} />
              ))}
            </>
          )}

          {/* Plan de Pagos */}
          {planWithOverrides && (
            <PlanRow
              plan={planWithOverrides}
              expanded={planExpanded}
              onToggle={onPlanToggle}
              onSelect={onSelect}
              selected={selectedItem?.id === poliza.planPago?.id}
              onMarkPaid={onMarkPaid}
              selectedItem={selectedItem}
            />
          )}
        </>
      )}
    </>
  );
}

// ─── LWC Viability Banner ─────────────────────────────────────────────────────
function LWCBanner() {
  const [open, setOpen] = useState(false);
  const items = [
    { ok: true,  label: "Pestaña Pólizas en LWC",              note: "NavigationMixin + tab nativa en App Builder. Completamente viable." },
    { ok: true,  label: "Tabla/árbol con árbol expandible",     note: "lightning-tree-grid o tabla custom con @wire(getRecords). Sin restricciones." },
    { ok: true,  label: "Panel lateral de detalle",             note: "lightning-record-view-form o componente custom con slot. Estándar LWC." },
    { ok: true,  label: "Badges de estado (Pagado/Vencido)",    note: "lightning-badge o span con CSS. Bindings reactivos con @track. Trivial." },
    { ok: true,  label: "Barra progreso recibos",               note: "Calculado en JS con @wire sobre lista de recibos. SVG/CSS inline." },
    { ok: true,  label: "Endosos expandibles",                  note: "Sub-consulta SOQL desde el Seguro o Fianza padre. Standard Related List." },
    { ok: true,  label: "Badge Renovación (días para vencer)",  note: "Campo fórmula en Salesforce (vigenciaFin - TODAY()). Lightning-formatted-number." },
    { ok: true,  label: "Acción Renovar póliza",                note: "LWC invoca Quick Action o Flow de pantalla mediante NavigationMixin." },
    { ok: true,  label: "Acción Crear endoso",                  note: "NavigationMixin.Navigate a record create page con defaults precargados." },
    { ok: true,  label: "Columna % Comisión",                   note: "Campo en objeto Seguro__c / Fianza__c. @wire(getRecord) estándar." },
    { ok: true,  label: "Marcar recibo como pagado",            note: "updateRecord() del LDS o Apex imperativo. Una línea de código." },
    { ok: true,  label: "Sub-tabs Seguros / Fianzas",          note: "lightning-tabset + lightning-tab. Componente nativo de SLDS." },
    { ok: false, label: "Tabla de Comisiones (maestro)",        note: "Requiere objeto Custom (Tech_Comision__c) y lógica de liberación al cobrar. Mayor esfuerzo." },
    { ok: false, label: "Contrato de Fianza",                   note: "Objeto Custom (Contrato__c) con relación padre-hijo a Fianza. Requiere diseño de modelo." },
    { ok: false, label: "Convenio Modificatorio",               note: "Objeto Custom hijo de Contrato. Necesita wireframe propio." },
  ];
  return (
    <div style={{ margin: "0 20px 12px", border: `1px solid ${C.border}`, borderRadius: 8, overflow: "hidden" }}>
      <button onClick={() => setOpen(o => !o)} style={{
        width: "100%", display: "flex", alignItems: "center", gap: 8,
        padding: "9px 14px", background: C.charcoal, border: "none", cursor: "pointer",
        color: C.white, fontSize: 12, fontWeight: 600, textAlign: "left"
      }}>
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none" style={{ transition: "transform 0.15s", transform: open ? "rotate(90deg)" : "rotate(0deg)", flexShrink: 0 }}>
          <path d="M4 2l5 5-5 5" stroke="white" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
        Viabilidad técnica LWC — {items.filter(i => i.ok).length}/{items.length} elementos confirmados
        <span style={{ marginLeft: "auto", fontSize: 10, background: "#16a34a", borderRadius: 4, padding: "2px 7px" }}>
          {items.filter(i => i.ok).length} viables
        </span>
        <span style={{ fontSize: 10, background: "#dc2626", borderRadius: 4, padding: "2px 7px" }}>
          {items.filter(i => !i.ok).length} requieren diseño
        </span>
      </button>
      {open && (
        <div style={{ background: C.surface, padding: "8px 14px 12px" }}>
          {items.map((item, i) => (
            <div key={i} style={{ display: "flex", alignItems: "flex-start", gap: 8, padding: "5px 0", borderBottom: i < items.length - 1 ? `1px solid ${C.border}` : "none" }}>
              <span style={{ fontSize: 13, flexShrink: 0, marginTop: 1 }}>{item.ok ? "✅" : "⚠️"}</span>
              <div>
                <div style={{ fontSize: 12, fontWeight: 600, color: C.charcoal }}>{item.label}</div>
                <div style={{ fontSize: 11, color: C.tabInactive, marginTop: 1 }}>{item.note}</div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

// ─── Main ─────────────────────────────────────────────────────────────────────
function VariacionA() {
  const [activeTab,      setActiveTab]      = useState("seguros");
  const [filterEstatus,  setFilterEstatus]  = useState("todos");
  const [search,         setSearch]         = useState("");
  const [expanded,       setExpanded]       = useState({});
  const [planExpanded,   setPlanExpanded]   = useState({});
  const [endososExpanded,setEndososExpanded]= useState({});
  const [selectedItem,   setSelectedItem]   = useState(null);
  const [selectedType,   setSelectedType]   = useState(null);
  const [reciboEstatus,  setReciboEstatus]  = useState({});
  const [renovarModal,   setRenovarModal]   = useState(null);

  const items = activeTab === "seguros" ? MOCK_DATA.seguros : MOCK_DATA.fianzas;

  const filtered = items.filter(p => {
    const matchSearch = search === "" || p.folio.toLowerCase().includes(search.toLowerCase()) || p.cliente.toLowerCase().includes(search.toLowerCase());
    const matchEstatus = filterEstatus === "todos" || p.estatus === filterEstatus;
    return matchSearch && matchEstatus;
  });

  const toggleExpand     = id => setExpanded(prev      => ({ ...prev, [id]: !prev[id] }));
  const togglePlan       = id => setPlanExpanded(prev  => ({ ...prev, [id]: !prev[id] }));
  const toggleEndosos    = id => setEndososExpanded(prev => ({ ...prev, [id]: !prev[id] }));

  const handleMarkPaid = useCallback(reciboId => {
    setReciboEstatus(prev => ({ ...prev, [reciboId]: "Pagado" }));
    setSelectedItem(prev => prev?.id === reciboId ? { ...prev, estatus: "Pagado" } : prev);
  }, []);

  const handleRenovar = useCallback(poliza => {
    setRenovarModal(poliza);
  }, []);

  const thStyle = {
    padding: "8px 10px", fontSize: 11, fontWeight: 700,
    color: C.tabInactive, textTransform: "uppercase", letterSpacing: "0.06em",
    background: C.surface, borderBottom: `1px solid ${C.border}`,
    textAlign: "left", userSelect: "none", whiteSpace: "nowrap", position: "sticky", top: 0
  };

  return (
    <div style={{ fontFamily: "'Inter', sans-serif", background: C.white, height: "100%", display: "flex", flexDirection: "column", position: "relative", overflow: "hidden" }}>

      {/* Module nav tabs */}
      <div style={{ padding: "0 20px", borderBottom: `1px solid ${C.border}` }}>
        <div style={{ display: "flex", gap: 2, paddingTop: 10 }}>
          {["Dashboard", "Prospectos", "Oportunidades", "Clientes", "Pólizas"].map(t => (
            <div key={t} style={{
              padding: "7px 14px", fontSize: 13, fontWeight: t === "Pólizas" ? 600 : 500,
              color: t === "Pólizas" ? C.charcoal : C.tabInactive,
              borderBottom: t === "Pólizas" ? `2px solid ${C.charcoal}` : "2px solid transparent",
              cursor: "pointer"
            }}>{t}</div>
          ))}
        </div>
      </div>

      {/* Toolbar */}
      <div style={{ padding: "12px 20px", borderBottom: `1px solid ${C.border}`, display: "flex", alignItems: "center", gap: 10, flexWrap: "wrap" }}>
        {/* Sub-tabs */}
        <div style={{ display: "flex", background: C.surface, border: `1px solid ${C.border}`, borderRadius: 6, padding: 3, gap: 2 }}>
          {[
            { id: "seguros", label: "Seguros", count: MOCK_DATA.seguros.length },
            { id: "fianzas", label: "Fianzas / PPR", count: MOCK_DATA.fianzas.length },
          ].map(t => (
            <button key={t.id} onClick={() => setActiveTab(t.id)} style={{
              padding: "5px 12px", border: "none", cursor: "pointer", borderRadius: 4,
              fontSize: 12, fontWeight: 600,
              background: activeTab === t.id ? C.white : "transparent",
              color: activeTab === t.id ? C.charcoal : C.tabInactive,
              boxShadow: activeTab === t.id ? "0 1px 3px rgba(0,0,0,0.1)" : "none",
              transition: "all 0.15s"
            }}>
              {t.label}
              <span style={{ marginLeft: 5, fontSize: 10, background: activeTab === t.id ? C.blueLight.bg : C.border, color: activeTab === t.id ? C.blue : C.tabInactive, borderRadius: 99, padding: "1px 5px" }}>{t.count}</span>
            </button>
          ))}
        </div>

        {/* Search */}
        <div style={{ display: "flex", alignItems: "center", gap: 6, background: C.surface, border: `1px solid ${C.border}`, borderRadius: 6, padding: "5px 10px", flex: 1, maxWidth: 260 }}>
          <svg width="12" height="12" viewBox="0 0 12 12" fill="none"><circle cx="5" cy="5" r="3.5" stroke={C.tabInactive} strokeWidth="1.2"/><path d="M8.5 8.5l2 2" stroke={C.tabInactive} strokeWidth="1.2" strokeLinecap="round"/></svg>
          <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Buscar póliza, cliente..." style={{ border: "none", background: "none", fontSize: 12, outline: "none", color: C.charcoal, width: "100%" }} />
        </div>

        <select value={filterEstatus} onChange={e => setFilterEstatus(e.target.value)} style={{ padding: "5px 10px", border: `1px solid ${C.border}`, borderRadius: 6, fontSize: 12, color: C.charcoal, background: C.white, cursor: "pointer" }}>
          <option value="todos">Todos los estatus</option>
          <option value="Emitida">Emitida</option>
          <option value="Cancelada">Cancelada</option>
        </select>

        <div style={{ flex: 1 }} />
        <button style={{ padding: "6px 14px", background: C.charcoal, color: C.white, border: "none", borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: "pointer" }}>+ Nueva Póliza</button>
      </div>

      {/* LWC Viability Banner */}
      <div style={{ paddingTop: 12 }}>
        <LWCBanner />
      </div>

      {/* Table + panel */}
      <div style={{ flex: 1, display: "flex", overflow: "hidden" }}>
        <div style={{ flex: 1, overflow: "auto" }}>
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr>
                <th style={{ ...thStyle, minWidth: 260 }}>
                  Póliza / Plan / Recibo
                  <LWCTag note="lightning-tree-grid o tabla custom con SOQL recursivo. Completamente viable en LWC con @wire." />
                </th>
                <th style={thStyle}>Cliente</th>
                <th style={thStyle}>Aseguradora</th>
                <th style={thStyle}>Estatus</th>
                <th style={{ ...thStyle, minWidth: 130 }}>
                  Recibos
                  <LWCTag note="@wire(getRelatedListRecords) sobre Plan_de_Pagos__c. Actualización con updateRecord() del LDS." />
                </th>
                <th style={{ ...thStyle, textAlign: "center" }}>
                  % Comisión
                  <LWCTag note="Campo en Seguro__c. La comisión liberada se calcula al marcar recibo Cobrado vía Apex Trigger o Flow." />
                </th>
                <th style={{ ...thStyle, textAlign: "center" }}>
                  Endosos
                  <LWCTag note="@wire sobre Endoso_de_Seguro__c con filtro por ID de póliza padre. Relación M-D estándar." />
                </th>
              </tr>
            </thead>
            <tbody>
              {filtered.map(p => (
                <PolizaRow
                  key={p.id}
                  poliza={p}
                  expanded={!!expanded[p.id]}
                  onToggle={() => toggleExpand(p.id)}
                  onSelect={(item, type) => { setSelectedItem(item); setSelectedType(type); }}
                  selected={selectedItem?.id === p.id}
                  planExpanded={!!planExpanded[p.planPago?.id]}
                  onPlanToggle={() => togglePlan(p.planPago?.id)}
                  endososExpanded={!!endososExpanded[p.id + "-endosos"]}
                  onEndososToggle={() => toggleEndosos(p.id + "-endosos")}
                  onMarkPaid={handleMarkPaid}
                  selectedItem={selectedItem}
                  onRenovar={handleRenovar}
                  reciboEstatus={reciboEstatus}
                />
              ))}
              {filtered.length === 0 && (
                <tr><td colSpan={7} style={{ padding: 40, textAlign: "center", color: C.tabInactive, fontSize: 13 }}>Sin resultados</td></tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Detail Panel */}
        {selectedItem && (
          <DetailPanel
            item={selectedItem}
            type={selectedType}
            onClose={() => { setSelectedItem(null); setSelectedType(null); }}
            onMarkPaid={handleMarkPaid}
            onRenovar={() => handleRenovar(selectedItem)}
          />
        )}
      </div>

      {/* Renovar Modal */}
      {renovarModal && (
        <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.35)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 50 }}>
          <div style={{ background: C.white, borderRadius: 10, padding: 28, width: 380, boxShadow: "0 20px 60px rgba(0,0,0,0.2)" }}>
            <div style={{ fontSize: 16, fontWeight: 700, color: C.charcoal, marginBottom: 6 }}>Iniciar renovación</div>
            <div style={{ fontSize: 13, color: C.tabInactive, marginBottom: 16, lineHeight: 1.5 }}>
              Se creará una nueva <strong>Oportunidad</strong> vinculada a esta póliza con la póliza renovada como referencia.
            </div>
            <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 7, padding: "10px 14px", marginBottom: 18, fontSize: 12, color: C.charcoal }}>
              <strong>Póliza:</strong> {renovarModal.folio?.substring(0, 50)}...<br/>
              <strong>Vence en:</strong> {renovarModal.diasParaVencer} días ({renovarModal.vigenciaFin})
            </div>
            <div style={{ display: "flex", gap: 10 }}>
              <button onClick={() => setRenovarModal(null)} style={{ flex: 1, padding: "9px 0", border: `1px solid ${C.border}`, borderRadius: 7, background: C.white, fontSize: 13, cursor: "pointer", color: C.charcoal, fontWeight: 500 }}>Cancelar</button>
              <button onClick={() => setRenovarModal(null)} style={{ flex: 2, padding: "9px 0", border: "none", borderRadius: 7, background: C.charcoal, color: C.white, fontSize: 13, fontWeight: 600, cursor: "pointer" }}>Crear oportunidad de renovación</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

Object.assign(window, { VariacionA });
