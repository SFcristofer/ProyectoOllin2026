@IsTest
public class TechProspectoConversionServiceTest {

    @IsTest
    static void debeConvertirProspectoYActualizarOportunidad() {
        Lead prospecto = TechTestDataFactory.crearLeadPersonaMoral();
        Account institucion = TechTestDataFactory.crearCuenta('Institucion Conversión');
        Product2 producto = TechTestDataFactory.crearProducto('Autos');
        Tech_Vendedor__c vendedor = TechTestDataFactory.crearVendedor('Autos');

        Opportunity opp = new Opportunity();
        opp.Name = 'Oportunidad Prospecto Test';
        opp.StageName = TechTestDataFactory.etapaAbierta();
        opp.CloseDate = Date.today().addDays(30);
        opp.Amount = 12000;
        opp.Prospecto__c = prospecto.Id;
        if (TechTestDataFactory.fieldExists('Opportunity', 'Vendedor_A__c')) opp.put('Vendedor_A__c', vendedor.Id);
        if (TechTestDataFactory.fieldExists('Opportunity', 'Producto__c')) opp.put('Producto__c', producto.Id);
        if (TechTestDataFactory.fieldExists('Opportunity', 'Institucion__c')) opp.put('Institucion__c', institucion.Id);
        if (TechTestDataFactory.fieldExists('Opportunity', 'Ramo__c')) opp.put('Ramo__c', TechTestDataFactory.pickValue('Opportunity', 'Ramo__c', new List<String>{ 'Autos', 'Auto' }));
        if (TechTestDataFactory.fieldExists('Opportunity', 'Metodo_Pago__c')) opp.put('Metodo_Pago__c', TechTestDataFactory.pickValue('Opportunity', 'Metodo_Pago__c', new List<String>{ 'Transferencia (SPEI)', 'Transferencia' }));
        if (TechTestDataFactory.fieldExists('Opportunity', 'Periodo_Pago__c')) opp.put('Periodo_Pago__c', TechTestDataFactory.pickValue('Opportunity', 'Periodo_Pago__c', new List<String>{ 'Mensual' }));
        if (TechTestDataFactory.fieldExists('Opportunity', 'Numero_Pagos__c')) opp.put('Numero_Pagos__c', 12);
        if (TechTestDataFactory.fieldExists('Opportunity', 'Fecha_Inicio_Vigencia__c')) opp.put('Fecha_Inicio_Vigencia__c', Date.today());
        if (TechTestDataFactory.fieldExists('Opportunity', 'Fecha_Fin_Vigencia__c')) opp.put('Fecha_Fin_Vigencia__c', Date.today().addMonths(12));
        if (TechTestDataFactory.fieldExists('Opportunity', 'Vigencia__c')) opp.put('Vigencia__c', 12);
        insert opp;

        Test.startTest();
        TechProspectoConversionService.convertirProspectosACuenta(new List<Id>{ prospecto.Id });
        Test.stopTest();

        Lead convertido = [SELECT Id, IsConverted, ConvertedAccountId FROM Lead WHERE Id = :prospecto.Id];
        System.assertEquals(true, convertido.IsConverted, 'El prospecto debe quedar convertido.');
        System.assertNotEquals(null, convertido.ConvertedAccountId, 'Debe existir cuenta convertida.');

        Opportunity oppActualizada = [SELECT Id, AccountId FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(convertido.ConvertedAccountId, oppActualizada.AccountId, 'La oportunidad debe heredar la cuenta convertida.');
    }
}