public with sharing class TechVentasController {

    @AuraEnabled(cacheable=true)
    public static TechVentasWrapper getKPIs() {
        TechVentasWrapper w = new TechVentasWrapper();
        w.leadsActivos    = 0;
        w.oppsEnPipeline  = 0;
        w.cierresGanados  = 0;
        w.cierresPerdidos = 0;
        w.montoTotalPipeline = 0;

        for (AggregateResult ar : TechVentasSelector.getLeadKPIs()) {
            w.leadsActivos += (Integer) ar.get('total');
        }

        for (AggregateResult ar : TechVentasSelector.getOppKPIs()) {
            String stage = (String)  ar.get('StageName');
            Integer cnt  = (Integer) ar.get('total');
            Decimal mon  = (Decimal) ar.get('monto');
            if (stage == 'Cierre ganado'  || stage == 'Closed Won')  w.cierresGanados  += cnt;
            else if (stage == 'Cierre perdido' || stage == 'Closed Lost') w.cierresPerdidos += cnt;
            else {
                w.oppsEnPipeline += cnt;
                if (mon != null) w.montoTotalPipeline += mon;
            }
        }

        Integer total = w.cierresGanados + w.cierresPerdidos;
        w.tasaCierre  = total > 0 ? ((Decimal) w.cierresGanados / total * 100).setScale(1) : 0;
        return w;
    }

    @AuraEnabled
    public static List<TechVentasWrapper.LeadItem> getLeads(String filtersJson) {
        List<TechVentasWrapper.LeadItem> result = new List<TechVentasWrapper.LeadItem>();
        for (Lead l : TechVentasSelector.getLeads(filtersJson)) {
            result.add(new TechVentasWrapper.LeadItem(l));
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<TechVentasWrapper.AccountItem> getClientes() {
        List<TechVentasWrapper.AccountItem> result = new List<TechVentasWrapper.AccountItem>();
        for (Account a : TechVentasSelector.getClientes()) {
            result.add(new TechVentasWrapper.AccountItem(a));
        }
        return result;
    }

    @AuraEnabled
    public static List<TechVentasWrapper.OppItem> getOportunidades(String filtersJson) {
        List<TechVentasWrapper.OppItem> result = new List<TechVentasWrapper.OppItem>();
        for (Opportunity o : TechVentasSelector.getOportunidades(filtersJson)) {
            result.add(new TechVentasWrapper.OppItem(o));
        }
        return result;
    }

    @AuraEnabled
    public static String crearOportunidad(Opportunity opp) {
        try {
            insert opp;
            return opp.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al crear oportunidad: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String crearLead(Lead lead) {
        try {
            insert lead;
            return lead.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al crear lead: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void actualizarLead(Lead lead) {
        try {
            update lead;
        } catch (Exception e) {
            throw new AuraHandledException('Error al actualizar lead: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void actualizarScoreLead(String leadId, Integer score) {
        try {
            update new Lead(Id = (Id)leadId, Score__c = score);
        } catch (Exception e) {
            throw new AuraHandledException('Error al actualizar score: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Map<String,String>> searchSeguros(String term) {
        String q = '%' + String.escapeSingleQuotes(term) + '%';
        List<Map<String,String>> results = new List<Map<String,String>>();
        for (Tech_Seguro__c s : [
            SELECT Id, Name, Numero_poliza__c, Ramo__c, Cliente__r.Name
            FROM Tech_Seguro__c
            WHERE (Numero_poliza__c LIKE :q OR Name LIKE :q OR Cliente__r.Name LIKE :q)
            ORDER BY Numero_poliza__c NULLS LAST LIMIT 10
        ]) {
            String display = String.isNotBlank(s.Numero_poliza__c) ? s.Numero_poliza__c : s.Name;
            String sub     = (s.Ramo__c != null ? s.Ramo__c : '')
                           + (s.Cliente__r != null ? ' · ' + s.Cliente__r.Name : '');
            results.add(new Map<String,String>{ 'id' => s.Id, 'name' => display, 'sub' => sub });
        }
        return results;
    }

    @AuraEnabled
    public static List<Map<String,String>> searchAccounts(String term) {
        String q = '%' + String.escapeSingleQuotes(term) + '%';
        List<Map<String,String>> results = new List<Map<String,String>>();
        for (Account a : [SELECT Id, Name, RecordType.Name FROM Account
                          WHERE Name LIKE :q ORDER BY Name LIMIT 10]) {
            String sub = a.RecordType != null ? a.RecordType.Name : '';
            results.add(new Map<String,String>{ 'id' => a.Id, 'name' => a.Name, 'sub' => sub });
        }
        return results;
    }

    @AuraEnabled
    public static List<Map<String,String>> searchProducts(String term, String ramo, String institucionId) {
        String q    = '%' + String.escapeSingleQuotes(term) + '%';
        String rClean = String.escapeSingleQuotes(ramo        != null ? ramo        : '');
        String iClean = String.escapeSingleQuotes(institucionId != null ? institucionId : '');
        List<Map<String,String>> results = new List<Map<String,String>>();
        String soql = 'SELECT Id, Name, ProductCode, Family FROM Product2 WHERE Name LIKE :q AND IsActive = true';
        if (String.isNotBlank(rClean))  soql += ' AND Ramo__c = :rClean';
        if (String.isNotBlank(iClean))  soql += ' AND Institucion__c = :iClean';
        soql += ' ORDER BY Name LIMIT 10';
        for (Product2 p : Database.query(soql)) {
            String sub = p.ProductCode != null ? p.ProductCode : (p.Family != null ? p.Family : '');
            results.add(new Map<String,String>{ 'id' => p.Id, 'name' => p.Name, 'sub' => sub });
        }
        return results;
    }

    @AuraEnabled
    public static List<Map<String,String>> searchVendedores(String term) {
        String q = '%' + String.escapeSingleQuotes(term) + '%';
        List<Map<String,String>> results = new List<Map<String,String>>();
        for (Tech_Vendedor__c v : [SELECT Id, Name, Name__c, Tipo_Vendedor__c, Email__c FROM Tech_Vendedor__c
                                    WHERE Name__c LIKE :q OR Email__c LIKE :q OR Name LIKE :q ORDER BY Name__c LIMIT 10]) {
            String displayName = v.Name__c != null ? v.Name__c : v.Name;
            String sub = v.Name + (v.Email__c != null ? ' · ' + v.Email__c : (v.Tipo_Vendedor__c != null ? ' · ' + v.Tipo_Vendedor__c : ''));
            results.add(new Map<String,String>{ 'id' => v.Id, 'name' => displayName, 'sub' => sub });
        }
        return results;
    }

    @AuraEnabled
    public static void actualizarOportunidad(Opportunity opp) {
        try {
            update opp;
        } catch (Exception e) {
            throw new AuraHandledException('Error al actualizar: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void actualizarStageOpp(String oppId, String stage) {
        try {
            update new Opportunity(Id = (Id)oppId, StageName = stage);
        } catch (Exception e) {
            throw new AuraHandledException('Error al actualizar etapa: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getLeadRecordTypes() {
        List<Map<String,String>> result = new List<Map<String,String>>();
        for (RecordType rt : [SELECT Id, Name, DeveloperName FROM RecordType
                              WHERE SobjectType = 'Lead' AND IsActive = true ORDER BY Name]) {
            result.add(new Map<String,String>{
                'id'   => rt.Id,
                'name' => rt.Name,
                'dev'  => rt.DeveloperName
            });
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getOppRecordTypes() {
        List<Map<String,String>> result = new List<Map<String,String>>();
        for (RecordType rt : [SELECT Id, Name, DeveloperName FROM RecordType
                              WHERE SobjectType = 'Opportunity' AND IsActive = true ORDER BY Name]) {
            result.add(new Map<String,String>{
                'id'   => rt.Id,
                'name' => rt.Name,
                'dev'  => rt.DeveloperName
            });
        }
        return result;
    }

    @AuraEnabled
    public static String crearOportunidadDesdeLeadId(String leadId, Opportunity opp) {
        try {
            opp.Prospecto__c = (Id) leadId;
            insert opp;
            return opp.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al convertir lead: ' + e.getMessage());
        }
    }
}