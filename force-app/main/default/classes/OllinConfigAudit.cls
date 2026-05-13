/*
    Clase: OllinConfigAudit
    Objetivo:
    Validar si la configuración definida en el documento de diseño Ollin
    fue implementada en Salesforce.

    Uso:
    1. Crear esta clase en Setup > Apex Classes.
    2. Ejecutar desde Developer Console > Execute Anonymous:
       OllinConfigAudit.run();

    Resultado:
    Imprime en Debug Log una matriz de evaluación:
    OK / FAIL / WARN / INFO.

    Nota:
    - Valida objetos, campos, tipos de dato, relaciones, record types,
      picklists, Apex classes, permission sets y objetos retirados.
    - Flows y Validation Rules se validan de forma parcial porque algunas
      configuraciones requieren Tooling API / Metadata API.
*/
public with sharing class OllinConfigAudit {

    private static final Boolean CREATE_CSV_FILE = false;

    private static List<CheckResult> results = new List<CheckResult>();

    private class ObjectSpec {
        String apiName;
        List<String> recordTypes = new List<String>();
        Map<String, FieldSpec> fields = new Map<String, FieldSpec>();

        ObjectSpec(String apiName) {
            this.apiName = apiName;
        }
    }

    private class FieldSpec {
        String apiName;
        String expectedType;
        String referenceTo;
        Boolean externalId = false;

        FieldSpec(String apiName, String expectedType, String referenceTo) {
            this.apiName = apiName;
            this.expectedType = expectedType;
            this.referenceTo = referenceTo;
        }
    }

    private class CheckResult {
        String sectionName;
        String itemName;
        String expectedValue;
        String actualValue;
        String status;
        String notes;

        CheckResult(
            String sectionName,
            String itemName,
            String expectedValue,
            String actualValue,
            String status,
            String notes
        ) {
            this.sectionName = sectionName;
            this.itemName = itemName;
            this.expectedValue = expectedValue;
            this.actualValue = actualValue;
            this.status = status;
            this.notes = notes;
        }
    }

    public static void run() {
        results.clear();

        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

        List<ObjectSpec> objectSpecs = buildObjectSpecs();

        for (ObjectSpec spec : objectSpecs) {
            validateObjectSpec(spec, globalDescribe);
        }

        validateRetiredObjects(globalDescribe);
        validatePicklistValues(globalDescribe);
        validateExpectedApexClasses();
        validateExpectedPermissionSets();
        validateExpectedFlows();
        validateValidationRulesAvailability();
        validateManualReviewItems();

        printResults();
    }

    private static List<ObjectSpec> buildObjectSpecs() {
        List<ObjectSpec> specs = new List<ObjectSpec>();

        /*
            OBJETOS ESTÁNDAR
        */

        ObjectSpec accountSpec = obj('Account');
        accountSpec.recordTypes.addAll(new List<String>{
            'Persona_Fisica',
            'Persona_Moral',
            'Beneficiario_Fianza',
            'Contratista',
            'Institucion'
        });
        f(accountSpec, 'Name', 'String', null);
        f(accountSpec, 'Phone', 'Phone', null);
        f(accountSpec, 'Website', 'Url', null);
        f(accountSpec, 'BillingStreet', 'String', null);
        f(accountSpec, 'BillingCity', 'String', null);
        f(accountSpec, 'BillingState', 'String', null);
        f(accountSpec, 'BillingPostalCode', 'String', null);
        f(accountSpec, 'BillingCountry', 'String', null);
        f(accountSpec, 'RFC__c', 'String', null);
        f(accountSpec, 'Type', 'Picklist', null);
        f(accountSpec, 'Segmento__c', 'Picklist', null);
        f(accountSpec, 'ID_Externo__c', 'String', null).externalId = true;
        specs.add(accountSpec);

        ObjectSpec contactSpec = obj('Contact');
        f(contactSpec, 'AccountId', 'Reference', 'Account');
        f(contactSpec, 'FirstName', 'String', null);
        f(contactSpec, 'LastName', 'String', null);
        f(contactSpec, 'Email', 'Email', null);
        f(contactSpec, 'Phone', 'Phone', null);
        f(contactSpec, 'MobilePhone', 'Phone', null);
        f(contactSpec, 'Title', 'String', null);
        f(contactSpec, 'Area__c', 'Picklist', null);
        f(contactSpec, 'Contacto_Principal__c', 'Boolean', null);
        specs.add(contactSpec);

        ObjectSpec leadSpec = obj('Lead');
        leadSpec.recordTypes.addAll(new List<String>{
            'Seguros_de_auto',
            'Gastos_medicos',
            'Vida',
            'Danos',
            'Fianzas',
            'Membresia_Ollin_Salud',
            'Otros'
        });
        f(leadSpec, 'FirstName', 'String', null);
        f(leadSpec, 'LastName', 'String', null);
        f(leadSpec, 'Company', 'String', null);
        f(leadSpec, 'Email', 'Email', null);
        f(leadSpec, 'Phone', 'Phone', null);
        f(leadSpec, 'MobilePhone', 'Phone', null);
        f(leadSpec, 'Status', 'Picklist', null);
        f(leadSpec, 'PostalCode', 'String', null);
        f(leadSpec, 'Tipo_de_seguro__c', 'Picklist', null);
        f(leadSpec, 'Clasificacion_Cliente__c', 'Picklist', null);
        f(leadSpec, 'Score_Precalificacion__c', 'Integer', null);
        f(leadSpec, 'Datos_Minimos_Completos__c', 'Boolean', null);
        f(leadSpec, 'Estado_Precalificacion__c', 'Picklist', null);
        f(leadSpec, 'UTM_Source__c', 'String', null);
        f(leadSpec, 'UTM_Medium__c', 'String', null);
        f(leadSpec, 'UTM_Campaign__c', 'String', null);
        f(leadSpec, 'UTM_Content__c', 'String', null);
        f(leadSpec, 'UTM_Term__c', 'String', null);
        f(leadSpec, 'Meta_Ad_Id__c', 'String', null);
        f(leadSpec, 'Lead_Id_Externo__c', 'String', null).externalId = true;
        f(leadSpec, 'Marca__c', 'String', null);
        f(leadSpec, 'Modelo__c', 'String', null);
        f(leadSpec, 'Anio__c', 'Integer', null);
        f(leadSpec, 'Version__c', 'String', null);
        f(leadSpec, 'Uso_Vehiculo__c', 'Picklist', null);
        f(leadSpec, 'Fecha_de_nacimiento__c', 'Date', null);
        f(leadSpec, 'Sexo__c', 'Picklist', null);
        f(leadSpec, 'HospitalesReferencias__c', 'TextArea', null);
        f(leadSpec, 'Objetivo_Plan__c', 'Picklist', null);
        f(leadSpec, 'Habito_Fumar__c', 'Boolean', null);
        f(leadSpec, 'Aportacion_Estimada__c', 'Currency', null);
        f(leadSpec, 'Monto_Contrato__c', 'Currency', null);
        f(leadSpec, 'Porcentaje_Afianzar__c', 'Percent', null);
        f(leadSpec, 'Tipo_Fianza__c', 'String', null);
        specs.add(leadSpec);

        ObjectSpec oppSpec = obj('Opportunity');
        oppSpec.recordTypes.addAll(new List<String>{
            'Digital',
            'Consultivo',
            'Promotoria'
        });
        f(oppSpec, 'AccountId', 'Reference', 'Account');
        f(oppSpec, 'Name', 'String', null);
        f(oppSpec, 'StageName', 'Picklist', null);
        f(oppSpec, 'CloseDate', 'Date', null);
        f(oppSpec, 'Amount', 'Currency', null);
        f(oppSpec, 'Producto__c', 'Reference', 'Product2');
        f(oppSpec, 'Vendedor__c', 'Reference', 'Vendedor__c');
        f(oppSpec, 'Ramo__c', 'Picklist', null);
        f(oppSpec, 'Subramo__c', 'Picklist', null);
        f(oppSpec, 'Tipo_Originador__c', 'Picklist', null);
        f(oppSpec, 'Canal_Origen__c', 'Picklist', null);
        f(oppSpec, 'Cotizacion_Externa_Id__c', 'String', null).externalId = true;
        f(oppSpec, 'Checkout_Id__c', 'String', null).externalId = true;
        f(oppSpec, 'Payment_Id__c', 'String', null).externalId = true;
        f(oppSpec, 'Policy_Id__c', 'String', null).externalId = true;
        f(oppSpec, 'Policy_Number__c', 'String', null);
        f(oppSpec, 'SLA_Asignacion__c', 'DateTime', null);
        f(oppSpec, 'SLA_Primera_Respuesta__c', 'DateTime', null);
        f(oppSpec, 'Estatus_SLA__c', 'Picklist', null);
        f(oppSpec, 'Motivo_Perdida__c', 'Picklist', null);
        f(oppSpec, 'Puede_Reactivarse__c', 'Boolean', null);
        specs.add(oppSpec);

        ObjectSpec productSpec = obj('Product2');
        productSpec.recordTypes.addAll(new List<String>{
            'Seguro',
            'Fianza',
            'Membresia',
            'Servicio'
        });
        f(productSpec, 'Name', 'String', null);
        f(productSpec, 'ProductCode', 'String', null);
        f(productSpec, 'Family', 'Picklist', null);
        f(productSpec, 'IsActive', 'Boolean', null);
        f(productSpec, 'Ramo__c', 'Picklist', null);
        f(productSpec, 'Subramo__c', 'Picklist', null);
        f(productSpec, 'Requiere_Datos_Auto__c', 'Boolean', null);
        f(productSpec, 'Requiere_Datos_Vida__c', 'Boolean', null);
        f(productSpec, 'Requiere_Datos_Fianza__c', 'Boolean', null);
        specs.add(productSpec);

        ObjectSpec pricebookSpec = obj('Pricebook2');
        f(pricebookSpec, 'Name', 'String', null);
        f(pricebookSpec, 'IsActive', 'Boolean', null);
        specs.add(pricebookSpec);

        ObjectSpec pricebookEntrySpec = obj('PricebookEntry');
        f(pricebookEntrySpec, 'Pricebook2Id', 'Reference', 'Pricebook2');
        f(pricebookEntrySpec, 'Product2Id', 'Reference', 'Product2');
        f(pricebookEntrySpec, 'UnitPrice', 'Currency', null);
        f(pricebookEntrySpec, 'IsActive', 'Boolean', null);
        specs.add(pricebookEntrySpec);

        ObjectSpec contractSpec = obj('Contract');
        contractSpec.recordTypes.addAll(new List<String>{
            'Contrato_Fianza'
        });
        f(contractSpec, 'AccountId', 'Reference', 'Account');
        f(contractSpec, 'ContractNumber', 'String', null);
        f(contractSpec, 'StartDate', 'Date', null);
        f(contractSpec, 'EndDate', 'Date', null);
        f(contractSpec, 'Status', 'Picklist', null);
        f(contractSpec, 'Valor_Contrato__c', 'Currency', null);
        f(contractSpec, 'Valor_Contrato_Vigente__c', 'Currency', null);
        f(contractSpec, 'Fin_Contrato_Vigente__c', 'Date', null);
        f(contractSpec, 'Beneficiario__c', 'Reference', 'Account');
        f(contractSpec, 'Contratista__c', 'Reference', 'Account');
        f(contractSpec, 'Institucion__c', 'Reference', 'Account');
        f(contractSpec, 'Vendedor__c', 'Reference', 'Vendedor__c');
        f(contractSpec, 'Proyecto__c', 'String', null);
        f(contractSpec, 'Suma_Fianzas__c', 'Currency', null);
        f(contractSpec, 'Exposicion_Porcentaje__c', 'Percent', null);
        specs.add(contractSpec);

        ObjectSpec campaignSpec = obj('Campaign');
        f(campaignSpec, 'Name', 'String', null);
        f(campaignSpec, 'Type', 'Picklist', null);
        f(campaignSpec, 'Status', 'Picklist', null);
        f(campaignSpec, 'StartDate', 'Date', null);
        f(campaignSpec, 'EndDate', 'Date', null);
        specs.add(campaignSpec);

        ObjectSpec taskSpec = obj('Task');
        f(taskSpec, 'Subject', 'String', null);
        f(taskSpec, 'Status', 'Picklist', null);
        f(taskSpec, 'Priority', 'Picklist', null);
        f(taskSpec, 'WhoId', 'Reference', null);
        f(taskSpec, 'WhatId', 'Reference', null);
        f(taskSpec, 'ActivityDate', 'Date', null);
        specs.add(taskSpec);

        /*
            OBJETOS PERSONALIZADOS
        */

        ObjectSpec vendedorSpec = obj('Vendedor__c');
        vendedorSpec.recordTypes.addAll(new List<String>{
            'Interno',
            'IA',
            'Promotoria',
            'Externo'
        });
        f(vendedorSpec, 'Name', 'String', null);
        f(vendedorSpec, 'Usuario_Salesforce__c', 'Reference', 'User');
        f(vendedorSpec, 'Email__c', 'Email', null);
        f(vendedorSpec, 'Telefono__c', 'Phone', null);
        f(vendedorSpec, 'Activo__c', 'Boolean', null);
        f(vendedorSpec, 'Tipo_Vendedor__c', 'Picklist', null);
        f(vendedorSpec, 'Zona__c', 'String', null);
        f(vendedorSpec, 'Canal_Origen__c', 'Picklist', null);
        f(vendedorSpec, 'Familias_Producto__c', 'MultiPicklist', null);
        f(vendedorSpec, 'Carga_Trabajo__c', 'Integer', null);
        f(vendedorSpec, 'Reasignable_por_SLA__c', 'Boolean', null);
        f(vendedorSpec, 'Porcentaje_Comision__c', 'Percent', null);
        specs.add(vendedorSpec);

        ObjectSpec vendedorProductoSpec = obj('Vendedor_Producto__c');
        f(vendedorProductoSpec, 'Name', 'String', null);
        f(vendedorProductoSpec, 'Vendedor__c', 'Reference', 'Vendedor__c');
        f(vendedorProductoSpec, 'Producto__c', 'Reference', 'Product2');
        f(vendedorProductoSpec, 'Familia_Producto__c', 'Picklist', null);
        f(vendedorProductoSpec, 'Activo__c', 'Boolean', null);
        f(vendedorProductoSpec, 'Prioridad__c', 'Integer', null);
        f(vendedorProductoSpec, 'Zona__c', 'String', null);
        specs.add(vendedorProductoSpec);

        ObjectSpec seguroSpec = obj('Seguro__c');
        seguroSpec.recordTypes.addAll(new List<String>{
            'Auto',
            'GMM',
            'Vida_PPR',
            'Danos',
            'Membresia_Ollin_Salud'
        });
        f(seguroSpec, 'Name', 'String', null);
        f(seguroSpec, 'Cliente__c', 'Reference', 'Account');
        f(seguroSpec, 'Opportunity__c', 'Reference', 'Opportunity');
        f(seguroSpec, 'Producto__c', 'Reference', 'Product2');
        f(seguroSpec, 'Vendedor__c', 'Reference', 'Vendedor__c');
        f(seguroSpec, 'Institucion__c', 'Reference', 'Account');
        f(seguroSpec, 'Numero_Seguro__c', 'String', null);
        f(seguroSpec, 'Policy_Id__c', 'String', null).externalId = true;
        f(seguroSpec, 'Ramo__c', 'Picklist', null);
        f(seguroSpec, 'Subramo__c', 'Picklist', null);
        f(seguroSpec, 'Vigencia_Inicio__c', 'Date', null);
        f(seguroSpec, 'Vigencia_Fin__c', 'Date', null);
        f(seguroSpec, 'Dias_Para_Vencer__c', 'Integer', null);
        f(seguroSpec, 'Frecuencia_Pago__c', 'Picklist', null);
        f(seguroSpec, 'Forma_Pago__c', 'Picklist', null);
        f(seguroSpec, 'Prima_Neta__c', 'Currency', null);
        f(seguroSpec, 'Descuento__c', 'Currency', null);
        f(seguroSpec, 'Recargos__c', 'Currency', null);
        f(seguroSpec, 'Derechos__c', 'Currency', null);
        f(seguroSpec, 'IVA__c', 'Currency', null);
        f(seguroSpec, 'Prima_Total__c', 'Currency', null);
        f(seguroSpec, 'Estatus__c', 'Picklist', null);
        f(seguroSpec, 'Tipo_Originador__c', 'Picklist', null);
        f(seguroSpec, 'Canal_Origen__c', 'Picklist', null);
        f(seguroSpec, 'Poliza_Renovada_De__c', 'Reference', 'Seguro__c');
        f(seguroSpec, 'Motivo_No_Renovacion__c', 'Picklist', null);
        f(seguroSpec, 'Fecha_Ultimo_Aviso_Renovacion__c', 'Date', null);
        specs.add(seguroSpec);

        ObjectSpec fianzaSpec = obj('Fianza__c');
        fianzaSpec.recordTypes.addAll(new List<String>{
            'Cumplimiento',
            'Anticipo',
            'Vicios_Ocultos',
            'Pasivos',
            'Otro'
        });
        f(fianzaSpec, 'Name', 'String', null);
        f(fianzaSpec, 'Contract__c', 'Reference', 'Contract');
        f(fianzaSpec, 'Cliente__c', 'Reference', 'Account');
        f(fianzaSpec, 'Beneficiario__c', 'Reference', 'Account');
        f(fianzaSpec, 'Institucion__c', 'Reference', 'Account');
        f(fianzaSpec, 'Vendedor__c', 'Reference', 'Vendedor__c');
        f(fianzaSpec, 'Producto__c', 'Reference', 'Product2');
        f(fianzaSpec, 'Numero_Fianza__c', 'String', null);
        f(fianzaSpec, 'Tipo_Riesgo__c', 'Picklist', null);
        f(fianzaSpec, 'Monto_Afianzado__c', 'Currency', null);
        f(fianzaSpec, 'Prima_Neta__c', 'Currency', null);
        f(fianzaSpec, 'Vigencia_Inicio__c', 'Date', null);
        f(fianzaSpec, 'Vigencia_Fin__c', 'Date', null);
        f(fianzaSpec, 'Plazo_Reclamacion_Dias__c', 'Integer', null);
        f(fianzaSpec, 'Monto_Afianzado_Vigente__c', 'Currency', null);
        f(fianzaSpec, 'Prima_Vigente__c', 'Currency', null);
        f(fianzaSpec, 'Fecha_Vencimiento_Vigente__c', 'Date', null);
        f(fianzaSpec, 'Dias_Para_Vencer__c', 'Integer', null);
        f(fianzaSpec, 'Exposicion_Porcentaje__c', 'Percent', null);
        f(fianzaSpec, 'Estatus__c', 'Picklist', null);
        specs.add(fianzaSpec);

        ObjectSpec endosoSeguroSpec = obj('Endoso__c');
        f(endosoSeguroSpec, 'Name', 'String', null);
        f(endosoSeguroSpec, 'Seguro__c', 'Reference', 'Seguro__c');
        f(endosoSeguroSpec, 'Tipo_Endoso__c', 'Picklist', null);
        f(endosoSeguroSpec, 'Fecha_Efectiva__c', 'Date', null);
        f(endosoSeguroSpec, 'Afecta_Prima__c', 'Boolean', null);
        f(endosoSeguroSpec, 'Diferencia_Monto__c', 'Currency', null);
        f(endosoSeguroSpec, 'Diferencia_Prima__c', 'Currency', null);
        f(endosoSeguroSpec, 'Estatus__c', 'Picklist', null);
        specs.add(endosoSeguroSpec);

        ObjectSpec convenioSpec = obj('Convenio_Modificatorio__c');
        f(convenioSpec, 'Name', 'String', null);
        f(convenioSpec, 'Contract__c', 'Reference', 'Contract');
        f(convenioSpec, 'Numero_Convenio__c', 'String', null);
        f(convenioSpec, 'Fecha__c', 'Date', null);
        f(convenioSpec, 'Tipo_Modificacion__c', 'Picklist', null);
        f(convenioSpec, 'Nuevo_Valor_Contrato__c', 'Currency', null);
        f(convenioSpec, 'Nueva_Fecha_Fin__c', 'Date', null);
        f(convenioSpec, 'Diferencia__c', 'Currency', null);
        f(convenioSpec, 'Descripcion__c', 'TextArea', null);
        specs.add(convenioSpec);

        ObjectSpec endosoFianzaSpec = obj('Endoso_de_Fianza__c');
        f(endosoFianzaSpec, 'Name', 'String', null);
        f(endosoFianzaSpec, 'Fianza__c', 'Reference', 'Fianza__c');
        f(endosoFianzaSpec, 'Convenio_Modificatorio__c', 'Reference', 'Convenio_Modificatorio__c');
        f(endosoFianzaSpec, 'Tipo_Endoso__c', 'Picklist', null);
        f(endosoFianzaSpec, 'Nuevo_Monto__c', 'Currency', null);
        f(endosoFianzaSpec, 'Nueva_Prima__c', 'Currency', null);
        f(endosoFianzaSpec, 'Nuevo_Vencimiento__c', 'Date', null);
        f(endosoFianzaSpec, 'Estatus__c', 'Picklist', null);
        specs.add(endosoFianzaSpec);

        ObjectSpec planSpec = obj('Plan_de_Pagos__c');
        f(planSpec, 'Name', 'String', null);
        f(planSpec, 'Seguro__c', 'Reference', 'Seguro__c');
        f(planSpec, 'Fianza__c', 'Reference', 'Fianza__c');
        f(planSpec, 'Frecuencia__c', 'Picklist', null);
        f(planSpec, 'Numero_Recibos__c', 'Integer', null);
        f(planSpec, 'Monto_Total__c', 'Currency', null);
        f(planSpec, 'Fecha_Inicio__c', 'Date', null);
        f(planSpec, 'Dia_Cobro_Mensual__c', 'Integer', null);
        f(planSpec, 'Metodo_Pago__c', 'Picklist', null);
        f(planSpec, 'Domiciliacion_Activa__c', 'Boolean', null);
        f(planSpec, 'Ultimos_4_Digitos__c', 'String', null);
        f(planSpec, 'Referencia_Domiciliacion__c', 'String', null);
        f(planSpec, 'Estatus__c', 'Picklist', null);
        f(planSpec, 'Moneda__c', 'Picklist', null);
        specs.add(planSpec);

        ObjectSpec reciboSpec = obj('Recibo__c');
        f(reciboSpec, 'Name', 'String', null);
        f(reciboSpec, 'Plan_de_Pagos__c', 'Reference', 'Plan_de_Pagos__c');
        f(reciboSpec, 'Numero_Recibo__c', 'Integer', null);
        f(reciboSpec, 'Fecha_Cobro__c', 'Date', null);
        f(reciboSpec, 'Fecha_Vencimiento__c', 'Date', null);
        f(reciboSpec, 'Monto_Programado__c', 'Currency', null);
        f(reciboSpec, 'Monto_Cobrado__c', 'Currency', null);
        f(reciboSpec, 'Fecha_Pago_Real__c', 'Date', null);
        f(reciboSpec, 'Estatus__c', 'Picklist', null);
        f(reciboSpec, 'Tipo_Pago__c', 'Picklist', null);
        f(reciboSpec, 'Metodo_Pago__c', 'Picklist', null);
        f(reciboSpec, 'Referencia_Pago__c', 'String', null);
        f(reciboSpec, 'Pago_Confirmado__c', 'Boolean', null);
        f(reciboSpec, 'Saldo_Pendiente__c', 'Currency', null);
        f(reciboSpec, 'Payment_Id__c', 'String', null).externalId = true;
        f(reciboSpec, 'Mensaje_Error_Pago__c', 'TextArea', null);
        specs.add(reciboSpec);

        ObjectSpec comisionSpec = obj('Comision__c');
        comisionSpec.recordTypes.addAll(new List<String>{
            'Maestra_Comisiones',
            'Comision_Registrada'
        });
        f(comisionSpec, 'Name', 'String', null);
        f(comisionSpec, 'Seguro__c', 'Reference', 'Seguro__c');
        f(comisionSpec, 'Fianza__c', 'Reference', 'Fianza__c');
        f(comisionSpec, 'Vendedor__c', 'Reference', 'Vendedor__c');
        f(comisionSpec, 'Institucion__c', 'Reference', 'Account');
        f(comisionSpec, 'Producto__c', 'Reference', 'Product2');
        f(comisionSpec, 'Tipo_Negocio__c', 'Picklist', null);
        f(comisionSpec, 'Porcentaje_Ollin__c', 'Percent', null);
        f(comisionSpec, 'Porcentaje_Vendedor__c', 'Percent', null);
        f(comisionSpec, 'Porcentaje_Aplicado__c', 'Percent', null);
        f(comisionSpec, 'Monto_Ollin__c', 'Currency', null);
        f(comisionSpec, 'Monto_Vendedor__c', 'Currency', null);
        f(comisionSpec, 'Estatus__c', 'Picklist', null);
        f(comisionSpec, 'Fecha_Inicio_Vigencia__c', 'Date', null);
        f(comisionSpec, 'Fecha_Fin_Vigencia__c', 'Date', null);
        f(comisionSpec, 'Vigente__c', 'Boolean', null);
        f(comisionSpec, 'ID_Externo_Unico__c', 'String', null).externalId = true;
        f(comisionSpec, 'Recibo__c', 'Reference', 'Recibo__c');
        specs.add(comisionSpec);

        ObjectSpec integrationLogSpec = obj('Integration_Log__c');
        f(integrationLogSpec, 'Name', 'String', null);
        f(integrationLogSpec, 'Sistema_Origen__c', 'String', null);
        f(integrationLogSpec, 'Sistema_Destino__c', 'String', null);
        f(integrationLogSpec, 'Operacion__c', 'Picklist', null);
        f(integrationLogSpec, 'Registro_Procesado_Id__c', 'String', null);
        f(integrationLogSpec, 'Resultado__c', 'Picklist', null);
        f(integrationLogSpec, 'Mensaje__c', 'TextArea', null);
        f(integrationLogSpec, 'Intentos__c', 'Integer', null);
        f(integrationLogSpec, 'Payload_Entrada__c', 'TextArea', null);
        f(integrationLogSpec, 'Payload_Salida__c', 'TextArea', null);
        f(integrationLogSpec, 'Fecha_Ejecucion__c', 'DateTime', null);
        specs.add(integrationLogSpec);

        ObjectSpec interaccionIaSpec = obj('Interaccion_IA__c');
        f(interaccionIaSpec, 'Name', 'String', null);
        f(interaccionIaSpec, 'Lead__c', 'Reference', 'Lead');
        f(interaccionIaSpec, 'Opportunity__c', 'Reference', 'Opportunity');
        f(interaccionIaSpec, 'Canal__c', 'Picklist', null);
        f(interaccionIaSpec, 'Fecha_Interaccion__c', 'DateTime', null);
        f(interaccionIaSpec, 'Decision__c', 'Picklist', null);
        f(interaccionIaSpec, 'Resultado__c', 'Picklist', null);
        f(interaccionIaSpec, 'Datos_Capturados__c', 'TextArea', null);
        f(interaccionIaSpec, 'Agentforce_Session_Id__c', 'String', null).externalId = true;
        specs.add(interaccionIaSpec);

        return specs;
    }

    private static ObjectSpec obj(String apiName) {
        return new ObjectSpec(apiName);
    }

    private static FieldSpec f(ObjectSpec spec, String apiName, String expectedType, String referenceTo) {
        FieldSpec fs = new FieldSpec(apiName, expectedType, referenceTo);
        spec.fields.put(apiName, fs);
        return fs;
    }

    private static void validateObjectSpec(ObjectSpec spec, Map<String, Schema.SObjectType> globalDescribe) {
        if (!globalDescribe.containsKey(spec.apiName)) {
            addResult('Objeto', spec.apiName, 'Debe existir', 'No existe', 'FAIL', 'Objeto no encontrado en la org.');
            return;
        }

        addResult('Objeto', spec.apiName, 'Debe existir', 'Existe', 'OK', 'Objeto encontrado.');

        Schema.DescribeSObjectResult objDescribe = globalDescribe.get(spec.apiName).getDescribe();

        validateRecordTypes(spec, objDescribe);
        validateFields(spec, objDescribe);
    }

    private static void validateRecordTypes(ObjectSpec spec, Schema.DescribeSObjectResult objDescribe) {
        if (spec.recordTypes == null || spec.recordTypes.isEmpty()) {
            return;
        }

        Map<String, Schema.RecordTypeInfo> rtMap = objDescribe.getRecordTypeInfosByDeveloperName();

        for (String rtDevName : spec.recordTypes) {
            if (!rtMap.containsKey(rtDevName)) {
                addResult(
                    'Record Type',
                    spec.apiName + '.' + rtDevName,
                    'Debe existir',
                    'No existe',
                    'FAIL',
                    'Tipo de registro requerido por el diseño.'
                );
            } else {
                Schema.RecordTypeInfo rti = rtMap.get(rtDevName);
                String availability = rti.isAvailable() ? 'Disponible para usuario ejecutor' : 'Existe, pero no disponible para usuario ejecutor';

                addResult(
                    'Record Type',
                    spec.apiName + '.' + rtDevName,
                    'Debe existir y estar disponible',
                    availability,
                    rti.isAvailable() ? 'OK' : 'WARN',
                    'Validar asignación del Record Type al perfil o Permission Set correspondiente.'
                );
            }
        }
    }

    private static void validateFields(ObjectSpec spec, Schema.DescribeSObjectResult objDescribe) {
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

        for (FieldSpec fs : spec.fields.values()) {
            if (!fieldMap.containsKey(fs.apiName)) {
                addResult(
                    'Campo',
                    spec.apiName + '.' + fs.apiName,
                    fs.expectedType,
                    'No existe',
                    'FAIL',
                    'Campo requerido por el diseño.'
                );
                continue;
            }

            Schema.DescribeFieldResult fd = fieldMap.get(fs.apiName).getDescribe();

            String actualType = getActualType(fd);
            Boolean typeOk = typeMatches(fs.expectedType, fd);

            addResult(
                'Campo',
                spec.apiName + '.' + fs.apiName,
                fs.expectedType,
                actualType,
                typeOk ? 'OK' : 'WARN',
                typeOk ? 'Tipo correcto.' : 'Tipo distinto al esperado. Validar si fue decisión de diseño.'
            );

            if (fs.externalId) {
                addResult(
                    'External ID',
                    spec.apiName + '.' + fs.apiName,
                    'External ID = true',
                    'External ID = ' + String.valueOf(fd.isExternalId()),
                    fd.isExternalId() ? 'OK' : 'WARN',
                    'Los campos de integración deben ser External ID para idempotencia.'
                );
            }

            if (!String.isBlank(fs.referenceTo)) {
                validateReference(spec.apiName, fs, fd);
            }
        }
    }

    private static void validateReference(String objectApiName, FieldSpec fs, Schema.DescribeFieldResult fd) {
        if (fd.getType() != Schema.DisplayType.Reference) {
            addResult(
                'Relación',
                objectApiName + '.' + fs.apiName,
                'Lookup/Master-Detail a ' + fs.referenceTo,
                'No es relación',
                'FAIL',
                'El campo debe ser relación.'
            );
            return;
        }

        Set<String> references = new Set<String>();
        for (Schema.SObjectType refType : fd.getReferenceTo()) {
            references.add(refType.getDescribe().getName());
        }

        Boolean refOk = references.contains(fs.referenceTo) || String.isBlank(fs.referenceTo);

        addResult(
            'Relación',
            objectApiName + '.' + fs.apiName,
            'Referencia a ' + fs.referenceTo,
            'Referencia a ' + String.join(new List<String>(references), ', '),
            refOk ? 'OK' : 'FAIL',
            refOk ? 'Relación correcta.' : 'La relación apunta a un objeto distinto al esperado.'
        );
    }

    private static void validateRetiredObjects(Map<String, Schema.SObjectType> globalDescribe) {
        List<String> retiredObjects = new List<String>{
            'Institucion__c',
            'Pago__c',
            'Tabla_de_Comisiones__c',
            'Renovacion__c'
        };

        for (String retiredObject : retiredObjects) {
            Boolean exists = globalDescribe.containsKey(retiredObject);
            addResult(
                'Objeto retirado',
                retiredObject,
                'No debe existir / no debe usarse',
                exists ? 'Existe' : 'No existe',
                exists ? 'WARN' : 'OK',
                exists
                    ? 'El diseño actualizado indica que este objeto debe desaparecer o quedar fuera de uso.'
                    : 'Correcto conforme al diseño actualizado.'
            );
        }
    }

    private static void validatePicklistValues(Map<String, Schema.SObjectType> globalDescribe) {
        Map<String, List<String>> expectedValues = new Map<String, List<String>>();

        expectedValues.put('Account.type', new List<String>{
            'Persona Física',
            'Persona Moral',
            'Beneficiario de Fianza',
            'Contratista',
            'Institución'
        });

        expectedValues.put('Account.Tipo_Institucion__c', new List<String>{
            'Aseguradora',
            'Afianzadora',
            'Ambas'
        });

        expectedValues.put('Lead.Producto_Interes__c', new List<String>{
            'Seguro de Auto',
            'Gastos Médicos',
            'Vida',
            'PPR',
            'Daños',
            'Membresía Ollin Salud',
            'Fianzas',
            'Otros'
        });

        expectedValues.put('Lead.Estado_Precalificacion__c', new List<String>{
            'Nuevo',
            'Recopilando información',
            'Accionable',
            'Calificado',
            'No calificado',
            'Reciclado'
        });

        expectedValues.put('Opportunity.StageName', new List<String>{
            'Oportunidad creada',
            'En análisis / levantamiento de información',
            'Cotización iniciada',
            'Cotización enviada / presentada',
            'Seguimiento',
            'Cierre ganado',
            'Cierre perdido'
        });

        expectedValues.put('Vendedor__c.Familias_Producto__c', new List<String>{
            'Auto',
            'GMM',
            'Vida',
            'PPR',
            'Daños',
            'Fianzas',
            'Membresía'
        });

        expectedValues.put('Seguro__c.Estatus__c', new List<String>{
            'Emitida',
            'Vigente',
            'Por renovar',
            'Renovada',
            'Vencida',
            'Cancelada'
        });

        expectedValues.put('Fianza__c.Estatus__c', new List<String>{
            'Emitida',
            'Vigente',
            'Por vencer',
            'Vencida',
            'Cancelada'
        });

        expectedValues.put('Plan_de_Pagos__c.Frecuencia__c', new List<String>{
            'Anual',
            'Semestral',
            'Trimestral',
            'Mensual',
            'Quincenal'
        });

        expectedValues.put('Recibo__c.Estatus__c', new List<String>{
            'Programado',
            'Por cobrar',
            'Cobrado',
            'Parcial',
            'Vencido',
            'Anulado',
            'Rechazado'
        });

        expectedValues.put('Comision__c.Estatus__c', new List<String>{
            'Maestra',
            'Devengada',
            'Liberada',
            'Pagada',
            'Clawback'
        });

        for (String key : expectedValues.keySet()) {
            List<String> parts = key.split('\\.');
            String objectApi = parts[0];
            String fieldApi = parts[1];

            if (!globalDescribe.containsKey(objectApi)) {
                addResult('Picklist', key, 'Valores esperados', 'Objeto no existe', 'FAIL', 'No se puede validar picklist.');
                continue;
            }

            Map<String, Schema.SObjectField> fieldMap = globalDescribe.get(objectApi).getDescribe().fields.getMap();

            if (!fieldMap.containsKey(fieldApi)) {
                addResult('Picklist', key, 'Valores esperados', 'Campo no existe', 'FAIL', 'No se puede validar picklist.');
                continue;
            }

            Schema.DescribeFieldResult fd = fieldMap.get(fieldApi).getDescribe();

            if (fd.getType() != Schema.DisplayType.Picklist && fd.getType() != Schema.DisplayType.MultiPicklist) {
                addResult('Picklist', key, 'Picklist/MultiPicklist', getActualType(fd), 'WARN', 'El campo no es picklist.');
                continue;
            }

            Set<String> actualValues = new Set<String>();
            for (Schema.PicklistEntry pe : fd.getPicklistValues()) {
                if (pe.isActive()) {
                    actualValues.add(pe.getValue());
                }
            }

            for (String expected : expectedValues.get(key)) {
                Boolean exists = actualValues.contains(expected);
                addResult(
                    'Valor Picklist',
                    key + ' = ' + expected,
                    'Debe existir',
                    exists ? 'Existe' : 'No existe',
                    exists ? 'OK' : 'WARN',
                    exists ? 'Valor activo.' : 'Agregar o mapear valor equivalente.'
                );
            }
        }
    }

    private static void validateExpectedApexClasses() {
        List<String> expectedApexClasses = new List<String>{
            'OllinPlanPagosService',
            'OllinPlanPagosServiceTest',
            'OllinVendedorProductoValidator',
            'OllinVendedorProductoValidatorTest',
            'OllinCommissionService',
            'OllinCommissionServiceTest',
            'OllinConfigAudit'
        };

        Set<String> found = new Set<String>();

        try {
            for (ApexClass ac : [
                SELECT Name
                FROM ApexClass
                WHERE Name IN :expectedApexClasses
            ]) {
                found.add(ac.Name);
            }

            for (String className : expectedApexClasses) {
                addResult(
                    'Apex Class',
                    className,
                    'Debe existir',
                    found.contains(className) ? 'Existe' : 'No existe',
                    found.contains(className) ? 'OK' : 'WARN',
                    'Validar si la lógica fue resuelta por Flow en lugar de Apex.'
                );
            }
        } catch (Exception e) {
            addResult(
                'Apex Class',
                'Consulta ApexClass',
                'Consulta disponible',
                e.getMessage(),
                'WARN',
                'No fue posible consultar ApexClass.'
            );
        }
    }

    private static void validateExpectedPermissionSets() {
        List<String> expectedPermissionSets = new List<String>{
            'Ollin_Admin',
            'Ollin_Direccion',
            'Ollin_Ventas',
            'Ollin_Operaciones',
            'Ollin_Marketing'
        };

        Set<String> found = new Set<String>();

        try {
            for (PermissionSet ps : [
                SELECT Name
                FROM PermissionSet
                WHERE Name IN :expectedPermissionSets
            ]) {
                found.add(ps.Name);
            }

            for (String psName : expectedPermissionSets) {
                addResult(
                    'Permission Set',
                    psName,
                    'Debe existir',
                    found.contains(psName) ? 'Existe' : 'No existe',
                    found.contains(psName) ? 'OK' : 'WARN',
                    'Validar permisos de objeto y campo en el set correspondiente.'
                );
            }
        } catch (Exception e) {
            addResult(
                'Permission Set',
                'Consulta PermissionSet',
                'Consulta disponible',
                e.getMessage(),
                'WARN',
                'No fue posible consultar PermissionSet.'
            );
        }
    }

    private static void validateExpectedFlows() {
        List<String> expectedFlows = new List<String>{
            'FL_Lead_Precalificacion_Scoring',
            'FL_Lead_Asignacion_Vendedor',
            'FL_Oportunidad_Cierre_Ganado_Crear_Seguro_Fianza',
            'FL_PlanPagos_Crear_Recibos',
            'FL_Recibo_Cobrado_Liberar_Comision',
            'FL_Seguro_Renovacion_Alertas',
            'FL_Cadencias_Lead_No_Contesta',
            'FL_Integracion_Cotizacion_Snapshot'
        };

        try {
            String queryString =
                'SELECT ApiName, Label ' +
                'FROM FlowDefinitionView ' +
                'WHERE ApiName IN ' + toSoqlInClause(expectedFlows);

            List<SObject> rows = Database.query(queryString);

            Set<String> found = new Set<String>();
            for (SObject row : rows) {
                found.add((String) row.get('ApiName'));
            }

            for (String flowApi : expectedFlows) {
                addResult(
                    'Flow',
                    flowApi,
                    'Debe existir y estar activo',
                    found.contains(flowApi) ? 'Existe' : 'No encontrado',
                    found.contains(flowApi) ? 'OK' : 'WARN',
                    'Validar manualmente versión activa, condiciones y acciones.'
                );
            }
        } catch (Exception e) {
            for (String flowApi : expectedFlows) {
                addResult(
                    'Flow',
                    flowApi,
                    'Debe existir y estar activo',
                    'No validado por Apex',
                    'INFO',
                    'No fue posible consultar FlowDefinitionView desde esta ejecución: ' + e.getMessage()
                );
            }
        }
    }

    private static void validateValidationRulesAvailability() {
        List<String> expectedValidationRules = new List<String>{
            'VR_PlanPagos_Solo_Un_Padre',
            'VR_Vendedor_Producto_Relacionado',
            'VR_Seguro_Datos_Minimos',
            'VR_Fianza_Datos_Minimos',
            'VR_Recibo_Monto_Cobrado',
            'VR_Comision_Porcentajes',
            'VR_Account_RFC_Obligatorio'
        };

        try {
            String queryString =
                'SELECT ValidationName, EntityDefinition.QualifiedApiName ' +
                'FROM ValidationRule ' +
                'WHERE ValidationName IN ' + toSoqlInClause(expectedValidationRules);

            List<SObject> rows = Database.query(queryString);

            Set<String> found = new Set<String>();
            for (SObject row : rows) {
                found.add((String) row.get('ValidationName'));
            }

            for (String vr : expectedValidationRules) {
                addResult(
                    'Validation Rule',
                    vr,
                    'Debe existir',
                    found.contains(vr) ? 'Existe' : 'No encontrada',
                    found.contains(vr) ? 'OK' : 'WARN',
                    'Validar fórmula y mensaje de error.'
                );
            }
        } catch (Exception e) {
            for (String vr : expectedValidationRules) {
                addResult(
                    'Validation Rule',
                    vr,
                    'Debe existir',
                    'Revisión manual',
                    'INFO',
                    'Apex estándar no pudo consultar ValidationRule en esta org: ' + e.getMessage()
                );
            }
        }
    }

    private static void validateManualReviewItems() {
        List<String> manualItems = new List<String>{
            'Lightning App Ollin Protección',
            'Navigation Items de Sales Console',
            'Dynamic Forms por Record Type',
            'Page Layout Assignment por perfil',
            'Lightning Record Pages activas por objeto',
            'Duplicate Rules para Lead, Account y Contact',
            'Matching Rules por Email, Teléfono y RFC',
            'Assignment Rules de Lead',
            'Email Templates',
            'Digital Engagement Templates',
            'Named Credentials de integraciones',
            'Remote Site Settings / External Credentials',
            'Field-Level Security para credenciales, comisiones y datos sensibles',
            'OWD, Role Hierarchy y Sharing Rules'
        };

        for (String itemName : manualItems) {
            addResult(
                'Revisión manual',
                itemName,
                'Debe configurarse',
                'No validado por este script',
                'INFO',
                'Revisar en Setup o mediante Metadata API.'
            );
        }
    }

    private static String getActualType(Schema.DescribeFieldResult fd) {
        if (fd.isAutoNumber()) {
            return 'AutoNumber';
        }
        return String.valueOf(fd.getType());
    }

    private static Boolean typeMatches(String expectedType, Schema.DescribeFieldResult fd) {
        if (String.isBlank(expectedType) || expectedType == 'ANY') {
            return true;
        }

        if (expectedType == 'AutoNumber') {
            return fd.isAutoNumber();
        }

        String expected = expectedType.toLowerCase();
        String actual = String.valueOf(fd.getType()).toLowerCase();

        Map<String, Set<String>> aliases = new Map<String, Set<String>>();
        aliases.put('string', new Set<String>{ 'string' });
        aliases.put('text', new Set<String>{ 'string' });
        aliases.put('textarea', new Set<String>{ 'textarea' });
        aliases.put('longtextarea', new Set<String>{ 'textarea' });
        aliases.put('integer', new Set<String>{ 'integer' });
        aliases.put('number', new Set<String>{ 'integer', 'double' });
        aliases.put('double', new Set<String>{ 'double' });
        aliases.put('currency', new Set<String>{ 'currency' });
        aliases.put('percent', new Set<String>{ 'percent' });
        aliases.put('date', new Set<String>{ 'date' });
        aliases.put('datetime', new Set<String>{ 'datetime' });
        aliases.put('boolean', new Set<String>{ 'boolean' });
        aliases.put('checkbox', new Set<String>{ 'boolean' });
        aliases.put('picklist', new Set<String>{ 'picklist' });
        aliases.put('multipicklist', new Set<String>{ 'multipicklist' });
        aliases.put('reference', new Set<String>{ 'reference' });
        aliases.put('lookup', new Set<String>{ 'reference' });
        aliases.put('masterdetail', new Set<String>{ 'reference' });
        aliases.put('email', new Set<String>{ 'email' });
        aliases.put('phone', new Set<String>{ 'phone' });
        aliases.put('url', new Set<String>{ 'url' });
        aliases.put('address', new Set<String>{ 'address' });

        if (!aliases.containsKey(expected)) {
            return expected == actual;
        }

        return aliases.get(expected).contains(actual);
    }

    private static String toSoqlInClause(List<String> values) {
        List<String> escaped = new List<String>();

        for (String value : values) {
            escaped.add('\'' + String.escapeSingleQuotes(value) + '\'');
        }

        return '(' + String.join(escaped, ',') + ')';
    }

    private static void addResult(
        String sectionName,
        String itemName,
        String expectedValue,
        String actualValue,
        String status,
        String notes
    ) {
        results.add(new CheckResult(
            sectionName,
            itemName,
            expectedValue,
            actualValue,
            status,
            notes
        ));
    }

    private static void printResults() {
        Integer okCount = 0;
        Integer failCount = 0;
        Integer warnCount = 0;
        Integer infoCount = 0;

        List<String> csvLines = new List<String>();
        csvLines.add('Seccion,Elemento,Esperado,Actual,Estatus,Notas');

        System.debug(LoggingLevel.INFO, '================ OLLIN CONFIG AUDIT - INICIO ================');

        for (CheckResult r : results) {
            if (r.status == 'OK') okCount++;
            else if (r.status == 'FAIL') failCount++;
            else if (r.status == 'WARN') warnCount++;
            else infoCount++;

            String line =
                '[' + r.status + '] ' +
                r.sectionName + ' | ' +
                r.itemName + ' | Esperado: ' +
                r.expectedValue + ' | Actual: ' +
                r.actualValue + ' | Notas: ' +
                r.notes;

            System.debug(LoggingLevel.INFO, line);

            csvLines.add(
                csv(r.sectionName) + ',' +
                csv(r.itemName) + ',' +
                csv(r.expectedValue) + ',' +
                csv(r.actualValue) + ',' +
                csv(r.status) + ',' +
                csv(r.notes)
            );
        }

        Integer total = results.size();
        Decimal passRate = total == 0 ? 0 : ((Decimal) okCount / (Decimal) total) * 100;

        System.debug(LoggingLevel.INFO, '================ OLLIN CONFIG AUDIT - RESUMEN ================');
        System.debug(LoggingLevel.INFO, 'TOTAL=' + total);
        System.debug(LoggingLevel.INFO, 'OK=' + okCount);
        System.debug(LoggingLevel.INFO, 'FAIL=' + failCount);
        System.debug(LoggingLevel.INFO, 'WARN=' + warnCount);
        System.debug(LoggingLevel.INFO, 'INFO=' + infoCount);
        System.debug(LoggingLevel.INFO, 'CUMPLIMIENTO_OK_PCT=' + passRate.setScale(2) + '%');

        if (failCount > 0) {
            System.debug(LoggingLevel.INFO, 'EVALUACION=NO APTO PARA PASAR A UAT. Existen componentes obligatorios faltantes.');
        } else if (warnCount > 0) {
            System.debug(LoggingLevel.INFO, 'EVALUACION=APTO CON OBSERVACIONES. Revisar advertencias antes de UAT.');
        } else {
            System.debug(LoggingLevel.INFO, 'EVALUACION=APTO PARA UAT. No se detectaron faltantes críticos.');
        }

        System.debug(LoggingLevel.INFO, '================ OLLIN CONFIG AUDIT - FIN ================');

        if (CREATE_CSV_FILE) {
            createCsvFile(csvLines);
        }
    }

    private static String csv(String value) {
        if (value == null) {
            value = '';
        }
        return '"' + value.replace('"', '""') + '"';
    }

    private static void createCsvFile(List<String> csvLines) {
        try {
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Ollin_Config_Audit_' + Datetime.now().format('yyyyMMdd_HHmmss');
            cv.PathOnClient = cv.Title + '.csv';
            cv.VersionData = Blob.valueOf(String.join(csvLines, '\n'));
            insert cv;

            System.debug(LoggingLevel.INFO, 'CSV_FILE_CREATED=ContentVersion Id ' + cv.Id);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'CSV_FILE_ERROR=' + e.getMessage());
        }
    }
}