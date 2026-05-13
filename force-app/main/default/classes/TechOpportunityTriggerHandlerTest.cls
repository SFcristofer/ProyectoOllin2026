@IsTest
public class TechOpportunityTriggerHandlerTest {

    @IsTest
    static void oportunidadGanadaDebeCrearSeguroPlanYRecibos() {
        Account cuenta = TechTestDataFactory.crearCuenta('Cliente Seguro');
        Product2 producto = TechTestDataFactory.crearProducto('Autos');
        Tech_Vendedor__c vendedor = TechTestDataFactory.crearVendedor('Autos');
        Opportunity opp = TechTestDataFactory.crearOportunidadAbierta(cuenta, producto, vendedor, 'Autos');

        Test.startTest();
        opp.StageName = TechTestDataFactory.etapaGanada();
        update opp;
        Test.stopTest();

        List<Tech_Seguro__c> seguros = [
            SELECT Id, Cliente__c, Oportunidad__c, Vendedor__c, Prima_neta__c, Poliza_renovada__c
            FROM Tech_Seguro__c
            WHERE Oportunidad__c = :opp.Id
        ];
        System.assertEquals(1, seguros.size(), 'Debe crear un seguro para oportunidad ganada de seguro.');
        System.assertEquals(cuenta.Id, seguros[0].Cliente__c, 'El seguro debe heredar la cuenta.');
        System.assertEquals(vendedor.Id, seguros[0].Vendedor__c, 'El seguro debe heredar Vendedor_A__c.');
        System.assertEquals(Decimal.valueOf(12000), seguros[0].Prima_neta__c, 'El seguro debe heredar Amount como prima neta.');

        List<Tech_Plan_de_Pago__c> planes = [
            SELECT Id, Seguro__c, Num_recibos__c, Monto_total__c
            FROM Tech_Plan_de_Pago__c
            WHERE Seguro__c = :seguros[0].Id
        ];
        System.assertEquals(1, planes.size(), 'Debe crear plan de pago ligado a Seguro__c.');

        Integer recibos = [
            SELECT COUNT()
            FROM Tech_Recibo_Pago__c
            WHERE Plan_de_Pagos__c = :planes[0].Id
        ];
        System.assertEquals(12, recibos, 'Debe crear 12 recibos.');
    }

    @IsTest
    static void oportunidadGanadaDeFianzaDebeCrearFianzaPlanYRecibos() {
        Account cuenta = TechTestDataFactory.crearCuenta('Contratista');
        Account beneficiario = TechTestDataFactory.crearCuenta('Beneficiario');
        Product2 producto = TechTestDataFactory.crearProducto('Fianzas');
        Tech_Vendedor__c vendedor = TechTestDataFactory.crearVendedor('Fianzas');
        Opportunity opp = TechTestDataFactory.crearOportunidadAbierta(cuenta, producto, vendedor, 'Fianzas');

        if (TechTestDataFactory.fieldExists('Opportunity', 'Contratista__c')) opp.put('Contratista__c', cuenta.Id);
        if (TechTestDataFactory.fieldExists('Opportunity', 'Beneficiario__c')) opp.put('Beneficiario__c', beneficiario.Id);
        if (TechTestDataFactory.fieldExists('Opportunity', 'Institucion__c')) opp.put('Institucion__c', beneficiario.Id);
        update opp;

        Test.startTest();
        opp.StageName = TechTestDataFactory.etapaGanada();
        update opp;
        Test.stopTest();

        List<Tech_Fianza__c> fianzas = [
            SELECT Id, Oportunidad__c, Contratistas__c, Beneficiarios__c, Vendedor__c, Prima_neta__c
            FROM Tech_Fianza__c
            WHERE Oportunidad__c = :opp.Id
        ];
        System.assertEquals(1, fianzas.size(), 'Debe crear una fianza para oportunidad ganada de fianzas.');
        System.assertEquals(cuenta.Id, fianzas[0].Contratistas__c, 'La fianza debe heredar contratista.');
        System.assertEquals(vendedor.Id, fianzas[0].Vendedor__c, 'La fianza debe heredar vendedor.');

        List<Tech_Plan_de_Pago__c> planes = [
            SELECT Id, Fianzas__c, Num_recibos__c, Monto_total__c
            FROM Tech_Plan_de_Pago__c
            WHERE Fianzas__c = :fianzas[0].Id
        ];
        System.assertEquals(1, planes.size(), 'Debe crear plan ligado a Fianzas__c.');

        Integer recibos = [SELECT COUNT() FROM Tech_Recibo_Pago__c WHERE Plan_de_Pagos__c = :planes[0].Id];
        System.assertEquals(12, recibos, 'Debe crear recibos de fianza.');
    }

