public with sharing class tech_OllinAuditService {

    private static final Integer CHUNK_SIZE = 10000;

    public static void run() {
        Map<String, Object> result = new Map<String, Object>();

        result.put('auditName', 'OLLIN Salesforce Configuration Audit');
        result.put('generatedAt', String.valueOf(System.now()));
        result.put('executedBy', UserInfo.getName());
        result.put('orgId', UserInfo.getOrganizationId());

        result.put('objects', auditObjects());
        result.put('apexClasses', auditApexClasses());
        result.put('apexTriggers', auditApexTriggers());

        printResult(result);
    }

    private static List<Object> auditObjects() {
        List<Object> output = new List<Object>();

        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

        Set<String> targetObjects = new Set<String>{
            'Lead',
            'Account',
            'Contact',
            'Opportunity',
            'Product2',
            'Pricebook2',
            'PricebookEntry',
            'OpportunityLineItem',
            'Contract',
            'Task',
            'Event',
            'Campaign'
        };

        for (String objName : gd.keySet()) {
            if (objName != null && objName.startsWith('Tech_') && objName.endsWith('__c')) {
                targetObjects.add(objName);
            }
        }

        for (String objApi : targetObjects) {
            Map<String, Object> objInfo = new Map<String, Object>();
            objInfo.put('objectApiName', objApi);

            if (!gd.containsKey(objApi)) {
                objInfo.put('status', 'NOT_FOUND');
                output.add(objInfo);
                continue;
            }

            Schema.DescribeSObjectResult d = gd.get(objApi).getDescribe();

            objInfo.put('status', 'FOUND');
            objInfo.put('label', d.getLabel());
            objInfo.put('custom', d.isCustom());
            objInfo.put('createable', d.isCreateable());
            objInfo.put('updateable', d.isUpdateable());
            objInfo.put('deletable', d.isDeletable());
            objInfo.put('queryable', d.isQueryable());

            List<Object> recordTypes = new List<Object>();

            for (Schema.RecordTypeInfo rt : d.getRecordTypeInfos()) {
                Map<String, Object> rtInfo = new Map<String, Object>();
                rtInfo.put('name', rt.getName());
                rtInfo.put('developerName', rt.getDeveloperName());
                rtInfo.put('available', rt.isAvailable());
                rtInfo.put('default', rt.isDefaultRecordTypeMapping());
                recordTypes.add(rtInfo);
            }

            objInfo.put('recordTypes', recordTypes);

            List<Object> fields = new List<Object>();
            Map<String, Schema.SObjectField> fieldMap = d.fields.getMap();

            for (String fieldApi : fieldMap.keySet()) {
                Schema.DescribeFieldResult fd = fieldMap.get(fieldApi).getDescribe();

                Map<String, Object> fieldInfo = new Map<String, Object>();
                fieldInfo.put('fieldApiName', fieldApi);
                fieldInfo.put('label', fd.getLabel());
                fieldInfo.put('type', String.valueOf(fd.getType()));
                fieldInfo.put('nillable', fd.isNillable());
                fieldInfo.put('createable', fd.isCreateable());
                fieldInfo.put('updateable', fd.isUpdateable());
                fieldInfo.put('calculated', fd.isCalculated());
                fieldInfo.put('relationshipName', fd.getRelationshipName());

                List<String> referenceTo = new List<String>();

                for (Schema.SObjectType refType : fd.getReferenceTo()) {
                    referenceTo.add(refType.getDescribe().getName());
                }

                if (!referenceTo.isEmpty()) {
                    fieldInfo.put('referenceTo', referenceTo);
                }

                if (
                    fd.getType() == Schema.DisplayType.Picklist ||
                    fd.getType() == Schema.DisplayType.MultiPicklist
                ) {
                    List<String> values = new List<String>();

                    for (Schema.PicklistEntry pe : fd.getPicklistValues()) {
                        if (pe.isActive()) {
                            values.add(pe.getValue());
                        }
                    }

                    fieldInfo.put('picklistValues', values);
                }

                fields.add(fieldInfo);
            }

            objInfo.put('fields', fields);

            List<Object> childRelationships = new List<Object>();

            for (Schema.ChildRelationship cr : d.getChildRelationships()) {
                if (cr.getChildSObject() == null || cr.getField() == null) {
                    continue;
                }

                String childObj = cr.getChildSObject().getDescribe().getName();

                if (
                    targetObjects.contains(childObj) ||
                    childObj.startsWith('Tech_') ||
                    objApi.startsWith('Tech_')
                ) {
                    Map<String, Object> rel = new Map<String, Object>();
                    rel.put('parentObject', objApi);
                    rel.put('childObject', childObj);
                    rel.put('field', String.valueOf(cr.getField()));
                    rel.put('relationshipName', cr.getRelationshipName());
                    rel.put('cascadeDelete', cr.isCascadeDelete());

                    childRelationships.add(rel);
                }
            }

            objInfo.put('childRelationships', childRelationships);

            output.add(objInfo);
        }

        return output;
    }

    private static List<Object> auditApexClasses() {
        List<Object> output = new List<Object>();

        List<ApexClass> classes = [
            SELECT Id, Name, ApiVersion, Status, Body, LengthWithoutComments
            FROM ApexClass
            WHERE Name LIKE 'Tech%' OR Name LIKE 'Ollin%'
            ORDER BY Name
        ];

        Set<String> objectTokens = getObjectTokens();
        Set<String> fieldTokens = getFieldTokens();

        for (ApexClass cls : classes) {
            String body = cls.Body == null ? '' : cls.Body;

            Map<String, Object> info = new Map<String, Object>();
            info.put('className', cls.Name);
            info.put('apiVersion', cls.ApiVersion);
            info.put('status', cls.Status);
            info.put('lengthWithoutComments', cls.LengthWithoutComments);
            info.put('usedObjects', detectTokens(body, objectTokens));
            info.put('usedFields', detectTokens(body, fieldTokens));
            info.put('methods', detectMethods(body));

            output.add(info);
        }

        return output;
    }

    private static List<Object> auditApexTriggers() {
        List<Object> output = new List<Object>();

        List<ApexTrigger> triggers = [
            SELECT Id, Name, TableEnumOrId, Status, Body, ApiVersion, LengthWithoutComments
            FROM ApexTrigger
            WHERE Name LIKE 'Tech%' OR Name LIKE 'Ollin%'
            ORDER BY Name
        ];

        Set<String> objectTokens = getObjectTokens();
        Set<String> fieldTokens = getFieldTokens();

        for (ApexTrigger trg : triggers) {
            String body = trg.Body == null ? '' : trg.Body;

            Map<String, Object> info = new Map<String, Object>();
            info.put('triggerName', trg.Name);
            info.put('objectOrTable', trg.TableEnumOrId);
            info.put('apiVersion', trg.ApiVersion);
            info.put('status', trg.Status);
            info.put('lengthWithoutComments', trg.LengthWithoutComments);
            info.put('usedObjects', detectTokens(body, objectTokens));
            info.put('usedFields', detectTokens(body, fieldTokens));

            output.add(info);
        }

        return output;
    }

    private static Set<String> getObjectTokens() {
        Set<String> tokens = new Set<String>{
            'Lead',
            'Account',
            'Contact',
            'Opportunity',
            'Product2',
            'Contract',
            'Task',
            'Event',
            'Campaign'
        };

        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

        for (String objName : gd.keySet()) {
            if (objName != null && objName.startsWith('Tech_') && objName.endsWith('__c')) {
                tokens.add(objName);
            }
        }

        return tokens;
    }

    private static Set<String> getFieldTokens() {
        Set<String> tokens = new Set<String>{
            'Id',
            'Name',
            'AccountId',
            'ContactId',
            'OwnerId',
            'StageName',
            'CloseDate',
            'Amount',
            'RecordTypeId'
        };

        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

        for (String objName : gd.keySet()) {
            if (
                objName == null ||
                !(
                    objName.startsWith('Tech_') ||
                    objName == 'Lead' ||
                    objName == 'Account' ||
                    objName == 'Opportunity' ||
                    objName == 'Product2' ||
                    objName == 'Contract'
                )
            ) {
                continue;
            }

            Schema.DescribeSObjectResult d = gd.get(objName).getDescribe();

            for (String fieldApi : d.fields.getMap().keySet()) {
                if (fieldApi.endsWith('__c')) {
                    tokens.add(fieldApi);
                }
            }
        }

        return tokens;
    }

    private static List<String> detectTokens(String body, Set<String> tokens) {
        List<String> found = new List<String>();

        for (String token : tokens) {
            if (!String.isBlank(token) && body.contains(token)) {
                found.add(token);
            }
        }

        found.sort();
        return found;
    }

    private static List<String> detectMethods(String body) {
        List<String> methods = new List<String>();

        if (String.isBlank(body)) {
            return methods;
        }

        List<String> lines = body.split('\n');

        for (String rawLine : lines) {
            String line = rawLine == null ? '' : rawLine.trim();

            Boolean looksLikeMethod =
                (
                    line.startsWith('public ') ||
                    line.startsWith('private ') ||
                    line.startsWith('global ') ||
                    line.startsWith('protected ')
                )
                &&
                line.contains('(')
                &&
                line.contains(')')
                &&
                !line.startsWith('if ')
                &&
                !line.startsWith('for ')
                &&
                !line.startsWith('while ');

            if (looksLikeMethod) {
                if (line.length() > 250) {
                    line = line.substring(0, 250);
                }

                methods.add(line);
            }
        }

        return methods;
    }

    private static void printResult(Map<String, Object> result) {
        String jsonOutput = JSON.serializePretty(result);

        System.debug('OLLIN_AUDIT_START');

        for (Integer i = 0; i < jsonOutput.length(); i += CHUNK_SIZE) {
            Integer endIndex = Math.min(i + CHUNK_SIZE, jsonOutput.length());
            System.debug(jsonOutput.substring(i, endIndex));
        }

        System.debug('OLLIN_AUDIT_END');
    }
}