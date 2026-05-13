// =============================================================================
// SEED: Datos de Prueba - ProyectoOllin2026
// Ejecutar: sf apex run --file scripts/apex/seed_datos_prueba.apex
// Crea un flujo completo con datos realistas para probar todos los LWCs:
//   Fianzas · Contratos · Ampliaciones · Beneficiarios · Contratistas
//   + Seguros · Planes de Pago · Recibos · Comisiones · Vendedores
// =============================================================================

// ── 0. RecordType IDs ──────────────────────────────────────────────────────
Map<String, Id> rtMap = new Map<String, Id>();
for (RecordType rt : [
    SELECT Id, DeveloperName
    FROM RecordType
    WHERE SobjectType = 'Account'
    AND DeveloperName IN ('Contratista', 'Beneficiario', 'Institucion', 'cuenta_negocio')
]) {
    rtMap.put(rt.DeveloperName, rt.Id);
}

// ── 1. VENDEDORES ──────────────────────────────────────────────────────────
List<Tech_Vendedor__c> vendedores = new List<Tech_Vendedor__c>{
    new Tech_Vendedor__c(
        Name__c                     = 'Carlos Mendoza Ríos',
        Email__c                    = 'carlos.mendoza@ollin.com.mx',
        Telefono__c                 = '5512345678',
        Tipo_vendedor__c            = 'Humano',
        Estatus__c                  = 'Activo',
        Zona__c                     = 'CDMX Norte',
        Promotoria__c               = 'Grupo Mendoza & Asociados',
        Ramos__c                    = 'Fianzas;Danos',
        Porcentaje_Comision_Ollin__c = 12,
        Fecha_Inicio__c             = Date.newInstance(2023, 1, 15),
        Carga_Trabajo__c            = 18
    ),
    new Tech_Vendedor__c(
        Name__c                     = 'Sofía Reyes Gutiérrez',
        Email__c                    = 'sofia.reyes@ollin.com.mx',
        Telefono__c                 = '5587654321',
        Tipo_vendedor__c            = 'Humano',
        Estatus__c                  = 'Activo',
        Zona__c                     = 'Guadalajara',
        Promotoria__c               = 'Seguros del Occidente',
        Ramos__c                    = 'GMM;Vida;Auto',
        Porcentaje_Comision_Ollin__c = 15,
        Fecha_Inicio__c             = Date.newInstance(2022, 6, 1),
        Carga_Trabajo__c            = 24
    )
};
insert vendedores;
Tech_Vendedor__c vCarlos = vendedores[0];
Tech_Vendedor__c vSofia  = vendedores[1];

