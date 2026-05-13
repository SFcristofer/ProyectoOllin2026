@IsTest
public class TechPlanPagoServiceTest {

    @IsTest
    static void debeGenerarPlanYRecibosDesdeSeguro() {
        Account cuenta = TechTestDataFactory.crearCuenta('Cliente Plan Seguro');
        Product2 producto = TechTestDataFactory.crearProducto('Autos');
        Tech_Vendedor__c vendedor = TechTestDataFactory.crearVendedor('Autos');
        Opportunity opp = TechTestDataFactory.crearOportunidadAbierta(cuenta, producto, vendedor, 'Autos');
        Tech_Seguro__c seguro = TechTestDataFactory.crearSeguro(cuenta, producto, vendedor, opp, 'Autos', Date.today().addMonths(12));

        Test.startTest();
        TechPlanPagoService.generarPlanesYRecibosPorSeguroIds(new Set<Id>{ seguro.Id });
        Test.stopTest();

        List<Tech_Plan_de_Pago__c> planes = [
            SELECT Id, Seguro__c, Num_recibos__c, Monto_total__c, Fecha_inicio__c
            FROM Tech_Plan_de_Pago__c
            WHERE Seguro__c = :seguro.Id
        ];
        System.assertEquals(1, planes.size(), 'Debe generar un plan de seguro.');
        System.assertEquals(Decimal.valueOf(12), planes[0].Num_recibos__c, 'Debe heredar número de pagos.');
        System.assertEquals(Decimal.valueOf(12000), planes[0].Monto_total__c, 'Debe heredar Amount.');

        List<Tech_Recibo_Pago__c> recibos = [
            SELECT Id, Numero__c, Fecha_programada__c, Monto_programado__c, Estado__c
            FROM Tech_Recibo_Pago__c
            WHERE Plan_de_Pagos__c = :planes[0].Id
            ORDER BY Numero__c ASC
        ];
        System.assertEquals(12, recibos.size(), 'Debe generar 12 recibos.');
        System.assertEquals(Date.today(), recibos[0].Fecha_programada__c, 'El primer recibo debe tomar fecha inicio.');
        System.assertEquals(Date.today().addDays(30), recibos[1].Fecha_programada__c, 'El segundo recibo debe programarse 30 días después.');
        System.assertEquals(Decimal.valueOf(1000), recibos[0].Monto_programado__c, 'Debe dividir monto entre número de pagos.');
    }

    @IsTest
    static void debeGenerarPlanYRecibosDesdeFianza() {
        Account contratista = TechTestDataFactory.crearCuenta('Contratista Plan');
        Account beneficiario = TechTestDataFactory.crearCuenta('Beneficiario Plan');
        Account afianzadora = TechTestDataFactory.crearCuenta('Afianzadora Plan');
        Product2 producto = TechTestDataFactory.crearProducto('Fianzas');
        Tech_Vendedor__c vendedor = TechTestDataFactory.crearVendedor('Fianzas');
        Opportunity opp = TechTestDataFactory.crearOportunidadAbierta(contratista, producto, vendedor, 'Fianzas');
        Tech_Fianza__c fianza = TechTestDataFactory.crearFianza(contratista, beneficiario, afianzadora, vendedor, opp);

        Test.startTest();
        TechPlanPagoService.generarPlanesYRecibosPorFianzaIds(new Set<Id>{ fianza.Id });
        Test.stopTest();

        List<Tech_Plan_de_Pago__c> planes = [
            SELECT Id, Fianzas__c, Num_recibos__c, Monto_total__c
            FROM Tech_Plan_de_Pago__c
            WHERE Fianzas__c = :fianza.Id
        ];
        System.assertEquals(1, planes.size(), 'Debe generar un plan de fianza.');

        Integer recibos = [SELECT COUNT() FROM Tech_Recibo_Pago__c WHERE Plan_de_Pagos__c = :planes[0].Id];
        System.assertEquals(12, recibos, 'Debe generar recibos de fianza.');
    }

    @IsTest
    static void noDebeDuplicarRecibosSiYaExisten() {
        Account cuenta = TechTestDataFactory.crearCuenta('Cliente Duplicados');
        Product2 producto = TechTestDataFactory.crearProducto('Autos');
        Tech_Vendedor__c vendedor = TechTestDataFactory.crearVendedor('Autos');
        Opportunity opp = TechTestDataFactory.crearOportunidadAbierta(cuenta, producto, vendedor, 'Autos');
        Tech_Seguro__c seguro = TechTestDataFactory.crearSeguro(cuenta, producto, vendedor, opp, 'Autos', Date.today().addMonths(12));
        Tech_Plan_de_Pago__c plan = TechTestDataFactory.crearPlanSeguro(seguro, 12000, 12);
        TechTestDataFactory.crearRecibo(plan, seguro, 1, Date.today(), 1000);

        Test.startTest();
        TechPlanPagoService.generarPlanesYRecibosPorSeguroIds(new Set<Id>{ seguro.Id });
        Test.stopTest();

        Integer total = [SELECT COUNT() FROM Tech_Recibo_Pago__c WHERE Plan_de_Pagos__c = :plan.Id];
        System.assertEquals(1, total, 'No debe duplicar recibos si el plan ya tiene recibos.');
    }
}