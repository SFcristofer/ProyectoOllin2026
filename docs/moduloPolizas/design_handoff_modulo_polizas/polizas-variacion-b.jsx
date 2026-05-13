// Variación B — Innovador: Árbol visual con cards + timeline de ciclo de vida
// Vista 360° con panel lateral animado y progress de recibos tipo Kanban

const { useState: useStateB, useCallback: useCallbackB, useEffect: useEffectB } = React;

// ─── Tokens (mismos) ──────────────────────────────────────────────────────────
const CB = {
  charcoal: "#2a2a2a", charcoalHover: "#404040",
  blue: "#1a56db", blueHover: "#1549c0",
  tabInactive: "#4b5563",
  green: { bg: "#d1fae5", text: "#065f46" },
  red: { bg: "#fee2e2", text: "#991b1b" },
  amber: { bg: "#fef3c7", text: "#92400e" },
  blueLight: { bg: "#dbeafe", text: "#1a56db" },
  border: "#e5e7eb", surface: "#f9fafb", white: "#ffffff",
};

function BadgeB({ status }) {
  const map = {
    Pagado:    { bg: CB.green.bg,      color: CB.green.text,      label: "Pagado" },
    Pendiente: { bg: CB.amber.bg,      color: CB.amber.text,      label: "Pendiente" },
    Vencido:   { bg: CB.red.bg,        color: CB.red.text,        label: "Vencido" },
    Emitida:   { bg: CB.blueLight.bg,  color: CB.blueLight.text,  label: "Emitida" },
    Activo:    { bg: CB.green.bg,      color: CB.green.text,      label: "Activo" },
    Auto:      { bg: "#ede9fe",        color: "#5b21b6",          label: "Auto" },
    PPR:       { bg: "#fce7f3",        color: "#9d174d",          label: "PPR" },
    Fianza:    { bg: "#e0f2fe",        color: "#0369a1",          label: "Fianza" },
  };
  const s = map[status] || { bg: CB.border, color: CB.tabInactive, label: status };
  return (
    <span style={{
      display: "inline-flex", alignItems: "center",
      padding: "2px 8px", borderRadius: 4,
      fontSize: 11, fontWeight: 600, letterSpacing: "0.02em",
      background: s.bg, color: s.color, whiteSpace: "nowrap"
    }}>{s.label}</span>
  );
}

// ─── Recibo mini-chip ─────────────────────────────────────────────────────────
function ReciboChip({ recibo, onClick, selected }) {
  const colors = {
    Pagado: CB.green,
    Pendiente: { bg: "#f3f4f6", text: CB.tabInactive },
    Vencido: CB.red,
  };
  const c = colors[recibo.estatus] || colors.Pendiente;
  return (
    <button
      onClick={() => onClick(recibo)}
      title={`${recibo.folio} — $${recibo.monto?.toLocaleString()} — ${recibo.estatus}`}
      style={{
        width: 22, height: 22, borderRadius: 4,
        background: selected ? CB.blue : c.bg,
        border: selected ? `2px solid ${CB.blue}` : `1px solid ${c.text}22`,
        cursor: "pointer", transition: "all 0.12s",
        flexShrink: 0
      }}
    />
  );
}