// ── 2. ACCOUNTS ────────────────────────────────────────────────────────────
// Contratistas (empresas que solicitan fianzas)
List<Account> cuentas = new List<Account>{
    // Contratista 1 — gran constructora
    new Account(
        Name            = 'Constructora Montoya & Asociados S.A. de C.V.',
        RFC__c          = 'CMA890312HV4',
        RecordTypeId    = rtMap.get('Contratista'),
        BillingCity     = 'Ciudad de México',
        BillingState    = 'CDMX',
        BillingCountry  = 'México',
        Phone           = '5533445566',
        Website         = 'www.constructoramontoya.com.mx'
    ),
    // Contratista 2 — empresa mediana
    new Account(
        Name            = 'Infraestructura del Bajío S.A. de C.V.',
        RFC__c          = 'IBA120508TY9',
        RecordTypeId    = rtMap.get('Contratista'),
        BillingCity     = 'León',
        BillingState    = 'Guanajuato',
        BillingCountry  = 'México',
        Phone           = '4777654321'
    ),
    // Beneficiarios (dependencias o empresas que reciben la garantía)
    new Account(
        Name            = 'Secretaría de Infraestructura y Comunicaciones de Jalisco',
        RFC__c          = 'SIC730401GX1',
        RecordTypeId    = rtMap.get('Beneficiario'),
        BillingCity     = 'Guadalajara',
        BillingState    = 'Jalisco',
        BillingCountry  = 'México',
        Phone           = '3336151500'
    ),
    new Account(
        Name            = 'Comisión Federal de Electricidad',
        RFC__c          = 'CFE370814QI0',
        RecordTypeId    = rtMap.get('Beneficiario'),
        BillingCity     = 'Ciudad de México',
        BillingState    = 'CDMX',
        BillingCountry  = 'México',
        Phone           = '5555537000'
    ),
    // Afianzadoras / Aseguradoras (Institucion RT — son entidades supervisadas)
    new Account(
        Name            = 'Chubb de México Compañía Afianzadora',
        RFC__c          = 'CMA670712KK6',
        RecordTypeId    = rtMap.get('Institucion'),
        BillingCity     = 'Ciudad de México',
        BillingState    = 'CDMX',
        BillingCountry  = 'México'
    ),
    new Account(
        Name            = 'Qualitas Compañía de Seguros',
        RFC__c          = 'QCS931209G49',
        RecordTypeId    = rtMap.get('Institucion'),
        BillingCity     = 'Ciudad de México',
        BillingState    = 'CDMX',
        BillingCountry  = 'México'
    ),
    new Account(
        Name            = 'GNP Seguros',
        RFC__c          = 'GNP931022TK1',
        RecordTypeId    = rtMap.get('Institucion'),
        BillingCity     = 'Ciudad de México',
        BillingState    = 'CDMX',
        BillingCountry  = 'México'
    ),
    // Institución pública
    new Account(
        Name            = 'Instituto Mexicano del Seguro Social',
        RFC__c          = 'IMS430714ZJ3',
        RecordTypeId    = rtMap.get('Institucion'),
        BillingCity     = 'Ciudad de México',
        BillingState    = 'CDMX',
        BillingCountry  = 'México',
        Phone           = '8000900696'
    )
};
insert cuentas;

Account acMontoya   = cuentas[0]; // Contratista 1
Account acBajio     = cuentas[1]; // Contratista 2
Account acJalisco   = cuentas[2]; // Beneficiario 1
Account acCFE       = cuentas[3]; // Beneficiario 2
Account acChubb     = cuentas[4]; // Afianzadora
Account acQualitas  = cuentas[5]; // Aseguradora 1
Account acGNP       = cuentas[6]; // Aseguradora 2
Account acIMSS      = cuentas[7]; // Institución

// ── 3. CONTRATOS ───────────────────────────────────────────────────────────
List<Contract> contratos = new List<Contract>{
    new Contract(
        AccountId                = acMontoya.Id,
        Contratista__c           = acMontoya.Id,
        Beneficiario__c          = acJalisco.Id,
        Status                   = 'Draft',
        StartDate                = Date.newInstance(2024, 3, 1),
        ContractTerm             = 24,
        Valor_Contrato_Vigente__c = 45000000,
        Fin_Contrato_Vigente__c  = Date.newInstance(2026, 2, 28),
        Exposicion_del__c        = 30
    ),
    new Contract(
        AccountId                = acBajio.Id,
        Contratista__c           = acBajio.Id,
        Beneficiario__c          = acCFE.Id,
        Status                   = 'Draft',
        StartDate                = Date.newInstance(2024, 7, 15),
        ContractTerm             = 12,
        Valor_Contrato_Vigente__c = 18500000,
        Fin_Contrato_Vigente__c  = Date.newInstance(2025, 7, 14),
        Exposicion_del__c        = 25
    )
};
insert contratos;
Contract ctMontoya = contratos[0];
Contract ctBajio   = contratos[1];