    @IsTest
    static void renovacionGanadaDebeCrearNuevaPolizaConReferenciaOrigen() {
        Account cuenta = TechTestDataFactory.crearCuenta('Cliente Renovacion');
        Product2 producto = TechTestDataFactory.crearProducto('Autos');
        Tech_Vendedor__c vendedor = TechTestDataFactory.crearVendedor('Autos');
        Opportunity oppBase = TechTestDataFactory.crearOportunidadAbierta(cuenta, producto, vendedor, 'Autos');
        Tech_Seguro__c seguroOrigen = TechTestDataFactory.crearSeguro(cuenta, producto, vendedor, oppBase, 'Autos', Date.today().addDays(20));

        Opportunity oppRenovacion = TechTestDataFactory.crearOportunidadAbierta(cuenta, producto, vendedor, 'Autos');
        oppRenovacion.Poliza_Renovar__c = seguroOrigen.Id;
        update oppRenovacion;

        Test.startTest();
        oppRenovacion.StageName = TechTestDataFactory.etapaGanada();
        update oppRenovacion;
        Test.stopTest();

        List<Tech_Seguro__c> nuevosSeguros = [
            SELECT Id, Poliza_renovada__c, Oportunidad__c
            FROM Tech_Seguro__c
            WHERE Oportunidad__c = :oppRenovacion.Id
        ];
        System.assertEquals(1, nuevosSeguros.size(), 'Debe crear la nueva póliza de renovación.');
        System.assertEquals(seguroOrigen.Id, nuevosSeguros[0].Poliza_renovada__c, 'Debe conservar la referencia a la póliza origen.');
    }

    @IsTest
    static void renovacionPerdidaDebeActualizarPolizaOrigen() {
        Account cuenta = TechTestDataFactory.crearCuenta('Cliente Renovacion Perdida');
        Product2 producto = TechTestDataFactory.crearProducto('Autos');
        Tech_Vendedor__c vendedor = TechTestDataFactory.crearVendedor('Autos');
        Opportunity oppBase = TechTestDataFactory.crearOportunidadAbierta(cuenta, producto, vendedor, 'Autos');
        Tech_Seguro__c seguroOrigen = TechTestDataFactory.crearSeguro(cuenta, producto, vendedor, oppBase, 'Autos', Date.today().addDays(10));

        Opportunity oppRenovacion = TechTestDataFactory.crearOportunidadAbierta(cuenta, producto, vendedor, 'Autos');
        oppRenovacion.Poliza_Renovar__c = seguroOrigen.Id;
        update oppRenovacion;

        Test.startTest();
        oppRenovacion = TechTestDataFactory.prepararCierrePerdido(oppRenovacion);
        update oppRenovacion;
        Test.stopTest();

        Tech_Seguro__c actualizado = [SELECT Id, Estatus__c FROM Tech_Seguro__c WHERE Id = :seguroOrigen.Id];
        System.assert(
            actualizado.Estatus__c == 'No Renovada' || actualizado.Estatus__c == 'Vencida',
            'La póliza origen debe cambiar a No Renovada o Vencida, según el valor oficial del picklist.'
        );
    }

    @IsTest
    static void oportunidadGanadaNoDebeDuplicarSeguro() {
        Account cuenta = TechTestDataFactory.crearCuenta('Cliente No Duplicado');
        Product2 producto = TechTestDataFactory.crearProducto('Autos');
        Tech_Vendedor__c vendedor = TechTestDataFactory.crearVendedor('Autos');
        Opportunity opp = TechTestDataFactory.crearOportunidadAbierta(cuenta, producto, vendedor, 'Autos');
        TechTestDataFactory.crearSeguro(cuenta, producto, vendedor, opp, 'Autos', Date.today().addMonths(12));

        Test.startTest();
        opp.StageName = TechTestDataFactory.etapaGanada();
        update opp;
        Test.stopTest();

        Integer total = [SELECT COUNT() FROM Tech_Seguro__c WHERE Oportunidad__c = :opp.Id];
        System.assertEquals(1, total, 'No debe duplicar seguro si ya existe uno ligado a la oportunidad.');
    }
}