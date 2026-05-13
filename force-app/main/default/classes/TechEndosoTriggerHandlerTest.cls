@IsTest
public class TechEndosoTriggerHandlerTest {

    @IsTest
    static void endosoDebeAjustarSoloRecibosFuturosNoCobrados() {
        Account cuenta = TechTestDataFactory.crearCuenta('Cliente Endoso');
        Product2 producto = TechTestDataFactory.crearProducto('Autos');
        Tech_Vendedor__c vendedor = TechTestDataFactory.crearVendedor('Autos');
        Opportunity opp = TechTestDataFactory.crearOportunidadAbierta(cuenta, producto, vendedor, 'Autos');
        Tech_Seguro__c seguro = TechTestDataFactory.crearSeguro(cuenta, producto, vendedor, opp, 'Autos', Date.today().addMonths(12));
        Tech_Plan_de_Pago__c plan = TechTestDataFactory.crearPlanSeguro(seguro, 12000, 4);

        Tech_Recibo_Pago__c r1 = TechTestDataFactory.crearRecibo(plan, seguro, 1, Date.today(), 3000);
        r1.Monto_cobrado__c = 3000;
        r1.Fecha_pago__c = Date.today();
        r1.Metodo_pago__c = TechTestDataFactory.pickValue('Tech_Recibo_Pago__c', 'Metodo_pago__c', new List<String>{ 'Efectivo' });
        update r1;

        TechTestDataFactory.crearRecibo(plan, seguro, 2, Date.today().addDays(30), 3000);
        TechTestDataFactory.crearRecibo(plan, seguro, 3, Date.today().addDays(60), 3000);
        TechTestDataFactory.crearRecibo(plan, seguro, 4, Date.today().addDays(90), 3000);

        Test.startTest();
        Tech_Endoso__c endoso = new Tech_Endoso__c();
//        endoso.Name = 'Endoso Test Prima';
        endoso.Seguro__c = seguro.Id;
        endoso.Plan_de_pago__c = plan.Id;
        endoso.Afecta_prima__c = true;
        endoso.Nueva_prima__c = 15000;
        endoso.Fecha_efectiva__c = Date.today().addDays(30);
        endoso.Estado__c = TechTestDataFactory.pickValue('Tech_Endoso__c', 'Estado__c', new List<String>{ 'Borrador', 'Aplicado' });
        TechTestDataFactory.setPicklistIfExists(endoso, 'Tipo_endoso__c', new List<String>{ 'Cambio datos', 'Aumento prima', 'Otro' });
        insert endoso;
        Test.stopTest();

        Tech_Seguro__c seguroActualizado = [SELECT Prima_neta__c FROM Tech_Seguro__c WHERE Id = :seguro.Id];
        System.assertEquals(Decimal.valueOf(15000), seguroActualizado.Prima_neta__c, 'El seguro debe actualizar prima neta.');

        Map<Decimal, Tech_Recibo_Pago__c> recibos = new Map<Decimal, Tech_Recibo_Pago__c>();
        for (Tech_Recibo_Pago__c r : [
            SELECT Numero__c, Monto_programado__c, Estado__c
            FROM Tech_Recibo_Pago__c
            WHERE Plan_de_Pagos__c = :plan.Id
        ]) {
            recibos.put(r.Numero__c, r);
        }

        System.assertEquals(Decimal.valueOf(3000), recibos.get(1).Monto_programado__c, 'Recibo cobrado no debe cambiar.');
        System.assertEquals(Decimal.valueOf(4000), recibos.get(2).Monto_programado__c, 'Recibo futuro 2 debe ajustarse.');
        System.assertEquals(Decimal.valueOf(4000), recibos.get(3).Monto_programado__c, 'Recibo futuro 3 debe ajustarse.');
        System.assertEquals(Decimal.valueOf(4000), recibos.get(4).Monto_programado__c, 'Recibo futuro 4 debe ajustarse.');
    }

    @IsTest
    static void debeBloquearEndosoSinSeguroNiFianza() {
        Test.startTest();
        try {
            Tech_Endoso__c endoso = new Tech_Endoso__c();
//            endoso.Name = 'Endoso Sin Relación';
            endoso.Afecta_prima__c = true;
            endoso.Nueva_prima__c = 15000;
            endoso.Fecha_efectiva__c = Date.today();
            endoso.Estado__c = TechTestDataFactory.pickValue('Tech_Endoso__c', 'Estado__c', new List<String>{ 'Borrador', 'Aplicado' });
            TechTestDataFactory.setPicklistIfExists(endoso, 'Tipo_endoso__c', new List<String>{ 'Cambio datos', 'Aumento prima', 'Otro' });
            insert endoso;
            System.assert(false, 'Debe fallar si el endoso no tiene Seguro ni Fianza.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Seguro') || e.getMessage().contains('Fianza'), 'Debe indicar Seguro o Fianza.');
        }
        Test.stopTest();
    }
}