// ── 4. FIANZAS ─────────────────────────────────────────────────────────────
List<Tech_Fianza__c> fianzas = new List<Tech_Fianza__c>{
    // Fianza 1 — Cumplimiento Vigente (>90 días para vencer)
    new Tech_Fianza__c(
        Contratistas__c              = acMontoya.Id,
        Beneficiarios__c             = acJalisco.Id,
        Afianzadoras__c              = acChubb.Id,
        Vendedor__c                  = vCarlos.Id,
        Contrato__c                  = ctMontoya.Id,
        Tipo_de_Riesgo__c            = 'Cumplimiento',
        Estatus__c                   = 'Vigente',
        Monto_Afianzado__c           = 13500000,
        Monto_Afianzado_Vigente__c   = 13500000,
        Prima_neta__c                = 121500,
        Prima_Vigente__c             = 121500,
        Costo_de_fianza__c           = 148230,
        Fecha_de_Emision__c          = Date.newInstance(2024, 3, 5),
        Fecha_de_Vencimiento__c      = Date.newInstance(2026, 3, 4),
        Fecha_Vencimiento_Vigente__c = Date.newInstance(2026, 3, 4),
        DiasReclamaci_n__c           = 365,
        Exposicion__c                = 30
    ),
    // Fianza 2 — Anticipo Vigente (31-90 días, semáforo Amarillo si fuera seguro)
    new Tech_Fianza__c(
        Contratistas__c              = acMontoya.Id,
        Beneficiarios__c             = acJalisco.Id,
        Afianzadoras__c              = acChubb.Id,
        Vendedor__c                  = vCarlos.Id,
        Contrato__c                  = ctMontoya.Id,
        Tipo_de_Riesgo__c            = 'Anticipo',
        Estatus__c                   = 'Vigente',
        Monto_Afianzado__c           = 9000000,
        Monto_Afianzado_Vigente__c   = 9000000,
        Prima_neta__c                = 81000,
        Prima_Vigente__c             = 81000,
        Costo_de_fianza__c           = 98820,
        Fecha_de_Emision__c          = Date.newInstance(2024, 3, 5),
        Fecha_de_Vencimiento__c      = Date.newInstance(2026, 2, 28),
        Fecha_Vencimiento_Vigente__c = Date.newInstance(2026, 2, 28),
        DiasReclamaci_n__c           = 180,
        Exposicion__c                = 20
    ),
    // Fianza 3 — Vicios y Defectos Emitida (contrato Bajío)
    new Tech_Fianza__c(
        Contratistas__c              = acBajio.Id,
        Beneficiarios__c             = acCFE.Id,
        Afianzadoras__c              = acChubb.Id,
        Vendedor__c                  = vCarlos.Id,
        Contrato__c                  = ctBajio.Id,
        Tipo_de_Riesgo__c            = 'Vicios y Defectos Ocultos',
        Estatus__c                   = 'Emitida',
        Monto_Afianzado__c           = 4625000,
        Monto_Afianzado_Vigente__c   = 4625000,
        Prima_neta__c                = 41625,
        Prima_Vigente__c             = 41625,
        Costo_de_fianza__c           = 50782.50,
        Fecha_de_Emision__c          = Date.newInstance(2024, 7, 20),
        Fecha_de_Vencimiento__c      = Date.newInstance(2026, 7, 14),
        Fecha_Vencimiento_Vigente__c = Date.newInstance(2026, 7, 14),
        DiasReclamaci_n__c           = 365,
        Exposicion__c                = 25
    ),
    // Fianza 4 — Pasivos Laborales Vencida (histórico)
    new Tech_Fianza__c(
        Contratistas__c              = acBajio.Id,
        Beneficiarios__c             = acCFE.Id,
        Afianzadoras__c              = acChubb.Id,
        Vendedor__c                  = vCarlos.Id,
        Contrato__c                  = ctBajio.Id,
        Tipo_de_Riesgo__c            = 'Pasivos Laborales',
        Estatus__c                   = 'Vencida',
        Monto_Afianzado__c           = 1850000,
        Monto_Afianzado_Vigente__c   = 1850000,
        Prima_neta__c                = 16650,
        Prima_Vigente__c             = 16650,
        Costo_de_fianza__c           = 20313,
        Fecha_de_Emision__c          = Date.newInstance(2023, 7, 15),
        Fecha_de_Vencimiento__c      = Date.newInstance(2024, 7, 14),
        Fecha_Vencimiento_Vigente__c = Date.newInstance(2024, 7, 14),
        DiasReclamaci_n__c           = 365,
        Exposicion__c                = 10
    )
};
insert fianzas;
Tech_Fianza__c fz1 = fianzas[0];
Tech_Fianza__c fz2 = fianzas[1];
Tech_Fianza__c fz3 = fianzas[2];
Tech_Fianza__c fz4 = fianzas[3];

