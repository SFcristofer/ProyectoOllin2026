public with sharing class TechVentasSelector {

    // ── Whitelists para filtros dinámicos ─────────────────────────────────────

    private static final Map<String, String> LEAD_FIELD_MAP = new Map<String, String>{
        'name'       => 'Name',
        'company'    => 'Company',
        'status'     => 'Status',
        'tipoSeguro' => 'Tipo_de_seguro__c',
        'score'      => 'Score__c',
        'rating'     => 'Rating',
        'leadSource' => 'LeadSource',
        'createdDate'=> 'CreatedDate'
    };
    private static final Set<String> LEAD_NUM_FIELDS  = new Set<String>{ 'score' };
    private static final Set<String> LEAD_DATE_FIELDS = new Set<String>{ 'createdDate' };
    private static final Set<String> LEAD_TEXT_FIELDS = new Set<String>{ 'name', 'company' };

    private static final Map<String, String> OPP_FIELD_MAP = new Map<String, String>{
        'name'        => 'Name',
        'accountName' => 'Account.Name',
        'ramo'        => 'Ramo__c',
        'stageName'   => 'StageName',
        'amount'      => 'Amount',
        'closeDate'   => 'CloseDate',
        'metodoPago'  => 'Metodo_Pago__c',
        'periodoPago' => 'Periodo_Pago__c',
        'vigencia'    => 'Vigencia__c'
    };
    private static final Set<String> OPP_NUM_FIELDS  = new Set<String>{ 'amount', 'vigencia' };
    private static final Set<String> OPP_DATE_FIELDS = new Set<String>{ 'closeDate' };
    private static final Set<String> OPP_TEXT_FIELDS = new Set<String>{ 'name', 'accountName' };

    // ─────────────────────────────────────────────────────────────────────────

    public static List<Lead> getLeads(String filtersJson) {
        List<String> conditions = new List<String>{ 'IsConverted = false' };
        conditions.addAll(parseFilters(filtersJson, LEAD_FIELD_MAP, LEAD_NUM_FIELDS, LEAD_DATE_FIELDS, LEAD_TEXT_FIELDS));
        String whereClause = String.join(conditions, ' AND ');

        String soql =
            'SELECT Id, Name, FirstName, LastName, LeadSource, Status, Score__c, '
          + 'Email, Phone, MobilePhone, Company, Title, '
          + 'Tipo_de_seguro__c, Monto__c, Aportacion_Estimada__c, '
          + 'Suma_asegurada__c, Presupuesto__c, '
          + 'Genero__c, Sexo__c, Fecha_de_nacimiento__c, Edad_Calculada__c, Fuma__c, '
          + 'RFC__c, CURP__c, CP__c, '
          + 'Rating, Industry, '
          + 'Regimenes_Fiscales__c, tipos_de_contribuyentes__c, '
          + 'NumeroProspecto__c, '
          + 'Aseguradora__c, Aseguradora__r.Name, '
          + 'Tech_Vendedor__c, Tech_Vendedor__r.Name, Tech_Vendedor__r.Name__c, '
          + 'Marca__c, Modelo__c, Anho__c, Version__c, '
          + 'Uso__c, Tipo_de_cobertura__c, '
          + 'ObjetivoPlan__c, Plazo_Plan__c, '
          + 'PadecimientosExistentes__c, HospitalesReferencias__c, '
          + 'TipoFianza__c, Porcentaje_de_afianzar__c, Monto_del_contrato__c, '
          + 'Contrato__c, '
          + 'Motivo_No_Calificacion__c, Puede_Reactivarse__c, '
          + 'Quote_ID_Externo__c, Giro_Actividad__c, '
          + 'Ubicacion_Riesgo__c, Documento_Fuente_Recibido__c, '
          + 'RecordTypeId, RecordType.DeveloperName, '
          + 'CreatedDate, OwnerId, Owner.Name '
          + 'FROM Lead '
          + 'WHERE ' + whereClause + ' '
          + 'ORDER BY CreatedDate DESC '
          + 'LIMIT 300';
        return Database.query(soql);
    }

    public static List<Opportunity> getOportunidades(String filtersJson) {
        List<String> conditions = parseFilters(filtersJson, OPP_FIELD_MAP, OPP_NUM_FIELDS, OPP_DATE_FIELDS, OPP_TEXT_FIELDS);
        String whereStr = conditions.isEmpty() ? '' : 'WHERE ' + String.join(conditions, ' AND ');

        String soql =
            'SELECT Id, Name, StageName, Amount, CloseDate, '
          + 'AccountId, Account.Name, '
          + 'Ramo__c, Subproducto__c, '
          + 'Tipo_Originador__c, Type, LeadSource, Probability, '
          + 'Vendedor_A__c, Vendedor_A__r.Name, Vendedor_A__r.Name__c, '
          + 'Loss_Reason__c, Motivo_Perdida__c, Aseguradora_Competidora__c, '
          + 'Notas_Vendedor__c, Puede_Reactivarse__c, Description, NextStep, '
          + 'Producto__c, Producto__r.Name, '
          + 'Institucion__c, Institucion__r.Name, '
          + 'Metodo_Pago__c, Periodo_Pago__c, '
          + 'Fecha_Inicio_Vigencia__c, Fecha_Fin_Vigencia__c, Vigencia__c, Numero_Pagos__c, '
          + 'Vigencia_Inicio__c, Vigencia_Fin__c, '
          + 'Poliza_Renovar__c, Poliza_Renovar__r.Numero_poliza__c, Poliza_Renovar__r.Name, '
          + 'URL_Poliza__c, '
          + 'Cotizacion_Externa_Id__c, Ano_vehiculo__c, Modelo__c, '
          + 'Contratista__c, Contratista__r.Name, Contratista__r.PersonEmail, '
          + 'Beneficiario__c, Beneficiario__r.Name, Beneficiario__r.PersonEmail, '
          + 'PctComisionOllin__c, '
          + 'Prospecto__c, Prospecto__r.Name, '
          + 'RecordTypeId, RecordType.DeveloperName, '
          + 'CreatedDate '
          + 'FROM Opportunity '
          + whereStr + ' '
          + 'ORDER BY CreatedDate DESC '
          + 'LIMIT 500';
        return Database.query(soql);
    }

    public static List<Account> getClientes() {
        return [
            SELECT Id, Name, FirstName, LastName,
                   PersonEmail, Phone, BillingCity,
                   RecordType.Name, RecordType.DeveloperName,
                   Vendedor__c, Vendedor__r.Name,
                   CreatedDate,
                   (SELECT Id FROM Opportunities ORDER BY CreatedDate DESC LIMIT 500)
            FROM Account
            WHERE IsPersonAccount = true
               OR RecordType.DeveloperName IN ('Contratista', 'Beneficiario', 'Cuenta_negocio')
            ORDER BY CreatedDate DESC
            LIMIT 500
        ];
    }

    public static AggregateResult[] getLeadKPIs() {
        return [
            SELECT Status, COUNT(Id) total
            FROM Lead
            WHERE IsConverted = false
            GROUP BY Status
        ];
    }

    public static AggregateResult[] getOppKPIs() {
        return [
            SELECT StageName, COUNT(Id) total, SUM(Amount) monto
            FROM Opportunity
            WHERE CloseDate = THIS_YEAR
            GROUP BY StageName
        ];
    }

    // ── Construcción dinámica de WHERE ────────────────────────────────────────

    private static List<String> parseFilters(
        String filtersJson,
        Map<String, String> fieldMap,
        Set<String> numFields,
        Set<String> dateFields,
        Set<String> textFields
    ) {
        List<String> conditions = new List<String>();
        if (String.isBlank(filtersJson)) return conditions;

        List<Object> rawList;
        try {
            rawList = (List<Object>) JSON.deserializeUntyped(filtersJson);
        } catch (Exception ex) {
            return conditions;
        }

        for (Object rawItem : rawList) {
            try {
                Map<String, Object> rule = (Map<String, Object>) rawItem;
                String field = (String) rule.get('field');
                String op    = (String) rule.get('op');
                String value = (String) rule.get('value');

                if (!fieldMap.containsKey(field) || String.isBlank(value) || String.isBlank(op)) continue;

                String soqlField = fieldMap.get(field);
                String cond = buildCondition(
                    soqlField, op, value,
                    numFields.contains(field),
                    dateFields.contains(field),
                    textFields.contains(field)
                );
                if (cond != null) conditions.add(cond);
            } catch (Exception ex) { /* skip malformed rule */ }
        }
        return conditions;
    }

    private static String buildCondition(
        String soqlField, String op, String value,
        Boolean isNum, Boolean isDate, Boolean isText
    ) {
        if (isNum) {
            Decimal numVal;
            try { numVal = Decimal.valueOf(value); } catch (Exception ex) { return null; }
            String n = String.valueOf(numVal);
            if (op == 'eq')  return soqlField + ' = '  + n;
            if (op == 'ne')  return soqlField + ' != ' + n;
            if (op == 'gt')  return soqlField + ' > '  + n;
            if (op == 'lt')  return soqlField + ' < '  + n;
            if (op == 'gte') return soqlField + ' >= ' + n;
            if (op == 'lte') return soqlField + ' <= ' + n;
        } else if (isDate) {
            Date dateVal;
            try { dateVal = Date.valueOf(value); } catch (Exception ex) { return null; }
            String d = String.valueOf(dateVal);
            if (op == 'eq')  return soqlField + ' = '  + d;
            if (op == 'gt')  return soqlField + ' > '  + d;
            if (op == 'lt')  return soqlField + ' < '  + d;
            if (op == 'gte') return soqlField + ' >= ' + d;
            if (op == 'lte') return soqlField + ' <= ' + d;
        } else if (isText) {
            String safe = String.escapeSingleQuotes(value);
            if (op == 'contains') return soqlField + ' LIKE \'%' + safe + '%\'';
            if (op == 'eq')       return soqlField + ' = \'' + safe + '\'';
            if (op == 'ne')       return soqlField + ' != \'' + safe + '\'';
        } else {
            // picklist / stage
            String safe = String.escapeSingleQuotes(value);
            if (op == 'eq') return soqlField + ' = \'' + safe + '\'';
            if (op == 'ne') return soqlField + ' != \'' + safe + '\'';
        }
        return null;
    }
}