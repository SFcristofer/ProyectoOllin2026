public with sharing class TechVendedorMetadataInstaller {

    private static final String API_VERSION = 'v60.0';

    public class InstallerException extends Exception {}

    public static void run() {
        System.debug('======================================================');
        System.debug('INICIO INSTALACIÓN METADATA: Tech_Vendedor__c');
        System.debug('======================================================');

        ensureGlobalValueSetFamiliaProducto();
        ensureTechVendedorObject();
        //ensureRecordTypes();
        //ensureFields();
        //ensureValidationRules();

        System.debug('======================================================');
        System.debug('FIN INSTALACIÓN METADATA: revisar errores/advertencias en el log');
        System.debug('======================================================');
    }

    // =========================================================
    // 1. GLOBAL VALUE SET: Ramos_GVS
    // =========================================================
    private static void ensureGlobalValueSetFamiliaProducto() {
        String soql = 'SELECT Id FROM GlobalValueSet WHERE DeveloperName = \'Ramos_GVS\'';

        if (toolingHasRows(soql)) {
            logOk('GlobalValueSet Ramos_GVS ya existe.');
            return;
        }

        List<Object> values = new List<Object>{
            globalValue('Auto', 'Auto', false),
            globalValue('GMM', 'Gastos Médicos Mayores', false),
            globalValue('Vida', 'Vida', false),
            globalValue('PPR', 'PPR / Inversión', false),
            globalValue('Danos', 'Daños', false),
            globalValue('Fianzas', 'Fianzas', false),
            globalValue('Membresia_Ollin_Salud', 'Membresía Ollin Salud', false),
            globalValue('Otros', 'Otros', false)
        };

        Map<String, Object> metadata = new Map<String, Object>{
            'masterLabel' => 'Familia Producto',
            'customValue' => values,
            'sorted' => false
        };

        createToolingMetadata('GlobalValueSet', 'Ramos_GVS', metadata);
        logOk('GlobalValueSet Ramos_GVS creado.');
    }

    private static Map<String, Object> globalValue(String fullName, String label, Boolean isDefault) {
        return new Map<String, Object>{
            'fullName' => fullName,
            'label' => label,
            'default' => isDefault
        };
    }

    // =========================================================
    // 2. CUSTOM OBJECT: Tech_Vendedor__c
    // =========================================================
    private static void ensureTechVendedorObject() {
        String soql = 'SELECT Id FROM CustomObject WHERE DeveloperName = \'Tech_Vendedor\'';

        if (toolingHasRows(soql)) {
            logOk('Objeto Tech_Vendedor__c ya existe.');
            return;
        }

        Map<String, Object> nameField = new Map<String, Object>{
            'type' => 'AutoNumber',
            'label' => 'Número de Vendedor',
            'displayFormat' => 'VEN-{00000}',
            'startingNumber' => 1
        };

        Map<String, Object> metadata = new Map<String, Object>{
            'label' => 'Tech Vendedor',
            'pluralLabel' => 'Tech Vendedores',
            'deploymentStatus' => 'Deployed',
            'sharingModel' => 'ReadWrite',
            'enableReports' => true,
            'enableActivities' => true,
            'enableHistory' => true,
            'nameField' => nameField
        };

        createToolingMetadata('CustomObject', 'Tech_Vendedor__c', metadata);
        logOk('Objeto Tech_Vendedor__c creado.');
    }

    // =========================================================
    // 3. RECORD TYPES
    // =========================================================
    private static void ensureRecordTypes() {
        ensureRecordType('Interno', 'Interno', 'Vendedor interno de Ollin con usuario Salesforce.');
        ensureRecordType('Externo_Promotoria', 'Externo Promotoría', 'Vendedor o agente externo sin acceso Salesforce.');
        ensureRecordType('IA', 'IA', 'Originador o agente de inteligencia artificial.');
    }

    private static void ensureRecordType(String developerName, String label, String description) {
        String soql =
            'SELECT Id FROM RecordType ' +
            'WHERE SobjectType = \'Tech_Vendedor__c\' ' +
            'AND Name = \'' + String.escapeSingleQuotes(label) + '\'';

        if (toolingHasRows(soql)) {
            logOk('Record Type ya existe: ' + label);
            return;
        }

        Map<String, Object> metadata = new Map<String, Object>{
            'active' => true,
            'label' => label,
            'description' => description
        };

        createToolingMetadata(
            'RecordType',
            'Tech_Vendedor__c.' + developerName,
            metadata
        );

        logOk('Record Type creado: ' + label);
    }

    // =========================================================
    // 4. CAMPOS DEL OBJETO Tech_Vendedor__c
    // =========================================================
    private static void ensureFields() {

        ensureTextField(
            'Nombre_Completo__c',
            'Nombre completo',
            150,
            true,
            'Nombre completo operativo del vendedor.'
        );

        ensureLookupField(
            'Usuario_Salesforce__c',
            'Usuario Salesforce',
            'User',
            'Vendedores_Salesforce',
            false,
            'Usuario Salesforce relacionado cuando el vendedor es interno.'
        );

        ensureEmailField(
            'Email__c',
            'Email',
            false,
            'Correo electrónico del vendedor.'
        );

        ensurePhoneField(
            'Telefono__c',
            'Teléfono',
            false,
            'Teléfono de contacto del vendedor.'
        );

        ensurePicklistField(
            'Tipo_Vendedor__c',
            'Tipo de vendedor',
            new List<Map<String, Object>>{
                pickValue('Interno', 'Interno', true),
                pickValue('Externo_Promotoria', 'Externo Promotoría', false),
                pickValue('IA', 'IA', false)
            },
            true,
            'Clasifica si el vendedor es interno, externo o IA.'
        );

        ensureGlobalPicklistField(
            'Ramo__c',
            'Ramo',
            'Ramos_GVS',
            true,
            'Familia principal de producto que puede vender el vendedor.'
        );

        ensureLookupField(
            'Promotoria__c',
            'Promotoría',
            'Account',
            'Vendedores_Promotoria',
            false,
            'Cuenta tipo Institución/Promotoría asociada a vendedores externos.'
        );

        ensureTextField(
            'Zona__c',
            'Zona',
            80,
            false,
            'Zona comercial o geográfica principal.'
        );

        ensureTextField(
            'Estado__c',
            'Estado',
            80,
            false,
            'Estado principal de atención.'
        );

        ensureTextField(
            'Codigo_Postal_Base__c',
            'Código Postal Base',
            10,
            false,
            'Código postal base para reglas de asignación.'
        );

        ensureNumberField(
            'Carga_Trabajo_Actual__c',
            'Carga de trabajo actual',
            5,
            0,
            false,
            'Número de leads u oportunidades actualmente asignadas.'
        );

        ensureNumberField(
            'Capacidad_Maxima__c',
            'Capacidad máxima',
            5,
            0,
            false,
            'Capacidad máxima sugerida para balanceo de carga.'
        );

        ensurePercentField(
            'Porcentaje_Comision__c',
            '% Comisión',
            5,
            2,
            false,
            'Porcentaje base de comisión asignado al vendedor.'
        );

        ensureCheckboxField(
            'Activo__c',
            'Activo',
            true,
            'Indica si el vendedor puede recibir asignaciones.'
        );

        ensureCheckboxField(
            'Puede_Reasignarse_SLA__c',
            'Puede reasignarse por SLA',
            true,
            'Permite reasignar leads u oportunidades si incumple SLA.'
        );

        ensureDateField(
            'Fecha_Ingreso__c',
            'Fecha de ingreso',
            false,
            'Fecha de alta o ingreso del vendedor.'
        );

        ensureTextAreaField(
            'Observaciones__c',
            'Observaciones',
            32768,
            false,
            'Notas operativas del vendedor.'
        );
    }

    // =========================================================
    // 5. REGLAS DE VALIDACIÓN
    // =========================================================
    private static void ensureValidationRules() {

        ensureValidationRule(
            'VR_TechVendedor_Ramo_Activo',
            'Ramo obligatorio si el vendedor está activo.',
            'AND(Activo__c = TRUE, ISBLANK(TEXT(Ramo__c)))',
            'Debe capturar el Ramo del vendedor cuando el vendedor esté activo.',
            'Ramo__c'
        );

        ensureValidationRule(
            'VR_TechVendedor_Usuario_Interno',
            'Usuario Salesforce obligatorio para vendedor interno.',
            'AND($RecordType.DeveloperName = "Interno", ISBLANK(Usuario_Salesforce__c))',
            'Debe capturar el Usuario Salesforce cuando el vendedor sea interno.',
            'Usuario_Salesforce__c'
        );

        ensureValidationRule(
            'VR_TechVendedor_Promotoria_Externo',
            'Promotoría obligatoria para vendedor externo.',
            'AND($RecordType.DeveloperName = "Externo_Promotoria", ISBLANK(Promotoria__c))',
            'Debe capturar la Promotoría cuando el vendedor sea externo.',
            'Promotoria__c'
        );

        ensureValidationRule(
            'VR_TechVendedor_Comision_Rango',
            'La comisión debe estar entre 0 y 100.',
            'OR(Porcentaje_Comision__c < 0, Porcentaje_Comision__c > 100)',
            'El porcentaje de comisión debe estar entre 0 y 100.',
            'Porcentaje_Comision__c'
        );

        ensureValidationRule(
            'VR_TechVendedor_Capacidad_Activo',
            'Capacidad máxima obligatoria si está activo.',
            'AND(Activo__c = TRUE, OR(ISBLANK(Capacidad_Maxima__c), Capacidad_Maxima__c <= 0))',
            'Debe capturar una capacidad máxima mayor a cero cuando el vendedor esté activo.',
            'Capacidad_Maxima__c'
        );
    }

    private static void ensureValidationRule(
        String ruleName,
        String description,
        String formula,
        String errorMessage,
        String errorDisplayField
    ) {
        Map<String, Object> metadata = new Map<String, Object>{
            'active' => true,
            'description' => description,
            'errorConditionFormula' => formula,
            'errorMessage' => errorMessage,
            'errorDisplayField' => errorDisplayField
        };

        createToolingMetadata(
            'ValidationRule',
            'Tech_Vendedor__c.' + ruleName,
            metadata
        );

        logOk('Validation Rule enviada: ' + ruleName);
    }

    // =========================================================
    // FIELD HELPERS
    // =========================================================
    private static void ensureTextField(
        String apiName,
        String label,
        Integer length,
        Boolean required,
        String description
    ) {
        Map<String, Object> metadata = baseField(label, 'Text', required, description);
        metadata.put('length', length);
        ensureField(apiName, metadata);
    }

    private static void ensureTextAreaField(
        String apiName,
        String label,
        Integer length,
        Boolean required,
        String description
    ) {
        Map<String, Object> metadata = baseField(label, 'LongTextArea', required, description);
        metadata.put('length', length);
        metadata.put('visibleLines', 4);
        ensureField(apiName, metadata);
    }

    private static void ensureEmailField(
        String apiName,
        String label,
        Boolean required,
        String description
    ) {
        ensureField(apiName, baseField(label, 'Email', required, description));
    }

    private static void ensurePhoneField(
        String apiName,
        String label,
        Boolean required,
        String description
    ) {
        ensureField(apiName, baseField(label, 'Phone', required, description));
    }

    private static void ensureDateField(
        String apiName,
        String label,
        Boolean required,
        String description
    ) {
        ensureField(apiName, baseField(label, 'Date', required, description));
    }

    private static void ensureNumberField(
        String apiName,
        String label,
        Integer precision,
        Integer scale,
        Boolean required,
        String description
    ) {
        Map<String, Object> metadata = baseField(label, 'Number', required, description);
        metadata.put('precision', precision);
        metadata.put('scale', scale);
        ensureField(apiName, metadata);
    }

    private static void ensurePercentField(
        String apiName,
        String label,
        Integer precision,
        Integer scale,
        Boolean required,
        String description
    ) {
        Map<String, Object> metadata = baseField(label, 'Percent', required, description);
        metadata.put('precision', precision);
        metadata.put('scale', scale);
        ensureField(apiName, metadata);
    }

    private static void ensureCheckboxField(
        String apiName,
        String label,
        Boolean defaultValue,
        String description
    ) {
        Map<String, Object> metadata = baseField(label, 'Checkbox', false, description);
        metadata.put('defaultValue', String.valueOf(defaultValue));
        ensureField(apiName, metadata);
    }

    private static void ensureLookupField(
        String apiName,
        String label,
        String referenceTo,
        String relationshipName,
        Boolean required,
        String description
    ) {
        Map<String, Object> metadata = baseField(label, 'Lookup', required, description);
        metadata.put('referenceTo', referenceTo);
        metadata.put('relationshipName', relationshipName);
        metadata.put('deleteConstraint', 'SetNull');
        ensureField(apiName, metadata);
    }

    private static void ensureGlobalPicklistField(
        String apiName,
        String label,
        String globalValueSetName,
        Boolean required,
        String description
    ) {
        Map<String, Object> metadata = baseField(label, 'Picklist', required, description);
        metadata.put('valueSet', new Map<String, Object>{
            'restricted' => true,
            'valueSetName' => globalValueSetName
        });
        ensureField(apiName, metadata);
    }

    private static void ensurePicklistField(
        String apiName,
        String label,
        List<Map<String, Object>> values,
        Boolean required,
        String description
    ) {
        Map<String, Object> metadata = baseField(label, 'Picklist', required, description);
        metadata.put('valueSet', new Map<String, Object>{
            'restricted' => true,
            'valueSetDefinition' => new Map<String, Object>{
                'sorted' => false,
                'value' => values
            }
        });
        ensureField(apiName, metadata);
    }

    private static Map<String, Object> pickValue(String fullName, String label, Boolean isDefault) {
        return new Map<String, Object>{
            'fullName' => fullName,
            'label' => label,
            'default' => isDefault
        };
    }

    private static Map<String, Object> baseField(
        String label,
        String typeValue,
        Boolean required,
        String description
    ) {
        return new Map<String, Object>{
            'label' => label,
            'type' => typeValue,
            'required' => required,
            'description' => description
        };
    }

    private static void ensureField(String apiName, Map<String, Object> metadata) {
        String developerName = apiName.replace('__c', '');
        String soql =
            'SELECT Id FROM CustomField ' +
            'WHERE TableEnumOrId = \'Tech_Vendedor__c\' ' +
            'AND DeveloperName = \'' + String.escapeSingleQuotes(developerName) + '\'';

        if (toolingHasRows(soql)) {
            logOk('Campo ya existe: ' + apiName);
            return;
        }

        createToolingMetadata(
            'CustomField',
            'Tech_Vendedor__c.' + apiName,
            metadata
        );

        logOk('Campo creado/enviado: ' + apiName);
    }

    // =========================================================
    // TOOLING API HELPERS
    // =========================================================
    private static void createToolingMetadata(
        String toolingSObject,
        String fullName,
        Map<String, Object> metadata
    ) {
        Map<String, Object> payload = new Map<String, Object>{
            'FullName' => fullName,
            'Metadata' => metadata
        };

        HttpResponse response = sendTooling(
            'POST',
            '/services/data/' + API_VERSION + '/tooling/sobjects/' + toolingSObject,
            JSON.serialize(payload)
        );

        Integer statusCode = response.getStatusCode();

        if (statusCode >= 200 && statusCode < 300) {
            System.debug('OK Tooling create ' + toolingSObject + ': ' + fullName);
        } else {
            System.debug('WARN/ERROR Tooling create ' + toolingSObject + ': ' + fullName);
            System.debug('Status: ' + statusCode);
            System.debug('Body: ' + response.getBody());
        }
    }

    private static Boolean toolingHasRows(String soql) {
        HttpResponse response = sendTooling(
            'GET',
            '/services/data/' + API_VERSION + '/tooling/query/?q=' +
            EncodingUtil.urlEncode(soql, 'UTF-8'),
            null
        );

        if (response.getStatusCode() < 200 || response.getStatusCode() >= 300) {
            System.debug('WARN Tooling query falló: ' + soql);
            System.debug('Status: ' + response.getStatusCode());
            System.debug('Body: ' + response.getBody());
            return false;
        }

        Map<String, Object> result =
            (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

        Object totalSizeObj = result.get('totalSize');
        Integer totalSize = totalSizeObj == null ? 0 : Integer.valueOf(String.valueOf(totalSizeObj));

        return totalSize > 0;
    }

    private static HttpResponse sendTooling(String method, String path, String body) {
        HttpRequest request = new HttpRequest();

        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        request.setEndpoint(baseUrl + path);
        request.setMethod(method);
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        request.setHeader('Content-Type', 'application/json');

        if (body != null) {
            request.setBody(body);
        }

        Http http = new Http();
        return http.send(request);
    }

    private static void logOk(String message) {
        System.debug('OK | ' + message);
    }
}