// ── 5. SEGUROS ─────────────────────────────────────────────────────────────
Date hoy = Date.today();
List<Tech_Seguro__c> seguros = new List<Tech_Seguro__c>{
    // Seguro 1 — GMM Vigente (verde: vence en 200 días)
    new Tech_Seguro__c(
        Cliente__c              = acMontoya.Id,
        Aseguradora__c          = acGNP.Id,
        Vendedor__c             = vSofia.Id,
        Ramo__c                 = 'GMM',
        Subproducto__c          = 'Gastos Médicos Mayores Colectivo',
        Estatus__c              = 'Vigente',
        Numero_poliza__c        = 'GNP-GMM-2024-00887',
        Inicio_del_seguro__c    = Date.newInstance(2024, 11, 1),
        Fin_del_seguro__c       = hoy.addDays(200),
        Prima_neta__c           = 180000,
        Descuento__c            = 9000,
        Recargos__c             = 0,
        Derechos__c             = 1500,
        IVA__c                  = 27360,
        Ajuste__c               = 0,
        Pct_Comision__c         = 15,
        Monto_Comision__c       = 27000,
        Frecuencia_de_pago__c   = 'Mensual',
        Forma_de_pago__c        = 'Transferencia',
        Canal__c                = 'Consultivo',
        Semaforo_renovacion__c  = 'Verde',
        Tipo_originador__c      = 'Humano'
    ),
    // Seguro 2 — Auto Vigente (amarillo: vence en 60 días)
    new Tech_Seguro__c(
        Cliente__c              = acBajio.Id,
        Aseguradora__c          = acQualitas.Id,
        Vendedor__c             = vSofia.Id,
        Ramo__c                 = 'Auto',
        Subproducto__c          = 'Flota de vehículos comerciales',
        Estatus__c              = 'Vigente',
        Numero_poliza__c        = 'QCS-AUTO-2025-04421',
        Inicio_del_seguro__c    = hoy.addDays(-305),
        Fin_del_seguro__c       = hoy.addDays(60),
        Prima_neta__c           = 95000,
        Descuento__c            = 4750,
        Recargos__c             = 1900,
        Derechos__c             = 800,
        IVA__c                  = 14792,
        Ajuste__c               = 0,
        Pct_Comision__c         = 12,
        Monto_Comision__c       = 11400,
        Frecuencia_de_pago__c   = 'Anual',
        Forma_de_pago__c        = 'Transferencia',
        Canal__c                = 'Consultivo',
        Semaforo_renovacion__c  = 'Amarillo',
        Tipo_originador__c      = 'Humano'
    ),
    // Seguro 3 — Vida Por renovar (rojo: vence en 15 días)
    new Tech_Seguro__c(
        Cliente__c              = acMontoya.Id,
        Aseguradora__c          = acGNP.Id,
        Vendedor__c             = vSofia.Id,
        Ramo__c                 = 'Vida',
        Subproducto__c          = 'Vida Grupo',
        Estatus__c              = 'Por renovar',
        Numero_poliza__c        = 'GNP-VIDA-2024-01123',
        Inicio_del_seguro__c    = hoy.addDays(-350),
        Fin_del_seguro__c       = hoy.addDays(15),
        Prima_neta__c           = 62000,
        Descuento__c            = 0,
        Recargos__c             = 1240,
        Derechos__c             = 600,
        IVA__c                  = 10054.40,
        Ajuste__c               = 0,
        Pct_Comision__c         = 18,
        Monto_Comision__c       = 11160,
        Frecuencia_de_pago__c   = 'Anual',
        Forma_de_pago__c        = 'Domiciliación',
        Canal__c                = 'Promotoría',
        Semaforo_renovacion__c  = 'Rojo',
        Tipo_originador__c      = 'Humano'
    ),
    // Seguro 4 — Daños Cancelado (histórico)
    new Tech_Seguro__c(
        Cliente__c              = acBajio.Id,
        Aseguradora__c          = acQualitas.Id,
        Vendedor__c             = vSofia.Id,
        Ramo__c                 = 'Daños',
        Subproducto__c          = 'Incendio y Terremoto',
        Estatus__c              = 'Cancelada',
        Numero_poliza__c        = 'QCS-DAN-2023-00299',
        Inicio_del_seguro__c    = Date.newInstance(2023, 1, 1),
        Fin_del_seguro__c       = Date.newInstance(2024, 1, 1),
        Prima_neta__c           = 38000,
        Descuento__c            = 1900,
        Recargos__c             = 0,
        Derechos__c             = 500,
        IVA__c                  = 5856,
        Ajuste__c               = 0,
        Pct_Comision__c         = 10,
        Monto_Comision__c       = 3800,
        Frecuencia_de_pago__c   = 'Anual',
        Forma_de_pago__c        = 'Transferencia',
        Canal__c                = 'Digital',
        Semaforo_renovacion__c  = 'Rojo',
        Tipo_originador__c      = 'Humano'
    )
};
insert seguros;
Tech_Seguro__c sg1 = seguros[0]; // GMM Verde
Tech_Seguro__c sg2 = seguros[1]; // Auto Amarillo
Tech_Seguro__c sg3 = seguros[2]; // Vida Rojo
Tech_Seguro__c sg4 = seguros[3]; // Daños Cancelado

