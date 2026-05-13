public with sharing class TechMetadataInspector {

    /*
     * =====================================================================================
     * CLASE: TechMetadataInspector
     * =====================================================================================
     *
     * Versión: Auditoría completa
     *
     * Objetivo:
     * - Consultar todos los objetos accesibles por Schema Describe.
     * - Consultar todos los campos de todos los objetos inspeccionados.
     * - Consultar relaciones hijas.
     * - Consultar Record Types.
     * - Consultar reglas de validación.
     * - Consultar layouts.
     * - Consultar todos los triggers Apex.
     * - Consultar todas las clases Apex.
     * - Exportar código Apex completo de clases y triggers.
     * - Detectar referencias a objetos dentro del Body de clases/triggers.
     *
     * Importante:
     * - No usa WHERE Body LIKE, porque Tooling API no permite filtrar por Body.
     * - Para orgs grandes, se recomienda generar objetos y código Apex en archivos separados.
     * - Ejecutar con usuario administrador.
     * - Puede requerir Remote Site Setting hacia la propia org si no se usa Named Credential.
     */

    private static final String API_VERSION = 'v60.0';

    /*
     * =====================================================================================
     * MÉTODOS PRINCIPALES
     * =====================================================================================
     */

    public static String generarJsonEstructura() {
        return generarJsonAuditoriaCompleta(true, true);
    }

    public static Id generarArchivoJsonEstructura() {
        return generarArchivoJsonAuditoriaCompleta();
    }

    public static String generarJsonAuditoriaCompleta() {
        return generarJsonAuditoriaCompleta(true, true);
    }

    public static Id generarArchivoJsonAuditoriaCompleta() {
        String jsonResultado = generarJsonAuditoriaCompleta(true, true);
        return crearArchivo(
            'Tech_Metadata_Inspector_Full_' + Datetime.now().format('yyyyMMdd_HHmmss'),
            'Tech_Metadata_Inspector_Full.json',
            jsonResultado
        );
    }

    public static Id generarArchivoJsonSoloObjetos() {
        String jsonResultado = generarJsonAuditoriaCompleta(true, false);
        return crearArchivo(
            'Tech_Metadata_Inspector_Objetos_' + Datetime.now().format('yyyyMMdd_HHmmss'),
            'Tech_Metadata_Inspector_Objetos.json',
            jsonResultado
        );
    }

    public static Id generarArchivoCodigoApexCompleto() {
        String codigoApex = generarTextoCodigoApexCompleto();
        return crearArchivo(
            'Tech_Apex_Source_Export_Full_' + Datetime.now().format('yyyyMMdd_HHmmss'),
            'Tech_Apex_Source_Export_Full.txt',
            codigoApex
        );
    }

    public static String generarJsonAuditoriaCompleta(
        Boolean incluirObjetosEstandar,
        Boolean incluirCodigoApex
    ) {

        Map<String, Object> resultado = new Map<String, Object>();

        resultado.put('fechaEjecucion', String.valueOf(System.now()));
        resultado.put('organizacionId', UserInfo.getOrganizationId());
        resultado.put('usuarioId', UserInfo.getUserId());
        resultado.put('apiVersion', API_VERSION);
        resultado.put('modo', 'AUDITORIA_COMPLETA');
        resultado.put('incluirObjetosEstandar', incluirObjetosEstandar);
        resultado.put('incluirCodigoApex', incluirCodigoApex);

        List<String> nombresObjetos = obtenerNombresObjetosAccesibles(incluirObjetosEstandar);

        resultado.put('totalObjetosDetectados', nombresObjetos.size());
        resultado.put('objetosDetectados', nombresObjetos);

        resultado.put('objetos', obtenerEstructuraObjetos(nombresObjetos));

        resultado.put('recordTypes', obtenerRecordTypesSeguros(nombresObjetos));

        resultado.put(
            'reglasValidacion',
            ejecutarConsultaToolingSegura(
                'Reglas de Validación - Todas',
                'SELECT Id, ValidationName, Active, Description, ErrorDisplayField, ' +
                'ErrorMessage, EntityDefinition.QualifiedApiName ' +
                'FROM ValidationRule ' +
                'ORDER BY EntityDefinition.QualifiedApiName, ValidationName'
            )
        );

        resultado.put(
            'layouts',
            ejecutarConsultaToolingSegura(
                'Layouts - Todos',
                'SELECT Id, Name, TableEnumOrId ' +
                'FROM Layout ' +
                'ORDER BY TableEnumOrId, Name'
            )
        );

        resultado.put(
            'triggers',
            ejecutarConsultaToolingSegura(
                'Triggers Apex - Todos sin Body',
                'SELECT Id, Name, TableEnumOrId, Status, ApiVersion ' +
                'FROM ApexTrigger ' +
                'ORDER BY TableEnumOrId, Name'
            )
        );

        resultado.put(
            'clasesApex',
            obtenerClasesApexTodas(incluirCodigoApex, nombresObjetos)
        );

        resultado.put(
            'codigoApexExportado',
            obtenerCodigoApexCompleto(incluirCodigoApex, nombresObjetos)
        );

        resultado.put('trabajosProgramados', obtenerTrabajosProgramadosSeguros());

        return JSON.serializePretty(resultado);
    }

    /*
     * =====================================================================================
     * EXPORTACIÓN DE CÓDIGO APEX EN TEXTO
     * =====================================================================================
     */

    public static String generarTextoCodigoApexCompleto() {

        List<String> nombresObjetos = obtenerNombresObjetosAccesibles(true);
        Map<String, Object> codigo = obtenerCodigoApexCompleto(true, nombresObjetos);

        String salida = '';
        salida += 'EXPORTACIÓN COMPLETA DE CÓDIGO APEX\n';
        salida += 'Fecha de ejecución: ' + String.valueOf(System.now()) + '\n';
        salida += 'Organización: ' + UserInfo.getOrganizationId() + '\n';
        salida += 'Usuario: ' + UserInfo.getUserId() + '\n';
        salida += '============================================================\n\n';

        List<Object> clases = (List<Object>) codigo.get('clases');
        List<Object> triggers = (List<Object>) codigo.get('triggers');

        salida += '==================== CLASES APEX ====================\n\n';

        for (Object claseObj : clases) {
            Map<String, Object> clase = (Map<String, Object>) claseObj;

            salida += '/*\n';
            salida += ' * Clase: ' + String.valueOf(clase.get('Name')) + '\n';
            salida += ' * Id: ' + String.valueOf(clase.get('Id')) + '\n';
            salida += ' * Status: ' + String.valueOf(clase.get('Status')) + '\n';
            salida += ' * API Version: ' + String.valueOf(clase.get('ApiVersion')) + '\n';
            salida += ' */\n';

            if (clase.containsKey('Body') && clase.get('Body') != null) {
                salida += String.valueOf(clase.get('Body')) + '\n\n';
            } else {
                salida += '// Código no disponible en la respuesta Tooling API.\n\n';
            }

            salida += '============================================================\n\n';
        }

        salida += '==================== TRIGGERS APEX ====================\n\n';

        for (Object triggerObj : triggers) {
            Map<String, Object> triggerApex = (Map<String, Object>) triggerObj;

            salida += '/*\n';
            salida += ' * Trigger: ' + String.valueOf(triggerApex.get('Name')) + '\n';
            salida += ' * Objeto: ' + String.valueOf(triggerApex.get('TableEnumOrId')) + '\n';
            salida += ' * Id: ' + String.valueOf(triggerApex.get('Id')) + '\n';
            salida += ' * Status: ' + String.valueOf(triggerApex.get('Status')) + '\n';
            salida += ' * API Version: ' + String.valueOf(triggerApex.get('ApiVersion')) + '\n';
            salida += ' */\n';

            if (triggerApex.containsKey('Body') && triggerApex.get('Body') != null) {
                salida += String.valueOf(triggerApex.get('Body')) + '\n\n';
            } else {
                salida += '// Código no disponible en la respuesta Tooling API.\n\n';
            }

            salida += '============================================================\n\n';
        }

        List<Object> errores = (List<Object>) codigo.get('errores');

        if (errores != null && !errores.isEmpty()) {
            salida += '==================== ERRORES / CONSULTAS NO COMPLETADAS ====================\n\n';
            salida += JSON.serializePretty(errores);
            salida += '\n';
        }

        return salida;
    }

    /*
     * =====================================================================================
     * OBJETOS
     * =====================================================================================
     */

    private static List<String> obtenerNombresObjetosAccesibles(Boolean incluirObjetosEstandar) {

        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        List<String> nombresObjetos = new List<String>();

        for (String nombreObjeto : globalDescribe.keySet()) {

            Schema.DescribeSObjectResult describeObj = globalDescribe.get(nombreObjeto).getDescribe();

            if (incluirObjetosEstandar != true && !describeObj.isCustom()) {
                continue;
            }

            nombresObjetos.add(nombreObjeto);
        }

        nombresObjetos.sort();
        return nombresObjetos;
    }

    private static List<ObjectInfo> obtenerEstructuraObjetos(List<String> nombresObjetos) {

        List<ObjectInfo> objetos = new List<ObjectInfo>();
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

        for (String nombreObjeto : nombresObjetos) {

            ObjectInfo objInfo = new ObjectInfo();
            objInfo.apiName = nombreObjeto;

            if (!globalDescribe.containsKey(nombreObjeto)) {
                objInfo.existe = false;
                objInfo.error = 'El objeto no existe o el usuario no tiene acceso.';
                objetos.add(objInfo);
                continue;
            }

            try {
                Schema.DescribeSObjectResult describeObj =
                    globalDescribe.get(nombreObjeto).getDescribe();

                objInfo.existe = true;
                objInfo.label = describeObj.getLabel();
                objInfo.labelPlural = describeObj.getLabelPlural();
                objInfo.keyPrefix = describeObj.getKeyPrefix();
                objInfo.custom = describeObj.isCustom();
                objInfo.createable = describeObj.isCreateable();
                objInfo.updateable = describeObj.isUpdateable();
                objInfo.deletable = describeObj.isDeletable();
                objInfo.queryable = describeObj.isQueryable();
                objInfo.searchable = describeObj.isSearchable();
                objInfo.triggerable = null;
                objInfo.fields = obtenerCampos(describeObj);
                objInfo.childRelationships = obtenerRelacionesHijas(describeObj);

            } catch (Exception e) {
                objInfo.existe = false;
                objInfo.error = e.getTypeName() + ': ' + e.getMessage();
            }

            objetos.add(objInfo);
        }

        return objetos;
    }

    private static List<FieldInfo> obtenerCampos(Schema.DescribeSObjectResult describeObj) {

        List<FieldInfo> campos = new List<FieldInfo>();
        Map<String, Schema.SObjectField> fieldsMap = describeObj.fields.getMap();

        List<String> nombresCampos = new List<String>();
        nombresCampos.addAll(fieldsMap.keySet());
        nombresCampos.sort();

        for (String nombreCampo : nombresCampos) {

            Schema.DescribeFieldResult df = fieldsMap.get(nombreCampo).getDescribe();
            FieldInfo campo = new FieldInfo();

            campo.apiName = df.getName();
            campo.label = df.getLabel();
            campo.type = String.valueOf(df.getType());
            campo.length = df.getLength();
            campo.precision = df.getPrecision();
            campo.scale = df.getScale();
            campo.digits = df.getDigits();
            campo.nillable = df.isNillable();
            campo.createable = df.isCreateable();
            campo.updateable = df.isUpdateable();
            campo.calculated = df.isCalculated();
            campo.calculatedFormula = df.isCalculated() ? df.getCalculatedFormula() : null;
            campo.defaultedOnCreate = df.isDefaultedOnCreate();
            campo.unique = df.isUnique();
            campo.externalId = df.isExternalId();
            campo.idLookup = df.isIdLookup();
            campo.autoNumber = df.isAutoNumber();
            campo.nameField = df.isNameField();
            campo.relationshipName = df.getRelationshipName();
            campo.inlineHelpText = df.getInlineHelpText();

            campo.referenceTo = new List<String>();
            for (Schema.SObjectType refType : df.getReferenceTo()) {
                campo.referenceTo.add(String.valueOf(refType));
            }

            campo.picklistValues = new List<PicklistValueInfo>();
            if (
                df.getType() == Schema.DisplayType.Picklist ||
                df.getType() == Schema.DisplayType.MultiPicklist
            ) {
                for (Schema.PicklistEntry pe : df.getPicklistValues()) {
                    PicklistValueInfo pv = new PicklistValueInfo();
                    pv.label = pe.getLabel();
                    pv.value = pe.getValue();
                    pv.active = pe.isActive();
                    pv.defaultValue = pe.isDefaultValue();
                    campo.picklistValues.add(pv);
                }
            }

            campos.add(campo);
        }

        return campos;
    }

    private static List<ChildRelationshipInfo> obtenerRelacionesHijas(
        Schema.DescribeSObjectResult describeObj
    ) {
        List<ChildRelationshipInfo> relaciones = new List<ChildRelationshipInfo>();

        for (Schema.ChildRelationship cr : describeObj.getChildRelationships()) {
            ChildRelationshipInfo rel = new ChildRelationshipInfo();
            rel.childSObject = String.valueOf(cr.getChildSObject());
            rel.field = String.valueOf(cr.getField());
            rel.relationshipName = cr.getRelationshipName();
            rel.cascadeDelete = cr.isCascadeDelete();
            rel.restrictedDelete = cr.isRestrictedDelete();
            relaciones.add(rel);
        }

        return relaciones;
    }

    /*
     * =====================================================================================
     * RECORD TYPES Y JOBS PROGRAMADOS
     * =====================================================================================
     */

    private static Map<String, Object> obtenerRecordTypesSeguros(List<String> nombresObjetos) {
        Map<String, Object> resultado = new Map<String, Object>();
        resultado.put('seccion', 'Record Types');

        try {
            Set<String> objetosSet = new Set<String>(nombresObjetos);
            List<Object> registros = new List<Object>();

            for (RecordType rt : [
                SELECT Id, SobjectType, DeveloperName, Name, IsActive, Description
                FROM RecordType
                ORDER BY SobjectType, DeveloperName
            ]) {
                if (!objetosSet.contains(rt.SobjectType)) {
                    continue;
                }

                Map<String, Object> item = new Map<String, Object>();
                item.put('Id', rt.Id);
                item.put('SobjectType', rt.SobjectType);
                item.put('DeveloperName', rt.DeveloperName);
                item.put('Name', rt.Name);
                item.put('IsActive', rt.IsActive);
                item.put('Description', rt.Description);
                registros.add(item);
            }

            resultado.put('exito', true);
            resultado.put('totalRegistros', registros.size());
            resultado.put('registros', registros);

        } catch (Exception e) {
            resultado.put('exito', false);
            resultado.put('tipoError', e.getTypeName());
            resultado.put('mensajeError', e.getMessage());
        }

        return resultado;
    }

    private static Map<String, Object> obtenerTrabajosProgramadosSeguros() {
        Map<String, Object> resultado = new Map<String, Object>();
        resultado.put('seccion', 'Trabajos Programados');

        try {
            List<Object> registros = new List<Object>();

            for (CronTrigger ct : [
                SELECT Id, State, NextFireTime, PreviousFireTime, StartTime, EndTime,
                       CronExpression, CronJobDetail.Name, CronJobDetail.JobType
                FROM CronTrigger
                ORDER BY CronJobDetail.Name
            ]) {
                Map<String, Object> item = new Map<String, Object>();
                item.put('Id', ct.Id);
                item.put('State', ct.State);
                item.put('NextFireTime', String.valueOf(ct.NextFireTime));
                item.put('PreviousFireTime', String.valueOf(ct.PreviousFireTime));
                item.put('StartTime', String.valueOf(ct.StartTime));
                item.put('EndTime', String.valueOf(ct.EndTime));
                item.put('CronExpression', ct.CronExpression);
                item.put('Name', ct.CronJobDetail != null ? ct.CronJobDetail.Name : null);
                item.put('JobType', ct.CronJobDetail != null ? ct.CronJobDetail.JobType : null);
                registros.add(item);
            }

            resultado.put('exito', true);
            resultado.put('totalRegistros', registros.size());
            resultado.put('registros', registros);

        } catch (Exception e) {
            resultado.put('exito', false);
            resultado.put('tipoError', e.getTypeName());
            resultado.put('mensajeError', e.getMessage());
        }

        return resultado;
    }

    /*
     * =====================================================================================
     * APEX CLASSES Y TRIGGERS
     * =====================================================================================
     */

    private static Map<String, Object> obtenerClasesApexTodas(
        Boolean incluirBody,
        List<String> nombresObjetos
    ) {
        Map<String, Object> resultado = new Map<String, Object>();
        List<Map<String, Object>> errores = new List<Map<String, Object>>();

        List<Map<String, Object>> clases = obtenerRegistrosClasesApexTodas(
            incluirBody,
            nombresObjetos,
            errores
        );

        resultado.put('seccion', 'Clases Apex - Todas');
        resultado.put('exito', errores.isEmpty());
        resultado.put('incluyeBody', incluirBody == true);
        resultado.put('criterios', new List<String>{
            'Todas las clases Apex consultables por Tooling API',
            'Sin filtro por prefijo',
            'Sin WHERE Body LIKE',
            'Referencias a objetos detectadas en Apex después de consultar Body'
        });
        resultado.put('totalRegistros', clases.size());
        resultado.put('registros', clases);
        resultado.put('errores', errores);

        return resultado;
    }

    private static Map<String, Object> obtenerCodigoApexCompleto(
        Boolean incluirBody,
        List<String> nombresObjetos
    ) {
        Map<String, Object> resultado = new Map<String, Object>();
        List<Map<String, Object>> errores = new List<Map<String, Object>>();

        List<Map<String, Object>> clases = obtenerRegistrosClasesApexTodas(
            incluirBody,
            nombresObjetos,
            errores
        );

        List<Map<String, Object>> triggers = obtenerRegistrosTriggersApexTodos(
            incluirBody,
            nombresObjetos,
            errores
        );

        resultado.put('seccion', 'Código Apex Exportado - Completo');
        resultado.put('incluyeBody', incluirBody == true);
        resultado.put('totalClases', clases.size());
        resultado.put('totalTriggers', triggers.size());
        resultado.put('clases', clases);
        resultado.put('triggers', triggers);
        resultado.put('errores', errores);

        return resultado;
    }

    private static List<Map<String, Object>> obtenerRegistrosClasesApexTodas(
        Boolean incluirBody,
        List<String> nombresObjetos,
        List<Map<String, Object>> errores
    ) {
        Map<String, Map<String, Object>> clasesPorId =
            new Map<String, Map<String, Object>>();

        String campos = incluirBody == true
            ? 'Id, Name, NamespacePrefix, Status, ApiVersion, LengthWithoutComments, Body'
            : 'Id, Name, NamespacePrefix, Status, ApiVersion, LengthWithoutComments';

        agregarRegistrosDesdeTooling(
            'Todas las clases Apex',
            'SELECT ' + campos + ' FROM ApexClass ORDER BY Name',
            clasesPorId,
            errores
        );

        for (String claseId : clasesPorId.keySet()) {
            enriquecerRegistroConReferenciasAObjetos(
                clasesPorId.get(claseId),
                nombresObjetos
            );
        }

        return ordenarRegistrosPorNombre(clasesPorId);
    }

    private static List<Map<String, Object>> obtenerRegistrosTriggersApexTodos(
        Boolean incluirBody,
        List<String> nombresObjetos,
        List<Map<String, Object>> errores
    ) {
        Map<String, Map<String, Object>> triggersPorId =
            new Map<String, Map<String, Object>>();

        String campos = incluirBody == true
            ? 'Id, Name, TableEnumOrId, Status, ApiVersion, Body'
            : 'Id, Name, TableEnumOrId, Status, ApiVersion';

        agregarRegistrosDesdeTooling(
            'Todos los triggers Apex',
            'SELECT ' + campos + ' FROM ApexTrigger ORDER BY TableEnumOrId, Name',
            triggersPorId,
            errores
        );

        for (String triggerId : triggersPorId.keySet()) {
            enriquecerRegistroConReferenciasAObjetos(
                triggersPorId.get(triggerId),
                nombresObjetos
            );
        }

        return ordenarRegistrosPorNombre(triggersPorId);
    }

    private static void enriquecerRegistroConReferenciasAObjetos(
        Map<String, Object> registro,
        List<String> nombresObjetos
    ) {
        List<String> objetosReferenciados = new List<String>();

        String body = registro.containsKey('Body') && registro.get('Body') != null
            ? String.valueOf(registro.get('Body'))
            : '';

        if (!String.isBlank(body)) {
            for (String nombreObjeto : nombresObjetos) {
                if (String.isBlank(nombreObjeto)) {
                    continue;
                }

                if (body.contains(nombreObjeto)) {
                    objetosReferenciados.add(nombreObjeto);
                }
            }
        }

        objetosReferenciados.sort();
        registro.put('objetosReferenciados', objetosReferenciados);
        registro.put('relacionadoPorObjeto', !objetosReferenciados.isEmpty());
    }

    private static void agregarRegistrosDesdeTooling(
        String etiqueta,
        String soql,
        Map<String, Map<String, Object>> registrosPorId,
        List<Map<String, Object>> errores
    ) {
        try {
            List<Object> registros = toolingQuery(soql);

            for (Object registroObj : registros) {
                Map<String, Object> registro = (Map<String, Object>) registroObj;
                String idRegistro = String.valueOf(registro.get('Id'));

                if (!registrosPorId.containsKey(idRegistro)) {
                    registro.put('criterioDeteccion', etiqueta);
                    registrosPorId.put(idRegistro, registro);
                }
            }

        } catch (Exception e) {
            Map<String, Object> errorInfo = new Map<String, Object>();
            errorInfo.put('seccion', etiqueta);
            errorInfo.put('query', soql);
            errorInfo.put('tipoError', e.getTypeName());
            errorInfo.put('mensajeError', e.getMessage());
            errores.add(errorInfo);
        }
    }

    private static List<Map<String, Object>> ordenarRegistrosPorNombre(
        Map<String, Map<String, Object>> registrosPorId
    ) {
        Map<String, Map<String, Object>> porNombre = new Map<String, Map<String, Object>>();
        List<String> llaves = new List<String>();

        for (String registroId : registrosPorId.keySet()) {
            Map<String, Object> registro = registrosPorId.get(registroId);
            String nombre = registro.containsKey('Name') && registro.get('Name') != null
                ? String.valueOf(registro.get('Name'))
                : registroId;

            String llave = nombre + '|' + registroId;
            porNombre.put(llave, registro);
            llaves.add(llave);
        }

        llaves.sort();

        List<Map<String, Object>> salida = new List<Map<String, Object>>();
        for (String llave : llaves) {
            salida.add(porNombre.get(llave));
        }

        return salida;
    }

    /*
     * =====================================================================================
     * TOOLING API
     * =====================================================================================
     */

    private static Map<String, Object> ejecutarConsultaToolingSegura(
        String seccion,
        String soql
    ) {
        Map<String, Object> resultado = new Map<String, Object>();
        resultado.put('seccion', seccion);
        resultado.put('query', soql);

        try {
            List<Object> registros = toolingQuery(soql);
            resultado.put('exito', true);
            resultado.put('totalRegistros', registros.size());
            resultado.put('registros', registros);

        } catch (Exception e) {
            resultado.put('exito', false);
            resultado.put('tipoError', e.getTypeName());
            resultado.put('mensajeError', e.getMessage());
        }

        return resultado;
    }

    private static List<Object> toolingQuery(String soql) {

        List<Object> registros = new List<Object>();

        String endpoint =
            URL.getOrgDomainUrl().toExternalForm() +
            '/services/data/' +
            API_VERSION +
            '/tooling/query/?q=' +
            EncodingUtil.urlEncode(soql, 'UTF-8');

        while (endpoint != null) {

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
                throw new CalloutException(
                    'Error Tooling API. Status: ' +
                    res.getStatusCode() +
                    ' Query: ' +
                    soql +
                    ' Body: ' +
                    res.getBody()
                );
            }

            Map<String, Object> respuesta =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            if (respuesta.containsKey('records')) {
                registros.addAll((List<Object>) respuesta.get('records'));
            }

            Boolean done = (Boolean) respuesta.get('done');

            if (done == true) {
                endpoint = null;
            } else {
                String nextRecordsUrl = (String) respuesta.get('nextRecordsUrl');
                endpoint = URL.getOrgDomainUrl().toExternalForm() + nextRecordsUrl;
            }
        }

        return registros;
    }

    /*
     * =====================================================================================
     * ARCHIVOS
     * =====================================================================================
     */

    private static Id crearArchivo(
        String titulo,
        String pathOnClient,
        String contenido
    ) {
        ContentVersion archivo = new ContentVersion();
        archivo.Title = titulo;
        archivo.PathOnClient = pathOnClient;
        archivo.VersionData = Blob.valueOf(contenido);
        insert archivo;
        return archivo.Id;
    }

    /*
     * =====================================================================================
     * DTOs
     * =====================================================================================
     */

    public class ObjectInfo {
        public String apiName;
        public Boolean existe;
        public String error;
        public String label;
        public String labelPlural;
        public String keyPrefix;
        public Boolean custom;
        public Boolean createable;
        public Boolean updateable;
        public Boolean deletable;
        public Boolean queryable;
        public Boolean searchable;
        public Boolean triggerable;
        public List<FieldInfo> fields;
        public List<ChildRelationshipInfo> childRelationships;
    }

    public class FieldInfo {
        public String apiName;
        public String label;
        public String type;
        public Integer length;
        public Integer precision;
        public Integer scale;
        public Integer digits;
        public Boolean nillable;
        public Boolean createable;
        public Boolean updateable;
        public Boolean calculated;
        public String calculatedFormula;
        public Boolean defaultedOnCreate;
        public Boolean unique;
        public Boolean externalId;
        public Boolean idLookup;
        public Boolean autoNumber;
        public Boolean nameField;
        public String relationshipName;
        public String inlineHelpText;
        public List<String> referenceTo;
        public List<PicklistValueInfo> picklistValues;
    }

    public class PicklistValueInfo {
        public String label;
        public String value;
        public Boolean active;
        public Boolean defaultValue;
    }

    public class ChildRelationshipInfo {
        public String childSObject;
        public String field;
        public String relationshipName;
        public Boolean cascadeDelete;
        public Boolean restrictedDelete;
    }
}