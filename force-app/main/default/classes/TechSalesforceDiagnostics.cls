public without sharing class TechSalesforceDiagnostics {

    // ============================================================
    // CONFIGURACIÓN
    // ============================================================

    public class Config {
		
        public Boolean includeStandardObjects = false;
        public Boolean includePicklistValues = true;
        public Boolean includeRecordTypes = true;
        public Boolean includeChildRelationships = true;
        public Boolean includeChildRelationshipsForStandardObjects = false;        
        public Boolean includeApexBodyAnalysis = true;

        public Integer maxObjects = 180;
        public Integer maxFieldsPerObject = 350;
        public Integer maxChildRelationshipsPerObject = 120;
        public Integer maxRecordTypesPerObject = 50;

        public Integer maxApexClasses = 300;
        public Integer maxApexTriggers = 300;
        public Integer maxFlows = 300;

        public Integer maxFieldTokensForAnalysis = 3000;
        public Integer maxMethodsPerApexUnit = 80;
        public Integer maxObjectRefsPerApexUnit = 80;
        public Integer maxFieldRefsPerApexUnit = 120;

        public Integer outputChunkSize = 15000;
    }

    private class AnalysisCatalog {
        public List<String> objectTokens = new List<String>();
        public Map<String, List<String>> fieldTokenToPossibleFields = new Map<String, List<String>>();
    }

    private class DiagLogger {
        private String buffer = '';
        private Integer chunkSize;

        public DiagLogger(Integer chunkSizeParam) {
            chunkSize = chunkSizeParam == null ? 15000 : chunkSizeParam;
        }

        public void line(String value) {
            if (value == null) {
                value = '';
            }

            buffer += value + '\n';

            if (buffer.length() >= chunkSize) {
                flush();
            }
        }

        public void flush() {
            if (String.isNotBlank(buffer)) {
                System.debug(LoggingLevel.ERROR, buffer);
                buffer = '';
            }
        }
    }

    // ============================================================
    // MÉTODOS PÚBLICOS
    // ============================================================

    public static void run() {
        run(new Config());
    }

    public static void run(Config cfg) {
        if (cfg == null) {
            cfg = new Config();
        }

        DiagLogger log = new DiagLogger(cfg.outputChunkSize);

        log.line('SF_DIAG|START|Salesforce diagnostic started at GMT=' + DateTime.now().formatGmt('yyyy-MM-dd HH:mm:ss'));
        log.line('SF_DIAG|INFO|Class=TechSalesforceDiagnostics');
        log.line('SF_DIAG|INFO|Mode=ReadOnly');

        try {
            sectionOrgInfo(log);
            AnalysisCatalog catalog = sectionObjectsFieldsRelationships(cfg, log);
            sectionApexClasses(cfg, log, catalog);
            sectionApexTriggers(cfg, log, catalog);
            sectionFlows(cfg, log);
            sectionOtherAutomationsAndRules(log);
        } catch (Exception e) {
            log.line('SF_DIAG|FATAL_ERROR|Message=' + clean(e.getMessage()));
            log.line('SF_DIAG|FATAL_ERROR|StackTrace=' + clean(e.getStackTraceString()));
        }

        log.line('SF_DIAG|END|Salesforce diagnostic finished at GMT=' + DateTime.now().formatGmt('yyyy-MM-dd HH:mm:ss'));
        log.flush();
    }

    // ============================================================
    // SECCIÓN: ORG INFO
    // ============================================================

    private static void sectionOrgInfo(DiagLogger log) {
        log.line('SF_DIAG|SECTION|ORG_INFO');

        log.line(
            'SF_DIAG|USER'
            + '|UserId=' + UserInfo.getUserId()
            + '|UserName=' + clean(UserInfo.getUserName())
            + '|ProfileId=' + UserInfo.getProfileId()
            + '|OrgId=' + UserInfo.getOrganizationId()
        );

        try {
            List<SObject> orgRows = Database.query(
                'SELECT Id, Name, OrganizationType, InstanceName, IsSandbox ' +
                'FROM Organization ' +
                'LIMIT 1'
            );

            if (!orgRows.isEmpty()) {
                SObject orgInfo = orgRows[0];

                log.line(
                    'SF_DIAG|ORG'
                    + '|Id=' + valueOf(orgInfo, 'Id')
                    + '|Name=' + valueOf(orgInfo, 'Name')
                    + '|OrganizationType=' + valueOf(orgInfo, 'OrganizationType')
                    + '|InstanceName=' + valueOf(orgInfo, 'InstanceName')
                    + '|IsSandbox=' + valueOf(orgInfo, 'IsSandbox')
                );
            }
        } catch (Exception e) {
            log.line('SF_DIAG|ORG_INFO_ERROR|Message=' + clean(e.getMessage()));
        }
    }

    // ============================================================
    // SECCIÓN: OBJETOS, CAMPOS Y RELACIONES
    // ============================================================

    private static AnalysisCatalog sectionObjectsFieldsRelationships(Config cfg, DiagLogger log) {
        log.line('SF_DIAG|SECTION|OBJECTS_FIELDS_RELATIONSHIPS');

        AnalysisCatalog catalog = new AnalysisCatalog();

        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

        List<String> objectNames = new List<String>();
        objectNames.addAll(globalDescribe.keySet());
        objectNames.sort();

        Set<String> standardObjects = defaultStandardObjectsToInclude();
        Set<String> standardFields = standardFieldsToAnalyze();

        Integer objectCounter = 0;
        Integer fieldTokenCounter = 0;

        log.line(
            'SF_DIAG|CONFIG'
            + '|includeStandardObjects=' + cfg.includeStandardObjects
            + '|includePicklistValues=' + cfg.includePicklistValues
            + '|includeRecordTypes=' + cfg.includeRecordTypes
            + '|includeChildRelationships=' + cfg.includeChildRelationships
            + '|includeApexBodyAnalysis=' + cfg.includeApexBodyAnalysis
            + '|maxObjects=' + cfg.maxObjects
            + '|maxFieldsPerObject=' + cfg.maxFieldsPerObject
        );

        for (String objectApiName : objectNames) {
            if (objectCounter >= cfg.maxObjects) {
                log.line('SF_DIAG|OBJECT_LIMIT_REACHED|maxObjects=' + cfg.maxObjects);
                break;
            }

            if (shouldSkipEntity(objectApiName)) {
                log.line(
                    'SF_DIAG|OBJECT_SKIPPED_NO_ACCESS_OR_INTERNAL'
                    + '|Object=' + clean(objectApiName)
                );
                continue;
            }

            try {
                Schema.SObjectType sObjType = globalDescribe.get(objectApiName);

                if (sObjType == null) {
                    log.line(
                        'SF_DIAG|OBJECT_SKIPPED_NULL_TOKEN'
                        + '|Object=' + clean(objectApiName)
                    );
                    continue;
                }

                Schema.DescribeSObjectResult objDescribe;

                try {
                    objDescribe = sObjType.getDescribe();
                } catch (Exception describeEx) {
                    log.line(
                        'SF_DIAG|OBJECT_SKIPPED_DESCRIBE_DENIED'
                        + '|Object=' + clean(objectApiName)
                        + '|Message=' + clean(describeEx.getMessage())
                    );
                    continue;
                }

                Boolean isCustomLike =
                    objDescribe.isCustom()
                    || objectApiName.endsWith('__c')
                    || objectApiName.endsWith('__mdt')
                    || objectApiName.endsWith('__e')
                    || objectApiName.endsWith('__x');

                Boolean includeObject =
                    cfg.includeStandardObjects
                    || isCustomLike
                    || standardObjects.contains(objectApiName);

                if (!includeObject) {
                    continue;
                }

                objectCounter++;
                catalog.objectTokens.add(objectApiName);

                log.line(
                    'SF_DIAG|OBJECT'
                    + '|ApiName=' + objectApiName
                    + '|Label=' + clean(objDescribe.getLabel())
                    + '|LabelPlural=' + clean(objDescribe.getLabelPlural())
                    + '|KeyPrefix=' + String.valueOf(objDescribe.getKeyPrefix())
                    + '|IsCustom=' + objDescribe.isCustom()
                    + '|IsQueryable=' + objDescribe.isQueryable()
                    + '|IsCreateable=' + objDescribe.isCreateable()
                    + '|IsUpdateable=' + objDescribe.isUpdateable()
                    + '|IsDeletable=' + objDescribe.isDeletable()
                    + '|IsSearchable=' + objDescribe.isSearchable()
                    + '|IsDeprecatedAndHidden=' + objDescribe.isDeprecatedAndHidden()
                );

                if (cfg.includeRecordTypes) {
                    describeRecordTypes(cfg, log, objectApiName, objDescribe);
                }

                Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

                List<String> fieldNames = new List<String>();
                fieldNames.addAll(fieldMap.keySet());
                fieldNames.sort();

                Integer fieldCounter = 0;

                for (String fieldApiName : fieldNames) {
                    if (fieldCounter >= cfg.maxFieldsPerObject) {
                        log.line(
                            'SF_DIAG|FIELD_LIMIT_REACHED'
                            + '|Object=' + objectApiName
                            + '|maxFieldsPerObject=' + cfg.maxFieldsPerObject
                        );
                        break;
                    }

                    fieldCounter++;

                    Schema.DescribeFieldResult fieldDescribe;

                    try {
                        fieldDescribe = fieldMap.get(fieldApiName).getDescribe();
                    } catch (Exception fieldDescribeEx) {
                        log.line(
                            'SF_DIAG|FIELD_SKIPPED_DESCRIBE_DENIED'
                            + '|Object=' + clean(objectApiName)
                            + '|Field=' + clean(fieldApiName)
                            + '|Message=' + clean(fieldDescribeEx.getMessage())
                        );
                        continue;
                    }

                    String formula = '';
                    if (fieldDescribe.isCalculated()) {
                        try {
                            formula = fieldDescribe.getCalculatedFormula();
                        } catch (Exception formulaEx) {
                            formula = 'FORMULA_NOT_AVAILABLE';
                        }
                    }

                    List<String> referenceTo = new List<String>();
                    try {
                        for (Schema.SObjectType refType : fieldDescribe.getReferenceTo()) {
                            String refName = String.valueOf(refType);
                            if (!shouldSkipEntity(refName)) {
                                referenceTo.add(refName);
                            }
                        }
                    } catch (Exception refEx) {
                        // Sin referencias disponibles.
                    }

                    String line =
                        'SF_DIAG|FIELD'
                        + '|Object=' + objectApiName
                        + '|ApiName=' + fieldApiName
                        + '|Label=' + clean(fieldDescribe.getLabel())
                        + '|Type=' + String.valueOf(fieldDescribe.getType())
                        + '|Length=' + fieldDescribe.getLength()
                        + '|Precision=' + fieldDescribe.getPrecision()
                        + '|Scale=' + fieldDescribe.getScale()
                        + '|IsNillable=' + fieldDescribe.isNillable()
                        + '|IsRequired=' + String.valueOf(!fieldDescribe.isNillable())
                        + '|IsCreateable=' + fieldDescribe.isCreateable()
                        + '|IsUpdateable=' + fieldDescribe.isUpdateable()
                        + '|IsUnique=' + fieldDescribe.isUnique()
                        + '|IsExternalId=' + fieldDescribe.isExternalId()
                        + '|IsCalculated=' + fieldDescribe.isCalculated()
                        + '|IsAutoNumber=' + fieldDescribe.isAutoNumber()
                        + '|IsDefaultedOnCreate=' + fieldDescribe.isDefaultedOnCreate()
                        + '|RelationshipName=' + clean(fieldDescribe.getRelationshipName());

                    if (!referenceTo.isEmpty()) {
                        line += '|ReferenceTo=' + clean(String.join(referenceTo, ','));
                    }

                    if (String.isNotBlank(formula)) {
                        line += '|Formula=' + clean(formula);
                    }

                    String helpText = fieldDescribe.getInlineHelpText();
                    if (String.isNotBlank(helpText)) {
                        line += '|HelpText=' + clean(helpText);
                    }

                    log.line(line);

                    Boolean shouldAnalyzeFieldToken =
                        fieldApiName.endsWith('__c')
                        || fieldApiName.endsWith('__pc')
                        || standardFields.contains(fieldApiName);

                    if (
                        cfg.includeApexBodyAnalysis
                        && shouldAnalyzeFieldToken
                        && fieldTokenCounter < cfg.maxFieldTokensForAnalysis
                    ) {
                        if (!catalog.fieldTokenToPossibleFields.containsKey(fieldApiName)) {
                            catalog.fieldTokenToPossibleFields.put(fieldApiName, new List<String>());
                            fieldTokenCounter++;
                        }

                        catalog.fieldTokenToPossibleFields.get(fieldApiName).add(objectApiName + '.' + fieldApiName);
                    }

                    if (
                        cfg.includePicklistValues
                        && (
                            fieldDescribe.getType() == Schema.DisplayType.Picklist
                            || fieldDescribe.getType() == Schema.DisplayType.MultiPicklist
                        )
                    ) {
                        describePicklistValues(log, objectApiName, fieldApiName, fieldDescribe);
                    }
                }

                Boolean canScanChildRelationships =
                    cfg.includeChildRelationships
                    && (
                        isCustomLike
                        || cfg.includeChildRelationshipsForStandardObjects
                    );
                
                if (canScanChildRelationships) {
                    describeChildRelationships(cfg, log, objectApiName, objDescribe);
                } else if (cfg.includeChildRelationships && !isCustomLike) {
                    log.line(
                        'SF_DIAG|CHILD_RELATIONSHIPS_SKIPPED_FOR_STANDARD_OBJECT'
                        + '|ParentObject=' + clean(objectApiName)
                        + '|Reason=Standard object child relationships may include restricted internal Salesforce entities'
                    );
                }
                
                

            } catch (Exception e) {
                log.line(
                    'SF_DIAG|OBJECT_ERROR'
                    + '|Object=' + clean(objectApiName)
                    + '|Message=' + clean(e.getMessage())
                );
            }
        }

        log.line(
            'SF_DIAG|SUMMARY'
            + '|ObjectsAnalyzed=' + objectCounter
            + '|FieldTokensForApexAnalysis=' + catalog.fieldTokenToPossibleFields.size()
        );

        return catalog;
    }

    private static void describeRecordTypes(
        Config cfg,
        DiagLogger log,
        String objectApiName,
        Schema.DescribeSObjectResult objDescribe
    ) {
        try {
            Integer rtCounter = 0;

            for (Schema.RecordTypeInfo rtInfo : objDescribe.getRecordTypeInfos()) {
                if (rtCounter >= cfg.maxRecordTypesPerObject) {
                    log.line('SF_DIAG|RECORD_TYPE_LIMIT_REACHED|Object=' + clean(objectApiName));
                    break;
                }

                rtCounter++;

                log.line(
                    'SF_DIAG|RECORD_TYPE'
                    + '|Object=' + clean(objectApiName)
                    + '|Name=' + clean(rtInfo.getName())
                    + '|DeveloperName=' + clean(rtInfo.getDeveloperName())
                    + '|RecordTypeId=' + String.valueOf(rtInfo.getRecordTypeId())
                    + '|IsActive=' + rtInfo.isActive()
                    + '|IsAvailable=' + rtInfo.isAvailable()
                    + '|IsDefaultMapping=' + rtInfo.isDefaultRecordTypeMapping()
                    + '|IsMaster=' + rtInfo.isMaster()
                );
            }
        } catch (Exception e) {
            log.line(
                'SF_DIAG|RECORD_TYPE_ERROR'
                + '|Object=' + clean(objectApiName)
                + '|Message=' + clean(e.getMessage())
            );
        }
    }

    private static void describePicklistValues(
        DiagLogger log,
        String objectApiName,
        String fieldApiName,
        Schema.DescribeFieldResult fieldDescribe
    ) {
        try {
            for (Schema.PicklistEntry pe : fieldDescribe.getPicklistValues()) {
                log.line(
                    'SF_DIAG|PICKLIST_VALUE'
                    + '|Object=' + clean(objectApiName)
                    + '|Field=' + clean(fieldApiName)
                    + '|Value=' + clean(pe.getValue())
                    + '|Label=' + clean(pe.getLabel())
                    + '|IsActive=' + pe.isActive()
                    + '|IsDefault=' + pe.isDefaultValue()
                );
            }
        } catch (Exception e) {
            log.line(
                'SF_DIAG|PICKLIST_ERROR'
                + '|Object=' + clean(objectApiName)
                + '|Field=' + clean(fieldApiName)
                + '|Message=' + clean(e.getMessage())
            );
        }
    }

    private static void describeChildRelationships(
        Config cfg,
        DiagLogger log,
        String objectApiName,
        Schema.DescribeSObjectResult objDescribe
    ) {
        try {
            Integer childCounter = 0;

            List<Schema.ChildRelationship> childRelationships;

            try {
                childRelationships = objDescribe.getChildRelationships();
            } catch (Exception e) {
                log.line(
                    'SF_DIAG|CHILD_RELATIONSHIPS_SKIPPED'
                    + '|ParentObject=' + clean(objectApiName)
                    + '|Message=' + clean(e.getMessage())
                );
                return;
            }

            for (Schema.ChildRelationship childRel : childRelationships) {
                if (childCounter >= cfg.maxChildRelationshipsPerObject) {
                    log.line('SF_DIAG|CHILD_RELATIONSHIP_LIMIT_REACHED|ParentObject=' + clean(objectApiName));
                    break;
                }

                String childObjectName = safeChildObjectName(childRel);

                if (
                    childObjectName == 'ACCESS_DENIED_CHILD_OBJECT'
                    || shouldSkipEntity(childObjectName)
                ) {
                    log.line(
                        'SF_DIAG|CHILD_RELATIONSHIP_SKIPPED_NO_ACCESS_OR_INTERNAL'
                        + '|ParentObject=' + clean(objectApiName)
                        + '|ChildObject=' + clean(childObjectName)
                    );
                    continue;
                }

                childCounter++;

                String childFieldName = safeChildFieldName(childRel);
                String relationshipName = safeChildRelationshipName(childRel);

                Boolean isCascadeDelete = false;
                Boolean isDeprecatedAndHidden = false;

                try {
                    isCascadeDelete = childRel.isCascadeDelete();
                } catch (Exception e1) {
                    isCascadeDelete = false;
                }

                try {
                    isDeprecatedAndHidden = childRel.isDeprecatedAndHidden();
                } catch (Exception e2) {
                    isDeprecatedAndHidden = false;
                }

                log.line(
                    'SF_DIAG|CHILD_RELATIONSHIP'
                    + '|ParentObject=' + clean(objectApiName)
                    + '|ChildObject=' + clean(childObjectName)
                    + '|Field=' + clean(childFieldName)
                    + '|RelationshipName=' + clean(relationshipName)
                    + '|IsCascadeDelete=' + String.valueOf(isCascadeDelete)
                    + '|IsDeprecatedAndHidden=' + String.valueOf(isDeprecatedAndHidden)
                );
            }
        } catch (Exception e) {
            log.line(
                'SF_DIAG|CHILD_RELATIONSHIP_ERROR'
                + '|Object=' + clean(objectApiName)
                + '|Message=' + clean(e.getMessage())
            );
        }
    }

    // ============================================================
    // SECCIÓN: APEX CLASSES
    // ============================================================

    private static void sectionApexClasses(Config cfg, DiagLogger log, AnalysisCatalog catalog) {
        log.line('SF_DIAG|SECTION|APEX_CLASSES');

        List<SObject> apexClasses = new List<SObject>();
        Boolean bodyAvailable = false;

        try {
            apexClasses = Database.query(
                'SELECT Id, Name, NamespacePrefix, Status, ApiVersion, Body, CreatedDate, LastModifiedDate ' +
                'FROM ApexClass ' +
                'ORDER BY Name ' +
                'LIMIT ' + cfg.maxApexClasses
            );
            bodyAvailable = true;
        } catch (Exception e1) {
            log.line('SF_DIAG|APEX_CLASS_BODY_WARNING|Message=' + clean(e1.getMessage()));

            try {
                apexClasses = Database.query(
                    'SELECT Id, Name, NamespacePrefix, Status, ApiVersion, CreatedDate, LastModifiedDate ' +
                    'FROM ApexClass ' +
                    'ORDER BY Name ' +
                    'LIMIT ' + cfg.maxApexClasses
                );
                bodyAvailable = false;
            } catch (Exception e2) {
                log.line('SF_DIAG|APEX_CLASS_ERROR|Message=' + clean(e2.getMessage()));
                return;
            }
        }

        for (SObject cls : apexClasses) {
            String className = valueOf(cls, 'Name');

            log.line(
                'SF_DIAG|APEX_CLASS'
                + '|Name=' + clean(className)
                + '|NamespacePrefix=' + valueOf(cls, 'NamespacePrefix')
                + '|Status=' + valueOf(cls, 'Status')
                + '|ApiVersion=' + valueOf(cls, 'ApiVersion')
                + '|CreatedDate=' + valueOf(cls, 'CreatedDate')
                + '|LastModifiedDate=' + valueOf(cls, 'LastModifiedDate')
                + '|BodyAvailable=' + bodyAvailable
            );

            if (cfg.includeApexBodyAnalysis && bodyAvailable) {
                analyzeApexBody(
                    cfg,
                    log,
                    catalog,
                    'Class',
                    className,
                    getOptionalField(cls, 'Body')
                );
            }
        }

        log.line(
            'SF_DIAG|SUMMARY'
            + '|ApexClassesAnalyzed=' + apexClasses.size()
            + '|ClassBodyAvailable=' + bodyAvailable
        );
    }

    // ============================================================
    // SECCIÓN: APEX TRIGGERS
    // ============================================================

    private static void sectionApexTriggers(Config cfg, DiagLogger log, AnalysisCatalog catalog) {
        log.line('SF_DIAG|SECTION|APEX_TRIGGERS');

        List<SObject> apexTriggers = new List<SObject>();
        Boolean bodyAvailable = false;

        try {
            apexTriggers = Database.query(
                'SELECT Id, Name, TableEnumOrId, Status, ApiVersion, Body, CreatedDate, LastModifiedDate ' +
                'FROM ApexTrigger ' +
                'ORDER BY Name ' +
                'LIMIT ' + cfg.maxApexTriggers
            );
            bodyAvailable = true;
        } catch (Exception e1) {
            log.line('SF_DIAG|APEX_TRIGGER_BODY_WARNING|Message=' + clean(e1.getMessage()));

            try {
                apexTriggers = Database.query(
                    'SELECT Id, Name, Status, ApiVersion, CreatedDate, LastModifiedDate ' +
                    'FROM ApexTrigger ' +
                    'ORDER BY Name ' +
                    'LIMIT ' + cfg.maxApexTriggers
                );
                bodyAvailable = false;
            } catch (Exception e2) {
                log.line('SF_DIAG|APEX_TRIGGER_ERROR|Message=' + clean(e2.getMessage()));
                return;
            }
        }

        for (SObject trg : apexTriggers) {
            String triggerName = valueOf(trg, 'Name');
            String body = getOptionalField(trg, 'Body');

            log.line(
                'SF_DIAG|APEX_TRIGGER'
                + '|Name=' + clean(triggerName)
                + '|Object=' + getOptionalField(trg, 'TableEnumOrId')
                + '|Status=' + valueOf(trg, 'Status')
                + '|ApiVersion=' + valueOf(trg, 'ApiVersion')
                + '|CreatedDate=' + valueOf(trg, 'CreatedDate')
                + '|LastModifiedDate=' + valueOf(trg, 'LastModifiedDate')
                + '|BodyAvailable=' + bodyAvailable
            );

            if (cfg.includeApexBodyAnalysis && bodyAvailable) {
                describeTriggerEvents(log, triggerName, body);

                analyzeApexBody(
                    cfg,
                    log,
                    catalog,
                    'Trigger',
                    triggerName,
                    body
                );
            }
        }

        log.line(
            'SF_DIAG|SUMMARY'
            + '|ApexTriggersAnalyzed=' + apexTriggers.size()
            + '|TriggerBodyAvailable=' + bodyAvailable
        );
    }

    private static void describeTriggerEvents(DiagLogger log, String triggerName, String body) {
        if (String.isBlank(body)) {
            return;
        }

        String bodyLower = body.toLowerCase();
        List<String> eventsFound = new List<String>();

        if (bodyLower.contains('before insert')) eventsFound.add('before insert');
        if (bodyLower.contains('before update')) eventsFound.add('before update');
        if (bodyLower.contains('before delete')) eventsFound.add('before delete');
        if (bodyLower.contains('after insert')) eventsFound.add('after insert');
        if (bodyLower.contains('after update')) eventsFound.add('after update');
        if (bodyLower.contains('after delete')) eventsFound.add('after delete');
        if (bodyLower.contains('after undelete')) eventsFound.add('after undelete');

        log.line(
            'SF_DIAG|APEX_TRIGGER_EVENTS'
            + '|Trigger=' + clean(triggerName)
            + '|Events=' + clean(String.join(eventsFound, ','))
        );
    }

    private static void analyzeApexBody(
        Config cfg,
        DiagLogger log,
        AnalysisCatalog catalog,
        String typeName,
        String apexUnitName,
        String body
    ) {
        if (String.isBlank(body)) {
            return;
        }

        String bodyLower = body.toLowerCase();

        extractMethods(cfg, log, typeName, apexUnitName, body);

        Integer objRefCounter = 0;

        for (String objectToken : catalog.objectTokens) {
            if (objRefCounter >= cfg.maxObjectRefsPerApexUnit) {
                log.line(
                    'SF_DIAG|APEX_OBJECT_REF_LIMIT_REACHED'
                    + '|Type=' + clean(typeName)
                    + '|ApexUnit=' + clean(apexUnitName)
                );
                break;
            }

            if (bodyLower.contains(objectToken.toLowerCase())) {
                objRefCounter++;

                log.line(
                    'SF_DIAG|APEX_OBJECT_REF'
                    + '|Type=' + clean(typeName)
                    + '|ApexUnit=' + clean(apexUnitName)
                    + '|ObjectToken=' + clean(objectToken)
                );
            }
        }

        Integer fieldRefCounter = 0;

        for (String fieldToken : catalog.fieldTokenToPossibleFields.keySet()) {
            if (fieldRefCounter >= cfg.maxFieldRefsPerApexUnit) {
                log.line(
                    'SF_DIAG|APEX_FIELD_REF_LIMIT_REACHED'
                    + '|Type=' + clean(typeName)
                    + '|ApexUnit=' + clean(apexUnitName)
                );
                break;
            }

            if (bodyLower.contains(fieldToken.toLowerCase())) {
                fieldRefCounter++;

                List<String> possibleMatches = catalog.fieldTokenToPossibleFields.get(fieldToken);
                List<String> trimmedMatches = new List<String>();

                Integer matchCounter = 0;

                for (String possibleMatch : possibleMatches) {
                    if (matchCounter >= 15) {
                        break;
                    }

                    trimmedMatches.add(possibleMatch);
                    matchCounter++;
                }

                log.line(
                    'SF_DIAG|APEX_FIELD_REF'
                    + '|Type=' + clean(typeName)
                    + '|ApexUnit=' + clean(apexUnitName)
                    + '|FieldToken=' + clean(fieldToken)
                    + '|PossibleMatches=' + clean(String.join(trimmedMatches, ','))
                    + '|TotalPossibleMatches=' + possibleMatches.size()
                );
            }
        }
    }

    private static void extractMethods(
        Config cfg,
        DiagLogger log,
        String typeName,
        String apexUnitName,
        String body
    ) {
        try {
            Pattern methodPattern = Pattern.compile(
                '(?i)\\b(public|private|protected|global|webservice)\\s+' +
                '(static\\s+)?[A-Za-z0-9_<>,\\[\\]\\.]+\\s+' +
                '([A-Za-z0-9_]+)\\s*\\('
            );

            Matcher methodMatcher = methodPattern.matcher(body);
            Integer methodCounter = 0;

            while (methodMatcher.find()) {
                if (methodCounter >= cfg.maxMethodsPerApexUnit) {
                    log.line(
                        'SF_DIAG|APEX_METHOD_LIMIT_REACHED'
                        + '|Type=' + clean(typeName)
                        + '|ApexUnit=' + clean(apexUnitName)
                    );
                    break;
                }

                methodCounter++;

                log.line(
                    'SF_DIAG|APEX_METHOD'
                    + '|Type=' + clean(typeName)
                    + '|ApexUnit=' + clean(apexUnitName)
                    + '|Method=' + clean(methodMatcher.group(3))
                    + '|Visibility=' + clean(methodMatcher.group(1))
                    + '|IsStatic=' + String.valueOf(methodMatcher.group(2) != null)
                );
            }
        } catch (Exception e) {
            log.line(
                'SF_DIAG|APEX_METHOD_PARSE_ERROR'
                + '|Type=' + clean(typeName)
                + '|ApexUnit=' + clean(apexUnitName)
                + '|Message=' + clean(e.getMessage())
            );
        }
    }

    // ============================================================
    // SECCIÓN: FLOWS
    // ============================================================

    private static void sectionFlows(Config cfg, DiagLogger log) {
        log.line('SF_DIAG|SECTION|FLOWS');

        List<SObject> flowDefinitions = new List<SObject>();
        String flowDefinitionMode = 'NONE';

        try {
            flowDefinitions = Database.query(
                'SELECT DurableId, ApiName, Label, ProcessType, ActiveVersionId, LatestVersionId ' +
                'FROM FlowDefinitionView ' +
                'ORDER BY ApiName ' +
                'LIMIT ' + cfg.maxFlows
            );

            flowDefinitionMode = 'RICH';
        } catch (Exception e1) {
            log.line('SF_DIAG|FLOW_DEFINITION_RICH_WARNING|Message=' + clean(e1.getMessage()));

            try {
                flowDefinitions = Database.query(
                    'SELECT DurableId, ApiName, Label ' +
                    'FROM FlowDefinitionView ' +
                    'ORDER BY ApiName ' +
                    'LIMIT ' + cfg.maxFlows
                );

                flowDefinitionMode = 'BASIC';
            } catch (Exception e2) {
                log.line('SF_DIAG|FLOW_DEFINITION_ERROR|Message=' + clean(e2.getMessage()));
            }
        }

        for (SObject fd : flowDefinitions) {
            String line =
                'SF_DIAG|FLOW_DEFINITION'
                + '|DurableId=' + valueOf(fd, 'DurableId')
                + '|ApiName=' + valueOf(fd, 'ApiName')
                + '|Label=' + valueOf(fd, 'Label');

            if (flowDefinitionMode == 'RICH') {
                line +=
                    '|ProcessType=' + valueOf(fd, 'ProcessType')
                    + '|ActiveVersionId=' + valueOf(fd, 'ActiveVersionId')
                    + '|LatestVersionId=' + valueOf(fd, 'LatestVersionId');
            }

            log.line(line);
        }

        List<SObject> flowVersions = new List<SObject>();
        String flowVersionMode = 'NONE';

        try {
            flowVersions = Database.query(
                'SELECT DurableId, ApiName, Label, VersionNumber, Status, ProcessType, TriggerType, ObjectApiName, RecordTriggerType, TriggerOrder, ApiVersion ' +
                'FROM FlowVersionView ' +
                'WHERE Status = \'Active\' ' +
                'ORDER BY ApiName, VersionNumber ' +
                'LIMIT ' + cfg.maxFlows
            );

            flowVersionMode = 'RICH';
        } catch (Exception e1) {
            log.line('SF_DIAG|FLOW_VERSION_RICH_WARNING|Message=' + clean(e1.getMessage()));

            try {
                flowVersions = Database.query(
                    'SELECT DurableId, ApiName, VersionNumber, Status ' +
                    'FROM FlowVersionView ' +
                    'WHERE Status = \'Active\' ' +
                    'ORDER BY ApiName, VersionNumber ' +
                    'LIMIT ' + cfg.maxFlows
                );

                flowVersionMode = 'BASIC';
            } catch (Exception e2) {
                log.line('SF_DIAG|FLOW_VERSION_ERROR|Message=' + clean(e2.getMessage()));
            }
        }

        for (SObject fv : flowVersions) {
            String line =
                'SF_DIAG|FLOW_VERSION'
                + '|DurableId=' + valueOf(fv, 'DurableId')
                + '|ApiName=' + valueOf(fv, 'ApiName')
                + '|VersionNumber=' + valueOf(fv, 'VersionNumber')
                + '|Status=' + valueOf(fv, 'Status');

            if (flowVersionMode == 'RICH') {
                line +=
                    '|Label=' + valueOf(fv, 'Label')
                    + '|ProcessType=' + valueOf(fv, 'ProcessType')
                    + '|TriggerType=' + valueOf(fv, 'TriggerType')
                    + '|ObjectApiName=' + valueOf(fv, 'ObjectApiName')
                    + '|RecordTriggerType=' + valueOf(fv, 'RecordTriggerType')
                    + '|TriggerOrder=' + valueOf(fv, 'TriggerOrder')
                    + '|ApiVersion=' + valueOf(fv, 'ApiVersion');
            }

            log.line(line);
        }

        log.line(
            'SF_DIAG|SUMMARY'
            + '|FlowDefinitions=' + flowDefinitions.size()
            + '|FlowVersions=' + flowVersions.size()
            + '|FlowDefinitionMode=' + flowDefinitionMode
            + '|FlowVersionMode=' + flowVersionMode
        );
    }

    // ============================================================
    // SECCIÓN: OTRAS AUTOMATIZACIONES Y REGLAS
    // ============================================================

    private static void sectionOtherAutomationsAndRules(DiagLogger log) {
        log.line('SF_DIAG|SECTION|OTHER_AUTOMATIONS_AND_RULES');

        queryProcessDefinitions(log);
        queryValidationRules(log);
        queryWorkflowRules(log);
        queryDuplicateRules(log);
    }

    private static void queryProcessDefinitions(DiagLogger log) {
        try {
            List<SObject> rows = Database.query(
                'SELECT Id, Name, DeveloperName, TableEnumOrId, State, Type ' +
                'FROM ProcessDefinition ' +
                'ORDER BY DeveloperName ' +
                'LIMIT 300'
            );

            for (SObject row : rows) {
                log.line(
                    'SF_DIAG|PROCESS_DEFINITION'
                    + '|Name=' + valueOf(row, 'Name')
                    + '|DeveloperName=' + valueOf(row, 'DeveloperName')
                    + '|Object=' + valueOf(row, 'TableEnumOrId')
                    + '|State=' + valueOf(row, 'State')
                    + '|Type=' + valueOf(row, 'Type')
                );
            }

            log.line('SF_DIAG|SUMMARY|ProcessDefinitions=' + rows.size());
        } catch (Exception e) {
            log.line('SF_DIAG|PROCESS_DEFINITION_ERROR_OR_NOT_AVAILABLE|Message=' + clean(e.getMessage()));
        }
    }

    private static void queryValidationRules(DiagLogger log) {
        try {
            List<SObject> rows = Database.query(
                'SELECT Id, ValidationName, Active, Description, ErrorMessage, EntityDefinition.QualifiedApiName ' +
                'FROM ValidationRule ' +
                'ORDER BY EntityDefinition.QualifiedApiName, ValidationName ' +
                'LIMIT 500'
            );

            for (SObject row : rows) {
                String entityName = '';

                try {
                    SObject entityDef = row.getSObject('EntityDefinition');
                    if (entityDef != null) {
                        entityName = String.valueOf(entityDef.get('QualifiedApiName'));
                    }
                } catch (Exception entityEx) {
                    entityName = '';
                }

                log.line(
                    'SF_DIAG|VALIDATION_RULE'
                    + '|Object=' + clean(entityName)
                    + '|Name=' + valueOf(row, 'ValidationName')
                    + '|Active=' + valueOf(row, 'Active')
                    + '|Description=' + valueOf(row, 'Description')
                    + '|ErrorMessage=' + valueOf(row, 'ErrorMessage')
                );
            }

            log.line('SF_DIAG|SUMMARY|ValidationRules=' + rows.size());
        } catch (Exception e) {
            log.line('SF_DIAG|VALIDATION_RULES_NOT_AVAILABLE_IN_THIS_CONTEXT|Message=' + clean(e.getMessage()));
        }
    }

    private static void queryWorkflowRules(DiagLogger log) {
        try {
            List<SObject> rows = Database.query(
                'SELECT Id, Name, TableEnumOrId, Active ' +
                'FROM WorkflowRule ' +
                'ORDER BY TableEnumOrId, Name ' +
                'LIMIT 500'
            );

            for (SObject row : rows) {
                log.line(
                    'SF_DIAG|WORKFLOW_RULE'
                    + '|Object=' + valueOf(row, 'TableEnumOrId')
                    + '|Name=' + valueOf(row, 'Name')
                    + '|Active=' + valueOf(row, 'Active')
                );
            }

            log.line('SF_DIAG|SUMMARY|WorkflowRules=' + rows.size());
        } catch (Exception e) {
            log.line('SF_DIAG|WORKFLOW_RULES_NOT_AVAILABLE_IN_THIS_CONTEXT|Message=' + clean(e.getMessage()));
        }
    }

    private static void queryDuplicateRules(DiagLogger log) {
        try {
            List<SObject> rows = Database.query(
                'SELECT Id, DeveloperName, MasterLabel, SobjectType, IsActive ' +
                'FROM DuplicateRule ' +
                'ORDER BY SobjectType, DeveloperName ' +
                'LIMIT 500'
            );

            for (SObject row : rows) {
                log.line(
                    'SF_DIAG|DUPLICATE_RULE'
                    + '|Object=' + valueOf(row, 'SobjectType')
                    + '|DeveloperName=' + valueOf(row, 'DeveloperName')
                    + '|MasterLabel=' + valueOf(row, 'MasterLabel')
                    + '|IsActive=' + valueOf(row, 'IsActive')
                );
            }

            log.line('SF_DIAG|SUMMARY|DuplicateRules=' + rows.size());
        } catch (Exception e) {
            log.line('SF_DIAG|DUPLICATE_RULES_NOT_AVAILABLE_IN_THIS_CONTEXT|Message=' + clean(e.getMessage()));
        }
    }

    // ============================================================
    // CATÁLOGOS BASE
    // ============================================================

    private static Set<String> defaultStandardObjectsToInclude() {
        return new Set<String>{
            'Account',
            'Contact',
            'Lead',
            'Opportunity',
            'OpportunityLineItem',
            'Product2',
            'Pricebook2',
            'PricebookEntry',
            'Quote',
            'QuoteLineItem',
            'Contract',
            'Order',
            'OrderItem',
            'Case',
            'Task',
            'Event',
            'Campaign',
            'CampaignMember',
            'User',
            'RecordType'
        };
    }

    private static Set<String> standardFieldsToAnalyze() {
        return new Set<String>{
            'Id',
            'Name',
            'OwnerId',
            'RecordTypeId',
            'AccountId',
            'ContactId',
            'LeadId',
            'OpportunityId',
            'CaseId',
            'Status',
            'StageName',
            'Amount',
            'CloseDate',
            'Email',
            'Phone',
            'CreatedDate',
            'LastModifiedDate'
        };
    }

    // ============================================================
    // FILTRO DE OBJETOS INTERNOS / SIN ACCESO
    // ============================================================

    private static Set<String> blockedEntityNames() {
        return new Set<String>{
            'AIWorksheetColProcEvent',
            'AIWorksheetProcEvent',
            'AIWorksheetEvent'
        };
    }

    private static Boolean shouldSkipEntity(String apiName) {
        if (String.isBlank(apiName)) {
            return true;
        }

        if (blockedEntityNames().contains(apiName)) {
            return true;
        }

        Boolean isCustomLike =
            apiName.endsWith('__c') ||
            apiName.endsWith('__mdt') ||
            apiName.endsWith('__e') ||
            apiName.endsWith('__x');

        /*
         * Omite entidades internas estándar de IA que pueden aparecer en
         * Schema.getGlobalDescribe() o en relaciones hijas, pero no siempre
         * son accesibles desde Apex.
         */
        if (!isCustomLike && apiName.startsWith('AI')) {
            return true;
        }

        return false;
    }

    private static String safeChildObjectName(Schema.ChildRelationship childRel) {
        try {
            return String.valueOf(childRel.getChildSObject());
        } catch (Exception e) {
            return 'ACCESS_DENIED_CHILD_OBJECT';
        }
    }

    private static String safeChildFieldName(Schema.ChildRelationship childRel) {
        try {
            return String.valueOf(childRel.getField());
        } catch (Exception e) {
            return 'ACCESS_DENIED_CHILD_FIELD';
        }
    }

    private static String safeChildRelationshipName(Schema.ChildRelationship childRel) {
        try {
            return clean(childRel.getRelationshipName());
        } catch (Exception e) {
            return 'ACCESS_DENIED_RELATIONSHIP_NAME';
        }
    }

    // ============================================================
    // UTILIDADES
    // ============================================================

    private static String valueOf(SObject row, String fieldApiName) {
        try {
            Object value = row.get(fieldApiName);
            return clean(String.valueOf(value));
        } catch (Exception e) {
            return '';
        }
    }

    private static String getOptionalField(SObject row, String fieldApiName) {
        try {
            Object value = row.get(fieldApiName);
            return String.valueOf(value);
        } catch (Exception e) {
            return '';
        }
    }

    private static String clean(String value) {
        if (value == null) {
            return '';
        }

        return value
            .replace('|', '/')
            .replace('\r', ' ')
            .replace('\n', ' ')
            .replace('\t', ' ')
            .trim();
    }
}