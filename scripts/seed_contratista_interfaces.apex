// ============================================================
// SEED: Dashboard Interfaces – Ajelet García
// sf apex run --file scripts/seed_contratista_interfaces.apex --target-org Ollin
// ============================================================

final Id AJELET_ID  = 'a0Fct0000055LtlEAE';
final Id CONTRATO_1 = 'a0Cct00003FLVWTEA5'; // 123 prueba
final Id CONTRATO_2 = 'a0Cct00003PNpMrEAL'; // 007985
final Id VBCVCV_ID  = 'a03ct00000goGCfAAM'; // Fianza VBCVCV

// 1. Vincular VBCVCV a Ajelet García
update new Fianza__c(
    Id                      = VBCVCV_ID,
    ContratistaFianza__c    = AJELET_ID,
    Estatus__c              = 'Vigente',
    Fecha_de_Emisi_n__c     = Date.today().addMonths(-6),
    Fecha_de_Vencimiento__c = Date.today().addMonths(6)
);
System.debug('1. VBCVCV vinculada a Ajelet Garcia');

// 2. Fianza Vencida
Fianza__c fv = new Fianza__c(
    Name                    = 'FZ-TEST-VENCIDA',
    ContratistaFianza__c    = AJELET_ID,
    Estatus__c              = 'Vencida',
    Monto_Afianzado__c      = 150000,
    No_Contrato__c          = CONTRATO_2,
    Fecha_de_Emisi_n__c     = Date.today().addMonths(-18),
    Fecha_de_Vencimiento__c = Date.today().addDays(-45)
);
insert fv;
System.debug('2. Fianza Vencida creada: ' + fv.Id);

// 3. Fianza Cancelada
Fianza__c fc = new Fianza__c(
    Name                    = 'FZ-TEST-CANCELADA',
    ContratistaFianza__c    = AJELET_ID,
    Estatus__c              = 'Cancelada',
    Monto_Afianzado__c      = 75000,
    No_Contrato__c          = CONTRATO_1,
    Fecha_de_Emisi_n__c     = Date.today().addMonths(-24),
    Fecha_de_Vencimiento__c = Date.today().addDays(-90)
);
insert fc;
System.debug('3. Fianza Cancelada creada: ' + fc.Id);

// 4. Tech_Relacion__c: fianzas → contratos
insert new List<Tech_Relacion__c>{
    new Tech_Relacion__c(Tipo__c='Contrato', Fianza__c=VBCVCV_ID, Contrato__c=CONTRATO_1),
    new Tech_Relacion__c(Tipo__c='Contrato', Fianza__c=fv.Id,     Contrato__c=CONTRATO_2),
    new Tech_Relacion__c(Tipo__c='Contrato', Fianza__c=fc.Id,     Contrato__c=CONTRATO_1)
};
System.debug('4. Relaciones Fianza-Contrato creadas');

// 5. Resumen
Integer cnt = [SELECT COUNT() FROM Fianza__c WHERE ContratistaFianza__c = :AJELET_ID];
Decimal monto = (Decimal)[SELECT SUM(Monto_Afianzado__c) t FROM Fianza__c WHERE ContratistaFianza__c = :AJELET_ID][0].get('t');
System.debug('=== RESULTADO ESPERADO ===');
System.debug('Fianzas totales: '  + cnt);
System.debug('Monto afianzado: $' + monto.format());
System.debug('Vencidas/Canceladas: 2');
System.debug('Contratos: 2 (123 prueba, 007985)');
