// ============================================================
// SEED: Dashboard Completo – Ajelet García
// Crea fianzas vigentes, en plazo, vencidas y canceladas
// con contratos y proyectos vinculados.
//
// Ejecución:
//   sf apex run --file scripts/seed_dashboard_completo.apex --target-org Ollin
// ============================================================

final Id AJELET_ID = 'a0Fct0000055LtlEAE';
// No_Contrato__c es lookup al objeto estándar Contract (prefijo 800), no a Contrato__c
final Id STD_CONTRACT = '800ct00000WGPOFAA5'; // único Contract estándar disponible

// ── 0. Limpiar demo anterior ───────────────────────────────
List<Fianza__c> viejas = [
    SELECT Id FROM Fianza__c
    WHERE ContratistaFianza__c = :AJELET_ID
    AND (Name LIKE 'FZ-DEMO-%' OR Name LIKE 'FZ-TEST-%')
];
if (!viejas.isEmpty()) {
    // Borrar relaciones primero
    List<Tech_Relacion__c> relsViejas = [
        SELECT Id FROM Tech_Relacion__c
        WHERE Fianza__c IN :new Map<Id,Fianza__c>(viejas).keySet()
    ];
    if (!relsViejas.isEmpty()) delete relsViejas;
    delete viejas;
    System.debug('0. Limpieza: ' + viejas.size() + ' fianzas demo eliminadas');
} else {
    System.debug('0. Sin datos demo previos');
}

// ── 1. Contratos ───────────────────────────────────────────
// Intenta crear nuevos; si ya existen con ese nombre los reutiliza
List<Contrato__c> contratos = new List<Contrato__c>();
List<Contrato__c> contratosExistentes = [
    SELECT Id, Name FROM Contrato__c
    WHERE Name IN ('CT-DEMO-Autopista-Norte', 'CT-DEMO-Planta-Industrial', 'CT-DEMO-Centro-Comercial')
];
Map<String, Id> contratosPorNombre = new Map<String, Id>();
for (Contrato__c c : contratosExistentes) contratosPorNombre.put(c.Name, c.Id);

List<Contrato__c> nuevosContratos = new List<Contrato__c>();
if (!contratosPorNombre.containsKey('CT-DEMO-Autopista-Norte'))
    nuevosContratos.add(new Contrato__c(Name = 'CT-DEMO-Autopista-Norte'));
if (!contratosPorNombre.containsKey('CT-DEMO-Planta-Industrial'))
    nuevosContratos.add(new Contrato__c(Name = 'CT-DEMO-Planta-Industrial'));
if (!contratosPorNombre.containsKey('CT-DEMO-Centro-Comercial'))
    nuevosContratos.add(new Contrato__c(Name = 'CT-DEMO-Centro-Comercial'));

if (!nuevosContratos.isEmpty()) {
    insert nuevosContratos;
    for (Contrato__c c : nuevosContratos) contratosPorNombre.put(c.Name, c.Id);
    System.debug('1. Contratos nuevos: ' + nuevosContratos.size());
} else {
    System.debug('1. Contratos ya existían');
}

Id ctAutopista  = contratosPorNombre.get('CT-DEMO-Autopista-Norte');
Id ctPlanta     = contratosPorNombre.get('CT-DEMO-Planta-Industrial');
Id ctComercial  = contratosPorNombre.get('CT-DEMO-Centro-Comercial');

// ── 2. Proyectos ───────────────────────────────────────────
List<Proyecto__c> proyExistentes = [
    SELECT Id, Name FROM Proyecto__c
    WHERE Name IN ('PRY-DEMO-Autopista', 'PRY-DEMO-Planta', 'PRY-DEMO-Comercial')
];
Map<String, Id> proyPorNombre = new Map<String, Id>();
for (Proyecto__c p : proyExistentes) proyPorNombre.put(p.Name, p.Id);