// ── 6. PLANES DE PAGO ──────────────────────────────────────────────────────
List<Tech_Plan_de_Pago__c> planes = new List<Tech_Plan_de_Pago__c>{
    // Plan 1 — Para fianza 1 (12 mensualidades)
    new Tech_Plan_de_Pago__c(
        Fianzas__c              = fz1.Id,
        Monto_total__c          = 148230,
        Num_recibos__c          = 12,
        Periodo_Pago__c         = 'Mensual',
        Metodo_Pago__c          = 'Transferencia (SPEI)',
        Fecha_inicio__c         = Date.newInstance(2024, 3, 5),
        Estado__c               = 'Activo',
        Estatus__c              = 'Activo',
        Dia_cobro_mensual__c    = 5,
        Domiciliacion_activa__c = false,
        Ultimos_4_digitos__c    = '4521'
    ),
    // Plan 2 — Para seguro GMM (mensual, 12 recibos)
    new Tech_Plan_de_Pago__c(
        Monto_total__c          = 199660,
        Num_recibos__c          = 12,
        Periodo_Pago__c         = 'Mensual',
        Metodo_Pago__c          = 'Domiciliacion bancaria',
        Fecha_inicio__c         = Date.newInstance(2024, 11, 1),
        Estado__c               = 'Activo',
        Estatus__c              = 'Activo',
        Dia_cobro_mensual__c    = 1,
        Domiciliacion_activa__c = true,
        Referencia_domiciliacion__c = 'CIE-GNP-88720',
        Ultimos_4_digitos__c    = '7834'
    ),
    // Plan 3 — Para fianza 3 (contado, 1 recibo)
    new Tech_Plan_de_Pago__c(
        Fianzas__c              = fz3.Id,
        Monto_total__c          = 50782.50,
        Num_recibos__c          = 1,
        Periodo_Pago__c         = 'Contado',
        Metodo_Pago__c          = 'Transferencia (SPEI)',
        Fecha_inicio__c         = Date.newInstance(2024, 7, 20),
        Estado__c               = 'Activo',
        Estatus__c              = 'Activo',
        Domiciliacion_activa__c = false,
        Ultimos_4_digitos__c    = '9901'
    )
};
insert planes;
Tech_Plan_de_Pago__c pl1 = planes[0];
Tech_Plan_de_Pago__c pl2 = planes[1];
Tech_Plan_de_Pago__c pl3 = planes[2];

// ── 7. RECIBOS DE PAGO ─────────────────────────────────────────────────────
List<Tech_Recibo_Pago__c> recibos = new List<Tech_Recibo_Pago__c>();

