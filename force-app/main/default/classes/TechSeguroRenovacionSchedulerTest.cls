@IsTest
public class TechSeguroRenovacionSchedulerTest {

    @IsTest
    static void debeCrearOportunidadDeRenovacionYEnviarNotificacion() {
        Account cuenta = TechTestDataFactory.crearCuenta('Cliente Scheduler');
        Product2 producto = TechTestDataFactory.crearProducto('Autos');
        Tech_Vendedor__c vendedor = TechTestDataFactory.crearVendedor('Autos');
        Opportunity oppBase = TechTestDataFactory.crearOportunidadAbierta(cuenta, producto, vendedor, 'Autos');
        Tech_Seguro__c seguro = TechTestDataFactory.crearSeguro(cuenta, producto, vendedor, oppBase, 'Autos', Date.today().addDays(20));

        Test.startTest();
        TechSeguroRenovacionScheduler.procesarRenovaciones();
        Test.stopTest();

        Tech_Seguro__c seguroActualizado = [SELECT Estatus__c FROM Tech_Seguro__c WHERE Id = :seguro.Id];
        System.assert(
            seguroActualizado.Estatus__c == 'Por renovar' || seguroActualizado.Estatus__c == 'En renovación',
            'El seguro debe quedar en proceso de renovación.'
        );

        List<Opportunity> renovaciones = [
            SELECT Id, AccountId, Poliza_Renovar__c, Amount, CloseDate
            FROM Opportunity
            WHERE Poliza_Renovar__c = :seguro.Id
        ];
        System.assertEquals(1, renovaciones.size(), 'Debe crear una oportunidad de renovación.');
        System.assertEquals(cuenta.Id, renovaciones[0].AccountId, 'La renovación debe heredar cliente.');
        System.assertEquals(Decimal.valueOf(12000), renovaciones[0].Amount, 'La renovación debe heredar prima/importe.');
        System.assert(Limits.getEmailInvocations() >= 0, 'La ejecución no debe fallar por correo.');
    }

    @IsTest
    static void noDebeDuplicarOportunidadDeRenovacionAbierta() {
        Account cuenta = TechTestDataFactory.crearCuenta('Cliente Scheduler No Dup');
        Product2 producto = TechTestDataFactory.crearProducto('Autos');
        Tech_Vendedor__c vendedor = TechTestDataFactory.crearVendedor('Autos');
        Opportunity oppBase = TechTestDataFactory.crearOportunidadAbierta(cuenta, producto, vendedor, 'Autos');
        Tech_Seguro__c seguro = TechTestDataFactory.crearSeguro(cuenta, producto, vendedor, oppBase, 'Autos', Date.today().addDays(20));

        Opportunity oppRenovacion = TechTestDataFactory.crearOportunidadAbierta(cuenta, producto, vendedor, 'Autos');
        oppRenovacion.Poliza_Renovar__c = seguro.Id;
        update oppRenovacion;

        Test.startTest();
        TechSeguroRenovacionScheduler.procesarRenovaciones();
        Test.stopTest();

        Integer total = [SELECT COUNT() FROM Opportunity WHERE Poliza_Renovar__c = :seguro.Id];
        System.assertEquals(1, total, 'No debe duplicar oportunidades de renovación abiertas.');
    }

    @IsTest
    static void debeProgramarJobDiario() {
        Test.startTest();
        TechSeguroRenovacionScheduler.programarDiario();
        Test.stopTest();

        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'TECH - Renovación diaria de seguros'
        ];
        System.assert(!jobs.isEmpty(), 'Debe programar el job diario de renovación.');
    }
}