List<Proyecto__c> nuevosProy = new List<Proyecto__c>();
if (!proyPorNombre.containsKey('PRY-DEMO-Autopista'))
    nuevosProy.add(new Proyecto__c(Name = 'PRY-DEMO-Autopista'));
if (!proyPorNombre.containsKey('PRY-DEMO-Planta'))
    nuevosProy.add(new Proyecto__c(Name = 'PRY-DEMO-Planta'));
if (!proyPorNombre.containsKey('PRY-DEMO-Comercial'))
    nuevosProy.add(new Proyecto__c(Name = 'PRY-DEMO-Comercial'));

if (!nuevosProy.isEmpty()) {
    insert nuevosProy;
    for (Proyecto__c p : nuevosProy) proyPorNombre.put(p.Name, p.Id);
    System.debug('2. Proyectos nuevos: ' + nuevosProy.size());
} else {
    System.debug('2. Proyectos ya existían');
}

Id pryAutopista = proyPorNombre.get('PRY-DEMO-Autopista');
Id pryPlanta    = proyPorNombre.get('PRY-DEMO-Planta');
Id pryComercial = proyPorNombre.get('PRY-DEMO-Comercial');

// ── 3. Fianzas ─────────────────────────────────────────────
// 3 vigentes/en plazo (barra azul del chart) + 3 vencidas/canceladas (barra amarilla + tabla)

// Vigente - monto grande, vence en 18 meses
Fianza__c fz1 = new Fianza__c(
    Name                    = 'FZ-DEMO-001',
    ContratistaFianza__c    = AJELET_ID,
    Estatus__c              = 'Vigente',
    Monto_Afianzado__c      = 320000,
    No_Contrato__c          = STD_CONTRACT,
    Fecha_de_Emisi_n__c     = Date.today().addMonths(-6),
    Fecha_de_Vencimiento__c = Date.today().addMonths(18)
);

// Vigente - monto mediano, vence en 8 meses
Fianza__c fz2 = new Fianza__c(
    Name                    = 'FZ-DEMO-002',
    ContratistaFianza__c    = AJELET_ID,
    Estatus__c              = 'Vigente',
    Monto_Afianzado__c      = 185000,
    No_Contrato__c          = STD_CONTRACT,
    Fecha_de_Emisi_n__c     = Date.today().addMonths(-4),
    Fecha_de_Vencimiento__c = Date.today().addMonths(8)
);

// En plazo - a punto de vencer
Fianza__c fz3 = new Fianza__c(
    Name                    = 'FZ-DEMO-003',
    ContratistaFianza__c    = AJELET_ID,
    Estatus__c              = 'En plazo',
    Monto_Afianzado__c      = 90000,
    No_Contrato__c          = STD_CONTRACT,
    Fecha_de_Emisi_n__c     = Date.today().addMonths(-14),
    Fecha_de_Vencimiento__c = Date.today().addDays(45)
);

// Vencida - aparece en tabla Fianzas Vencidas
Fianza__c fz4 = new Fianza__c(
    Name                    = 'FZ-DEMO-004',
    ContratistaFianza__c    = AJELET_ID,
    Estatus__c              = 'Vencida',
    Monto_Afianzado__c      = 210000,
    No_Contrato__c          = STD_CONTRACT,
    Fecha_de_Emisi_n__c     = Date.today().addMonths(-24),
    Fecha_de_Vencimiento__c = Date.today().addDays(-60)
);

// Vencida - aparece en tabla Fianzas Vencidas
Fianza__c fz5 = new Fianza__c(
    Name                    = 'FZ-DEMO-005',
    ContratistaFianza__c    = AJELET_ID,
    Estatus__c              = 'Vencida',
    Monto_Afianzado__c      = 95000,
    No_Contrato__c          = STD_CONTRACT,
    Fecha_de_Emisi_n__c     = Date.today().addMonths(-18),
    Fecha_de_Vencimiento__c = Date.today().addDays(-30)
);