// Plan 1: 12 recibos mensuales de fianza 1 (algunos ya pagados)
Decimal montoPorReciboP1 = 148230.00 / 12;
for (Integer i = 1; i <= 12; i++) {
    Date fProg = Date.newInstance(2024, 3, 5).addDays((i - 1) * 30);
    String estado = (i <= 4) ? 'Pagado' : ((i == 5) ? 'Vencido' : 'Programado');
    Decimal cobrado = (i <= 4) ? montoPorReciboP1 : null;
    recibos.add(new Tech_Recibo_Pago__c(
        Plan_de_Pagos__c     = pl1.Id,
        Numero__c            = i,
        Monto_programado__c  = montoPorReciboP1.setScale(2),
        Monto_cobrado__c     = cobrado,
        Fecha_programada__c  = fProg,
        Fecha_pago__c        = (i <= 4) ? fProg.addDays(1) : null,
        Estado__c            = 'Programado',
        Metodo_pago__c       = 'Transferencia (SPEI)',
        Poliza_numero__c     = fz1.Name,
        Referencia_pago__c   = (i <= 4) ? 'REF-SPEI-' + String.valueOf(2024030500 + i) : null
    ));
}

// Plan 2: 12 recibos mensuales del seguro GMM (6 cobrados, 1 en mora, 5 por venir)
Decimal montoPorReciboP2 = 199660.00 / 12;
for (Integer i = 1; i <= 12; i++) {
    Date fProg = Date.newInstance(2024, 11, 1).addDays((i - 1) * 30);
    Decimal cobrado = (i <= 6) ? montoPorReciboP2 : null;
    recibos.add(new Tech_Recibo_Pago__c(
        Plan_de_Pagos__c     = pl2.Id,
        Numero__c            = i,
        Monto_programado__c  = montoPorReciboP2.setScale(2),
        Monto_cobrado__c     = cobrado,
        Fecha_programada__c  = fProg,
        Fecha_pago__c        = (i <= 6) ? fProg : null,
        Estado__c            = 'Programado',
        Metodo_pago__c       = 'Domiciliacion bancaria',
        Poliza_numero__c     = 'GNP-GMM-2024-00887',
        Referencia_pago__c   = (i <= 6) ? 'DOM-GNP-2024-' + String.valueOf(1000 + i) : null,
        Intentos_Contacto__c = (i == 7) ? 2 : 0
    ));
}

// Plan 3: 1 recibo de contado (ya pagado)
recibos.add(new Tech_Recibo_Pago__c(
    Plan_de_Pagos__c     = pl3.Id,
    Numero__c            = 1,
    Monto_programado__c  = 50782.50,
    Monto_cobrado__c     = 50782.50,
    Fecha_programada__c  = Date.newInstance(2024, 7, 20),
    Fecha_pago__c        = Date.newInstance(2024, 7, 22),
    Estado__c            = 'Programado',
    Metodo_pago__c       = 'Transferencia (SPEI)',
    Poliza_numero__c     = fz3.Name,
    Referencia_pago__c   = 'REF-SPEI-20240722001'
));

insert recibos;

// ── 8. ENDOSOS / AMPLIACIONES ──────────────────────────────────────────────
List<Tech_Endoso__c> endosos = new List<Tech_Endoso__c>{
    // Endoso 1 — Ampliación de monto en fianza 1
    new Tech_Endoso__c(
        Fianza__c           = fz1.Id,
        Tipo_endoso__c      = 'Cambio datos',
        Estado__c           = 'Borrador',
        Fecha_efectiva__c   = Date.newInstance(2024, 9, 1),
        Fin_Vigencia__c     = Date.newInstance(2026, 3, 4),
        Fin_Contrato__c     = Date.newInstance(2026, 2, 28),
        Diferencia_monto__c = 1500000,
        Nueva_prima__c      = 135000,
        Afecta_prima__c     = true,
        Motivo__c           = 'El contrato original fue ampliado en alcance por dictamen técnico DT-2024-0891. Se incrementa el monto afianzado en $1,500,000 para cubrir trabajos adicionales de pavimentación.',
        Observaciones__c    = 'Autorización previa de Chubb de México recibida el 25-ago-2024.'
    ),
    // Endoso 2 — Cambio de datos en fianza 3
    new Tech_Endoso__c(
        Fianza__c           = fz3.Id,
        Tipo_endoso__c      = 'Cambio datos',
        Estado__c           = 'Borrador',
        Fecha_efectiva__c   = Date.newInstance(2024, 10, 15),
        Fin_Vigencia__c     = Date.newInstance(2026, 7, 14),
        Fin_Contrato__c     = Date.newInstance(2025, 7, 14),
        Diferencia_monto__c = 0,
        Nueva_prima__c      = 41625,
        Afecta_prima__c     = false,
        Motivo__c           = 'Corrección de datos del contratante: razón social actualizada de "Infraestructura del Bajío" a "Infraestructura del Bajío S.A. de C.V." según escritura notarial 1247.',
        Observaciones__c    = 'Sin impacto en prima ni en monto.'
    )
};
insert endosos;