// ─── Poliza Card ──────────────────────────────────────────────────────────────
function PolizaCard({ poliza, onSelect, selectedId, onReciboSelect, selectedReciboId, reciboEstatus }) {
  const [planOpen, setPlanOpen] = useStateB(false);
  const isSelected = selectedId === poliza.id;

  const getRecibo = r => ({ ...r, estatus: reciboEstatus[r.id] || r.estatus });
  const recibos = poliza.planPago?.recibos.map(getRecibo) || [];
  const paid = recibos.filter(r => r.estatus === "Pagado").length;
  const vencidos = recibos.filter(r => r.estatus === "Vencido").length;
  const pct = recibos.length > 0 ? (paid / recibos.length) * 100 : 0;

  return (
    <div style={{
      border: isSelected ? `1.5px solid ${CB.blue}` : `1px solid ${CB.border}`,
      borderRadius: 10, background: CB.white,
      boxShadow: isSelected ? `0 0 0 3px ${CB.blueLight.bg}` : "0 1px 3px rgba(0,0,0,0.05)",
      transition: "all 0.18s", overflow: "hidden"
    }}>
      {/* Card Header */}
      <div
        onClick={() => onSelect(poliza, "poliza")}
        style={{ padding: "12px 14px", cursor: "pointer", display: "flex", alignItems: "flex-start", gap: 10 }}
      >
        {/* Icon */}
        <div style={{
          width: 34, height: 34, borderRadius: 8, flexShrink: 0,
          background: poliza.ramo === "Auto" ? "#ede9fe" : poliza.ramo === "PPR" ? "#fce7f3" : "#e0f2fe",
          display: "flex", alignItems: "center", justifyContent: "center"
        }}>
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
            <path d="M8 1L2 4v5c0 3.5 2.5 6 6 6s6-2.5 6-6V4L8 1z"
              stroke={poliza.ramo === "Auto" ? "#5b21b6" : poliza.ramo === "PPR" ? "#9d174d" : "#0369a1"}
              strokeWidth="1.3" fill="none"/>
          </svg>
        </div>
        {/* Info */}
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 12, fontWeight: 600, color: CB.blue, lineHeight: 1.4, marginBottom: 3, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
            {poliza.folio}
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 6, flexWrap: "wrap" }}>
            <span style={{ fontSize: 11, color: CB.tabInactive }}>{poliza.aseguradora}</span>
            <span style={{ color: CB.border }}>·</span>
            <BadgeB status={poliza.ramo} />
            <BadgeB status={poliza.estatus} />
          </div>
        </div>
        <div style={{ flexShrink: 0, textAlign: "right" }}>
          <div style={{ fontSize: 13, fontWeight: 700, color: CB.charcoal }}>${poliza.prima?.toLocaleString()}</div>
          <div style={{ fontSize: 10, color: CB.tabInactive }}>prima neta</div>
        </div>
      </div>

      {/* Vigencia strip */}
      <div style={{ padding: "0 14px 8px", display: "flex", gap: 12, alignItems: "center" }}>
        <svg width="12" height="12" viewBox="0 0 12 12" fill="none" style={{ flexShrink: 0 }}>
          <rect x="1" y="1.5" width="10" height="9.5" rx="1.5" stroke={CB.tabInactive} strokeWidth="1.1"/>
          <path d="M4 1v2M8 1v2M1 5h10" stroke={CB.tabInactive} strokeWidth="1.1" strokeLinecap="round"/>
        </svg>
        <span style={{ fontSize: 11, color: CB.tabInactive }}>{poliza.vigenciaInicio} → {poliza.vigenciaFin}</span>
        {vencidos > 0 && (
          <span style={{ marginLeft: "auto", fontSize: 10, fontWeight: 700, background: CB.red.bg, color: CB.red.text, borderRadius: 4, padding: "2px 6px" }}>
            ⚠ {vencidos} vencido{vencidos > 1 ? "s" : ""}
          </span>
        )}
      </div>

      {/* Plan de Pagos toggle */}
      {poliza.planPago && (
        <>
          <button
            onClick={() => setPlanOpen(o => !o)}
            style={{
              width: "100%", padding: "8px 14px", background: CB.surface,
              border: "none", borderTop: `1px solid ${CB.border}`,
              cursor: "pointer", display: "flex", alignItems: "center", gap: 8,
              fontSize: 11, fontWeight: 600, color: CB.tabInactive
            }}
          >
            <svg width="12" height="12" viewBox="0 0 12 12" fill="none" style={{ transition: "transform 0.18s", transform: planOpen ? "rotate(90deg)" : "rotate(0deg)" }}>
              <path d="M4 2l4 4-4 4" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round"/>
            </svg>
            Plan de Pagos — {poliza.planPago.folio}
            <div style={{ flex: 1, marginLeft: 6 }}>
              <div style={{ height: 4, background: CB.border, borderRadius: 99, overflow: "hidden" }}>
                <div style={{ height: "100%", width: `${pct}%`, background: pct === 100 ? CB.green.text : CB.blue, borderRadius: 99 }} />
              </div>
            </div>
            <span style={{ fontSize: 10, color: CB.tabInactive, whiteSpace: "nowrap" }}>{paid}/{recibos.length}</span>
          </button>

          {planOpen && (
            <div style={{ padding: "10px 14px 12px", background: "#fafafa", borderTop: `1px solid ${CB.border}` }}>
              <div style={{ display: "flex", gap: 10, marginBottom: 8 }}>
                <div style={{ flex: 1 }}>
                  <span style={{ fontSize: 10, color: CB.tabInactive }}>Período</span>
                  <div style={{ fontSize: 12, fontWeight: 600, color: CB.charcoal }}>{poliza.planPago.periodoPago}</div>
                </div>
                <div style={{ flex: 1 }}>
                  <span style={{ fontSize: 10, color: CB.tabInactive }}>Método</span>
                  <div style={{ fontSize: 12, fontWeight: 600, color: CB.charcoal }}>{poliza.planPago.metodoPago}</div>
                </div>
                <div style={{ flex: 1 }}>
                  <span style={{ fontSize: 10, color: CB.tabInactive }}>Inicio</span>
                  <div style={{ fontSize: 12, fontWeight: 600, color: CB.charcoal }}>{poliza.planPago.fechaInicio}</div>
                </div>
              </div>

              {/* Recibo chips grid */}
              <div style={{ marginBottom: 6 }}>
                <span style={{ fontSize: 10, color: CB.tabInactive, display: "block", marginBottom: 5 }}>Recibos — clic para ver detalle</span>
                <div style={{ display: "flex", flexWrap: "wrap", gap: 4 }}>
                  {recibos.map(r => (
                    <ReciboChip
                      key={r.id} recibo={r}
                      onClick={recibo => onReciboSelect(recibo)}
                      selected={selectedReciboId === r.id}
                    />
                  ))}
                </div>
              </div>

              {/* Legend */}
              <div style={{ display: "flex", gap: 10, marginTop: 6 }}>
                {[
                  { color: CB.green.bg, border: CB.green.text + "44", label: "Pagado" },
                  { color: "#f3f4f6", border: CB.tabInactive + "44", label: "Pendiente" },
                  { color: CB.red.bg, border: CB.red.text + "44", label: "Vencido" },
                ].map(l => (
                  <div key={l.label} style={{ display: "flex", alignItems: "center", gap: 4 }}>
                    <div style={{ width: 10, height: 10, background: l.color, border: `1px solid ${l.border}`, borderRadius: 2 }} />
                    <span style={{ fontSize: 10, color: CB.tabInactive }}>{l.label}</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </>
      )}

      {/* Quick actions */}
      <div style={{ padding: "8px 14px", borderTop: `1px solid ${CB.border}`, display: "flex", gap: 6 }}>
        <button onClick={() => onSelect(poliza, "poliza")} style={{ flex: 1, padding: "5px 0", fontSize: 11, fontWeight: 500, border: `1px solid ${CB.border}`, borderRadius: 5, background: CB.white, cursor: "pointer", color: CB.charcoal }}>Ver detalle</button>
        <button style={{ flex: 1, padding: "5px 0", fontSize: 11, fontWeight: 500, border: `1px solid ${CB.border}`, borderRadius: 5, background: CB.white, cursor: "pointer", color: CB.charcoal }}>Endoso</button>
        <button style={{ flex: 1, padding: "5px 0", fontSize: 11, fontWeight: 500, border: "none", borderRadius: 5, background: CB.charcoal, cursor: "pointer", color: CB.white }}>Renovar</button>
      </div>
    </div>
  );
}

// ─── Slide-in Panel B ─────────────────────────────────────────────────────────
function SlidePanelB({ item, type, onClose, onMarkPaid, visible }) {
  if (!item) return null;
  const isRecibo = type === "recibo";
  const isPoliza = type === "poliza";

  const fieldStyle = {
    display: "grid", gridTemplateColumns: "130px 1fr", alignItems: "start",
    padding: "8px 0", borderBottom: `1px solid ${CB.border}`, gap: 8, fontSize: 12
  };

  return (
    <div style={{
      position: "absolute", top: 0, right: 0, bottom: 0, width: 340,
      background: CB.white, borderLeft: `1px solid ${CB.border}`,
      display: "flex", flexDirection: "column", zIndex: 10,
      boxShadow: "-6px 0 20px rgba(0,0,0,0.08)",
      transform: visible ? "translateX(0)" : "translateX(100%)",
      transition: "transform 0.22s cubic-bezier(0.4,0,0.2,1)"
    }}>
      {/* Header */}
      <div style={{ padding: "16px 18px", borderBottom: `1px solid ${CB.border}` }}>
        <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: 8 }}>
          <div style={{ fontSize: 10, color: CB.tabInactive, textTransform: "uppercase", letterSpacing: "0.06em" }}>
            {isPoliza ? "Póliza" : "Recibo de Pago"}
          </div>
          <button onClick={onClose} style={{ background: "none", border: "none", cursor: "pointer", padding: 2, color: CB.tabInactive }}>
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none"><path d="M2 2l10 10M12 2L2 12" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/></svg>
          </button>
        </div>
        <div style={{ fontSize: 14, fontWeight: 700, color: CB.charcoal, lineHeight: 1.3, marginBottom: 6 }}>{item.folio}</div>
        {isPoliza && <BadgeB status={item.estatus} />}
        {isRecibo && <BadgeB status={item.estatus} />}
      </div>

      {/* Fields */}
      <div style={{ flex: 1, overflow: "auto", padding: "4px 18px 18px" }}>
        {isPoliza && [
          ["Cliente", item.cliente],
          ["Aseguradora", item.aseguradora],
          ["Ramo", item.ramo],
          ["Producto", item.producto],
          ["Vendedor", item.vendedor],
          ["Prima neta", `$${item.prima?.toLocaleString()}`],
          ["Vigencia", `${item.vigenciaInicio} → ${item.vigenciaFin}`],
          ["Oportunidad", item.oportunidad],
        ].map(([k, v]) => (
          <div key={k} style={fieldStyle}>
            <span style={{ color: CB.tabInactive, fontWeight: 500 }}>{k}</span>
            <span style={{ color: CB.charcoal }}>{v || "—"}</span>
          </div>
        ))}

        {isRecibo && (
          <>
            {[
              ["Folio", item.folio],
              ["Monto", `$${item.monto?.toLocaleString()}`],
              ["Vencimiento", item.fechaVencimiento],
              ["Estatus", item.estatus],
            ].map(([k, v]) => (
              <div key={k} style={fieldStyle}>
                <span style={{ color: CB.tabInactive, fontWeight: 500 }}>{k}</span>
                <span style={{ color: CB.charcoal }}>{v || "—"}</span>
              </div>
            ))}
            {item.estatus !== "Pagado" && (
              <button
                onClick={() => onMarkPaid(item.id)}
                style={{
                  marginTop: 16, width: "100%", padding: "9px 0",
                  background: CB.charcoal, color: CB.white,
                  border: "none", borderRadius: 6, fontSize: 13, fontWeight: 600, cursor: "pointer"
                }}>
                Marcar como Pagado
              </button>
            )}
          </>
        )}
      </div>

      {isPoliza && (
        <div style={{ padding: "12px 18px", borderTop: `1px solid ${CB.border}`, display: "flex", gap: 8 }}>
          <button style={{ flex: 1, padding: "8px 0", background: CB.charcoal, color: CB.white, border: "none", borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: "pointer" }}>Renovar póliza</button>
          <button style={{ flex: 1, padding: "8px 0", background: CB.white, color: CB.charcoal, border: `1px solid ${CB.border}`, borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: "pointer" }}>Crear endoso</button>
        </div>
      )}
    </div>
  );
}

// ─── Stats Bar ────────────────────────────────────────────────────────────────
function StatsBar({ items, reciboEstatus }) {
  const allRecibos = items.flatMap(p => p.planPago?.recibos.map(r => ({ ...r, estatus: reciboEstatus[r.id] || r.estatus })) || []);
  const pagados = allRecibos.filter(r => r.estatus === "Pagado").length;
  const vencidos = allRecibos.filter(r => r.estatus === "Vencido").length;
  const pendientes = allRecibos.filter(r => r.estatus === "Pendiente").length;
  const primaNeta = items.reduce((s, p) => s + (p.prima || 0), 0);

  const stat = (label, value, color) => (
    <div style={{ display: "flex", flexDirection: "column", gap: 2, padding: "0 16px", borderRight: `1px solid ${CB.border}` }}>
      <span style={{ fontSize: 18, fontWeight: 700, color }}>{value}</span>
      <span style={{ fontSize: 10, color: CB.tabInactive, textTransform: "uppercase", letterSpacing: "0.05em" }}>{label}</span>
    </div>
  );

  return (
    <div style={{ padding: "12px 20px", borderBottom: `1px solid ${CB.border}`, display: "flex", alignItems: "center", gap: 0 }}>
      {stat("Pólizas", items.length, CB.charcoal)}
      {stat("Prima total", `$${primaNeta.toLocaleString()}`, CB.charcoal)}
      {stat("Recibos pagados", pagados, CB.green.text)}
      {stat("Pendientes", pendientes, CB.amber.text)}
      <div style={{ display: "flex", flexDirection: "column", gap: 2, padding: "0 16px" }}>
        <span style={{ fontSize: 18, fontWeight: 700, color: vencidos > 0 ? CB.red.text : CB.tabInactive }}>{vencidos}</span>
        <span style={{ fontSize: 10, color: CB.tabInactive, textTransform: "uppercase", letterSpacing: "0.05em" }}>Vencidos</span>
      </div>
    </div>
  );
}

// ─── Main Variacion B ─────────────────────────────────────────────────────────
function VariacionB() {
  const [activeTab, setActiveTabB] = useStateB("seguros");
  const [search, setSearchB] = useStateB("");
  const [selectedItem, setSelectedItemB] = useStateB(null);
  const [selectedType, setSelectedTypeB] = useStateB(null);
  const [panelVisible, setPanelVisibleB] = useStateB(false);
  const [selectedReciboId, setSelectedReciboIdB] = useStateB(null);
  const [reciboEstatus, setReciboEstatusB] = useStateB({});

  const items = activeTab === "seguros" ? MOCK_DATA.seguros : MOCK_DATA.fianzas;

  const filtered = items.filter(p =>
    search === "" ||
    p.folio.toLowerCase().includes(search.toLowerCase()) ||
    p.cliente.toLowerCase().includes(search.toLowerCase())
  );

  const handleSelect = useCallbackB((item, type) => {
    setSelectedItemB(item);
    setSelectedTypeB(type);
    setPanelVisibleB(true);
    setSelectedReciboIdB(null);
  }, []);

  const handleReciboSelect = useCallbackB((recibo) => {
    const withOverride = { ...recibo, estatus: reciboEstatus[recibo.id] || recibo.estatus };
    setSelectedItemB(withOverride);
    setSelectedTypeB("recibo");
    setPanelVisibleB(true);
    setSelectedReciboIdB(recibo.id);
  }, [reciboEstatus]);

  const handleClose = useCallbackB(() => {
    setPanelVisibleB(false);
    setTimeout(() => { setSelectedItemB(null); setSelectedTypeB(null); setSelectedReciboIdB(null); }, 220);
  }, []);

  const handleMarkPaid = useCallbackB(id => {
    setReciboEstatusB(prev => ({ ...prev, [id]: "Pagado" }));
    setSelectedItemB(prev => prev?.id === id ? { ...prev, estatus: "Pagado" } : prev);
  }, []);

  const tabs = [
    { id: "seguros", label: "Seguros", count: MOCK_DATA.seguros.length },
    { id: "fianzas", label: "Fianzas / PPR", count: MOCK_DATA.fianzas.length },
  ];

  return (
    <div style={{ fontFamily: "'Inter', sans-serif", background: CB.white, height: "100%", display: "flex", flexDirection: "column", position: "relative", overflow: "hidden" }}>

      {/* Module Header */}
      <div style={{ padding: "0 20px", borderBottom: `1px solid ${CB.border}` }}>
        <div style={{ display: "flex", gap: 2, paddingTop: 12 }}>
          {["Dashboard", "Prospectos", "Oportunidades", "Clientes", "Pólizas"].map(t => (
            <div key={t} style={{
              padding: "8px 16px", fontSize: 13, fontWeight: t === "Pólizas" ? 600 : 500,
              color: t === "Pólizas" ? CB.charcoal : CB.tabInactive,
              borderBottom: t === "Pólizas" ? `2px solid ${CB.charcoal}` : "2px solid transparent",
              cursor: "pointer", borderRadius: "4px 4px 0 0"
            }}>{t}</div>
          ))}
        </div>
      </div>

      {/* Toolbar */}
      <div style={{ padding: "12px 20px", borderBottom: `1px solid ${CB.border}`, display: "flex", alignItems: "center", gap: 12 }}>
        {/* Sub tabs */}
        <div style={{ display: "flex", background: CB.surface, border: `1px solid ${CB.border}`, borderRadius: 6, padding: 3, gap: 2 }}>
          {tabs.map(t => (
            <button key={t.id} onClick={() => setActiveTabB(t.id)} style={{
              padding: "5px 14px", border: "none", cursor: "pointer",
              borderRadius: 4, fontSize: 12, fontWeight: 600,
              background: activeTab === t.id ? CB.white : "transparent",
              color: activeTab === t.id ? CB.charcoal : CB.tabInactive,
              boxShadow: activeTab === t.id ? "0 1px 3px rgba(0,0,0,0.1)" : "none",
              transition: "all 0.15s"
            }}>
              {t.label}
              <span style={{ marginLeft: 6, fontSize: 10, background: activeTab === t.id ? CB.blueLight.bg : CB.border, color: activeTab === t.id ? CB.blue : CB.tabInactive, borderRadius: 99, padding: "1px 5px" }}>{t.count}</span>
            </button>
          ))}
        </div>

        {/* Search */}
        <div style={{ display: "flex", alignItems: "center", gap: 6, background: CB.surface, border: `1px solid ${CB.border}`, borderRadius: 6, padding: "5px 10px", flex: 1, maxWidth: 260 }}>
          <svg width="13" height="13" viewBox="0 0 13 13" fill="none"><circle cx="5.5" cy="5.5" r="4" stroke={CB.tabInactive} strokeWidth="1.2"/><path d="M9 9l2.5 2.5" stroke={CB.tabInactive} strokeWidth="1.2" strokeLinecap="round"/></svg>
          <input value={search} onChange={e => setSearchB(e.target.value)} placeholder="Buscar..." style={{ border: "none", background: "none", fontSize: 12, outline: "none", color: CB.charcoal, width: "100%" }} />
        </div>

        <div style={{ flex: 1 }} />
        <button style={{ padding: "6px 14px", background: CB.charcoal, color: CB.white, border: "none", borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: "pointer" }}>+ Nueva Póliza</button>
      </div>

      {/* Stats */}
      <StatsBar items={filtered} reciboEstatus={reciboEstatus} />

      {/* Cards grid */}
      <div style={{ flex: 1, overflow: "auto", padding: "16px 20px" }}>
        <div style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fill, minmax(320px, 1fr))",
          gap: 14, paddingRight: panelVisible ? 350 : 0,
          transition: "padding-right 0.22s cubic-bezier(0.4,0,0.2,1)"
        }}>
          {filtered.map(p => (
            <PolizaCard
              key={p.id}
              poliza={p}
              onSelect={handleSelect}
              selectedId={selectedItem?.id}
              onReciboSelect={handleReciboSelect}
              selectedReciboId={selectedReciboId}
              reciboEstatus={reciboEstatus}
            />
          ))}
          {filtered.length === 0 && (
            <div style={{ gridColumn: "1 / -1", padding: 40, textAlign: "center", color: CB.tabInactive, fontSize: 13 }}>Sin resultados</div>
          )}
        </div>
      </div>

      {/* Slide panel */}
      <SlidePanelB
        item={selectedItem}
        type={selectedType}
        onClose={handleClose}
        onMarkPaid={handleMarkPaid}
        visible={panelVisible}
      />
    </div>
  );
}

Object.assign(window, { VariacionB });
