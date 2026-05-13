@IsTest
public class TechReciboPagoTriggerHandlerTest {

    @IsTest
    static void debeMarcarReciboComoCobrado() {
        Account cuenta = TechTestDataFactory.crearCuenta('Cliente Cobro');
        Product2 producto = TechTestDataFactory.crearProducto('Autos');
        Tech_Vendedor__c vendedor = TechTestDataFactory.crearVendedor('Autos');
        Opportunity opp = TechTestDataFactory.crearOportunidadAbierta(cuenta, producto, vendedor, 'Autos');
        Tech_Seguro__c seguro = TechTestDataFactory.crearSeguro(cuenta, producto, vendedor, opp, 'Autos', Date.today().addMonths(12));
        Tech_Plan_de_Pago__c plan = TechTestDataFactory.crearPlanSeguro(seguro, 12000, 12);
        Tech_Recibo_Pago__c recibo = TechTestDataFactory.crearRecibo(plan, seguro, 1, Date.today(), 1000);

        Test.startTest();
        recibo.Monto_cobrado__c = 1000;
        recibo.Fecha_pago__c = Date.today();
        recibo.Metodo_pago__c = TechTestDataFactory.pickValue('Tech_Recibo_Pago__c', 'Metodo_pago__c', new List<String>{ 'Efectivo' });
        update recibo;
        Test.stopTest();

        Tech_Recibo_Pago__c actualizado = [SELECT Estado__c FROM Tech_Recibo_Pago__c WHERE Id = :recibo.Id];
        System.assertEquals('Cobrado', actualizado.Estado__c, 'Debe marcarse como Cobrado.');
    }

    @IsTest
    static void debeMarcarReciboComoParcial() {
        Account cuenta = TechTestDataFactory.crearCuenta('Cliente Parcial');
        Product2 producto = TechTestDataFactory.crearProducto('Autos');
        Tech_Vendedor__c vendedor = TechTestDataFactory.crearVendedor('Autos');
        Opportunity opp = TechTestDataFactory.crearOportunidadAbierta(cuenta, producto, vendedor, 'Autos');
        Tech_Seguro__c seguro = TechTestDataFactory.crearSeguro(cuenta, producto, vendedor, opp, 'Autos', Date.today().addMonths(12));
        Tech_Plan_de_Pago__c plan = TechTestDataFactory.crearPlanSeguro(seguro, 12000, 12);
        Tech_Recibo_Pago__c recibo = TechTestDataFactory.crearRecibo(plan, seguro, 1, Date.today(), 1000);

        Test.startTest();
        recibo.Monto_cobrado__c = 500;
        recibo.Fecha_pago__c = Date.today();
        recibo.Metodo_pago__c = TechTestDataFactory.pickValue('Tech_Recibo_Pago__c', 'Metodo_pago__c', new List<String>{ 'Efectivo' });
        update recibo;
        Test.stopTest();

        Tech_Recibo_Pago__c actualizado = [SELECT Estado__c FROM Tech_Recibo_Pago__c WHERE Id = :recibo.Id];
        System.assertEquals('Parcial', actualizado.Estado__c, 'Debe marcarse como Parcial.');
    }

    @IsTest
    static void debeMarcarPlanEnMoraConReciboVencido() {
        Account cuenta = TechTestDataFactory.crearCuenta('Cliente Mora');
        Product2 producto = TechTestDataFactory.crearProducto('Autos');
        Tech_Vendedor__c vendedor = TechTestDataFactory.crearVendedor('Autos');
        Opportunity opp = TechTestDataFactory.crearOportunidadAbierta(cuenta, producto, vendedor, 'Autos');
        Tech_Seguro__c seguro = TechTestDataFactory.crearSeguro(cuenta, producto, vendedor, opp, 'Autos', Date.today().addMonths(12));
        Tech_Plan_de_Pago__c plan = TechTestDataFactory.crearPlanSeguro(seguro, 12000, 12);

        Test.startTest();
        Tech_Recibo_Pago__c recibo = TechTestDataFactory.crearRecibo(plan, seguro, 1, Date.today().addDays(-5), 1000);
        Test.stopTest();

        Tech_Recibo_Pago__c actualizado = [SELECT Estado__c FROM Tech_Recibo_Pago__c WHERE Id = :recibo.Id];
        System.assertEquals('Vencido', actualizado.Estado__c, 'Debe marcarse como Vencido.');

        Tech_Plan_de_Pago__c planActualizado = [SELECT Estado__c FROM Tech_Plan_de_Pago__c WHERE Id = :plan.Id];
        System.assertEquals('En mora', planActualizado.Estado__c, 'El plan debe quedar En mora.');
    }

    @IsTest
    static void debeBloquearMontoCobradoMayorAlProgramado() {
        Account cuenta = TechTestDataFactory.crearCuenta('Cliente Error Cobro');
        Product2 producto = TechTestDataFactory.crearProducto('Autos');
        Tech_Vendedor__c vendedor = TechTestDataFactory.crearVendedor('Autos');
        Opportunity opp = TechTestDataFactory.crearOportunidadAbierta(cuenta, producto, vendedor, 'Autos');
        Tech_Seguro__c seguro = TechTestDataFactory.crearSeguro(cuenta, producto, vendedor, opp, 'Autos', Date.today().addMonths(12));
        Tech_Plan_de_Pago__c plan = TechTestDataFactory.crearPlanSeguro(seguro, 12000, 12);
        Tech_Recibo_Pago__c recibo = TechTestDataFactory.crearRecibo(plan, seguro, 1, Date.today(), 1000);

        Test.startTest();
        try {
            recibo.Monto_cobrado__c = 1500;
            recibo.Fecha_pago__c = Date.today();
            update recibo;
            System.assert(false, 'Debe fallar si el monto cobrado es mayor al programado.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Monto Cobrado'), 'El error debe mencionar Monto Cobrado.');
        }
        Test.stopTest();
    }
}