// ── 9. COMISIONES ──────────────────────────────────────────────────────────
List<Tech_Comision__c> comisiones = new List<Tech_Comision__c>{
    // Comisión 1 — Fianza 1 (Vigente → auto-generada por flow)
    new Tech_Comision__c(
        Fianza__c           = fz1.Id,
        Vendedor__c         = vCarlos.Id,
        Estatus__c          = 'Liberada',
        Pct_Aplicado__c     = 12,
        Monto_Vendedor__c   = 14587.20,
        Monto_Ollin__c      = 2189.08
    ),
    // Comisión 2 — Fianza 2
    new Tech_Comision__c(
        Fianza__c           = fz2.Id,
        Vendedor__c         = vCarlos.Id,
        Estatus__c          = 'Devengada',
        Pct_Aplicado__c     = 12,
        Monto_Vendedor__c   = 9734.40,
        Monto_Ollin__c      = 1460.16
    ),
    // Comisión 3 — Seguro GMM
    new Tech_Comision__c(
        Seguro__c           = sg1.Id,
        Vendedor__c         = vSofia.Id,
        Estatus__c          = 'Pagada',
        Pct_Aplicado__c     = 15,
        Monto_Vendedor__c   = 22950,
        Monto_Ollin__c      = 4050
    ),
    // Comisión 4 — Seguro Auto
    new Tech_Comision__c(
        Seguro__c           = sg2.Id,
        Vendedor__c         = vSofia.Id,
        Estatus__c          = 'Devengada',
        Pct_Aplicado__c     = 12,
        Monto_Vendedor__c   = 9690,
        Monto_Ollin__c      = 1710
    ),
    // Comisión 5 — Fianza 4 Revertida (clawback por vencimiento)
    new Tech_Comision__c(
        Fianza__c           = fz4.Id,
        Vendedor__c         = vCarlos.Id,
        Estatus__c          = 'Revertida',
        Pct_Aplicado__c     = 12,
        Monto_Vendedor__c   = 1998,
        Monto_Ollin__c      = 299.70
    )
};
insert comisiones;

// ── 10. RESUMEN ────────────────────────────────────────────────────────────
System.debug('');
System.debug('========== SEED COMPLETADO ==========');
System.debug('Vendedores:       ' + vendedores.size());
System.debug('Cuentas:          ' + cuentas.size() + ' (2 Contratistas · 2 Beneficiarios · 3 Aseguradoras/Afianzadoras · 1 Institución)');
System.debug('Contratos:        ' + contratos.size());
System.debug('Fianzas:          ' + fianzas.size() + ' (2 Vigentes · 1 Emitida · 1 Vencida)');
System.debug('Seguros:          ' + seguros.size() + ' (Verde/Amarillo/Rojo/Cancelado)');
System.debug('Planes de Pago:   ' + planes.size());
System.debug('Recibos de Pago:  ' + recibos.size());
System.debug('Endosos:          ' + endosos.size());
System.debug('Comisiones:       ' + comisiones.size());
System.debug('');
System.debug('Contratista 1 (Montoya): ' + acMontoya.Id);
System.debug('Contratista 2 (Bajío):   ' + acBajio.Id);
System.debug('Contrato Montoya:        ' + ctMontoya.Id);
System.debug('Contrato Bajío:          ' + ctBajio.Id);
System.debug('Fianza Cumplimiento:     ' + fz1.Id);
System.debug('Seguro GMM:              ' + sg1.Id);
System.debug('=====================================');