// Cancelada - aparece en tabla Fianzas Vencidas
Fianza__c fz6 = new Fianza__c(
    Name                    = 'FZ-DEMO-006',
    ContratistaFianza__c    = AJELET_ID,
    Estatus__c              = 'Cancelada',
    Monto_Afianzado__c      = 55000,
    No_Contrato__c          = STD_CONTRACT,
    Fecha_de_Emisi_n__c     = Date.today().addMonths(-36),
    Fecha_de_Vencimiento__c = Date.today().addDays(-200)
);

insert new List<Fianza__c>{ fz1, fz2, fz3, fz4, fz5, fz6 };
System.debug('3. Fianzas creadas: 6 (3 vigentes/en plazo, 2 vencidas, 1 cancelada)');

// ── 4. Relaciones Fianza → Contrato (para tabla Contratos en dashboard) ──
insert new List<Tech_Relacion__c>{
    new Tech_Relacion__c(Tipo__c = 'Contrato', Fianza__c = fz1.Id, Contrato__c = ctAutopista),
    new Tech_Relacion__c(Tipo__c = 'Contrato', Fianza__c = fz2.Id, Contrato__c = ctPlanta),
    new Tech_Relacion__c(Tipo__c = 'Contrato', Fianza__c = fz3.Id, Contrato__c = ctComercial),
    new Tech_Relacion__c(Tipo__c = 'Contrato', Fianza__c = fz4.Id, Contrato__c = ctAutopista),
    new Tech_Relacion__c(Tipo__c = 'Contrato', Fianza__c = fz5.Id, Contrato__c = ctPlanta),
    new Tech_Relacion__c(Tipo__c = 'Contrato', Fianza__c = fz6.Id, Contrato__c = ctComercial)
};
System.debug('4. Relaciones Fianza-Contrato: 6');

// ── 5. Relaciones Fianza → Proyecto ───────────────────────
insert new List<Tech_Relacion__c>{
    new Tech_Relacion__c(Tipo__c = 'Proyecto', Fianza__c = fz1.Id, Proyecto__c = pryAutopista),
    new Tech_Relacion__c(Tipo__c = 'Proyecto', Fianza__c = fz2.Id, Proyecto__c = pryPlanta),
    new Tech_Relacion__c(Tipo__c = 'Proyecto', Fianza__c = fz3.Id, Proyecto__c = pryComercial),
    new Tech_Relacion__c(Tipo__c = 'Proyecto', Fianza__c = fz4.Id, Proyecto__c = pryAutopista),
    new Tech_Relacion__c(Tipo__c = 'Proyecto', Fianza__c = fz5.Id, Proyecto__c = pryPlanta),
    new Tech_Relacion__c(Tipo__c = 'Proyecto', Fianza__c = fz6.Id, Proyecto__c = pryComercial)
};
System.debug('5. Relaciones Fianza-Proyecto: 6');

// ── 6. Resumen ─────────────────────────────────────────────
List<AggregateResult> agg = [
    SELECT Estatus__c, COUNT(Id) cnt, SUM(Monto_Afianzado__c) monto
    FROM Fianza__c
    WHERE ContratistaFianza__c = :AJELET_ID
    GROUP BY Estatus__c
];
Decimal totalMonto = 0;
System.debug('=== RESULTADO FINAL ===');
for (AggregateResult ar : agg) {
    Decimal m = (Decimal)ar.get('monto');
    if (m == null) m = 0;
    totalMonto += m;
    System.debug('  ' + ar.get('Estatus__c') + ': ' + ar.get('cnt') + ' fianza(s) · $' + m.format());
}
System.debug('  TOTAL AFIANZADO: $' + totalMonto.format());
System.debug('  Contratos en dashboard: 3');
System.debug('  Proyectos vinculados: 3');
System.debug('  Fianzas vencidas/canceladas (tabla): 3 → 2 en donut rojo (<90 días), 1 en azul');
