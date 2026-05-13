@IsTest
public class TechFianzaTriggerHandlerTest {

    @IsTest
    static void debePermitirCrearFianzaConDatosMinimos() {
        Account contratista = TechTestDataFactory.crearCuenta('Contratista Trigger');
        Account beneficiario = TechTestDataFactory.crearCuenta('Beneficiario Trigger');
        Account afianzadora = TechTestDataFactory.crearCuenta('Afianzadora Trigger');
        Product2 producto = TechTestDataFactory.crearProducto('Fianzas');
        Tech_Vendedor__c vendedor = TechTestDataFactory.crearVendedor('Fianzas');
        Opportunity opp = TechTestDataFactory.crearOportunidadAbierta(contratista, producto, vendedor, 'Fianzas');

        Test.startTest();
        Tech_Fianza__c fianza = TechTestDataFactory.crearFianza(contratista, beneficiario, afianzadora, vendedor, opp);
        Test.stopTest();

        Tech_Fianza__c creada = [
            SELECT Id, Oportunidad__c, Contratistas__c, Beneficiarios__c, Vendedor__c, Prima_neta__c
            FROM Tech_Fianza__c
            WHERE Id = :fianza.Id
        ];
        System.assertEquals(opp.Id, creada.Oportunidad__c, 'Debe conservar oportunidad relacionada.');
        System.assertEquals(contratista.Id, creada.Contratistas__c, 'Debe conservar contratista.');
        System.assertEquals(beneficiario.Id, creada.Beneficiarios__c, 'Debe conservar beneficiario.');
        System.assertEquals(vendedor.Id, creada.Vendedor__c, 'Debe conservar vendedor.');
    }
}