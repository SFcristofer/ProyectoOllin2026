public with sharing class TechContratistaController {
    @AuraEnabled(cacheable=true)
    public static List<TechContratistaWrapper> getContratistaList() {
        List<TechContratistaWrapper> wrappers = new List<TechContratistaWrapper>();
        for (Account a : TechContratistaSelector.getRecentContratistas()) {
            wrappers.add(new TechContratistaWrapper(a));
        }
        return wrappers;
    }

    @AuraEnabled
    public static List<Map<String,String>> searchFianzas(String term) {
        String q = '%' + String.escapeSingleQuotes(term) + '%';
        List<Map<String,String>> results = new List<Map<String,String>>();
        for (Tech_Fianza__c f : [SELECT Id, Name, Estatus__c, Monto_Afianzado__c, Fecha_de_Vencimiento__c
                                  FROM Tech_Fianza__c WHERE Name LIKE :q ORDER BY Name LIMIT 10]) {
            String sub = '';
            if (f.Estatus__c          != null) sub += f.Estatus__c;
            if (f.Monto_Afianzado__c  != null) sub += (sub.length() > 0 ? ' · ' : '') + '$' + f.Monto_Afianzado__c.format();
            results.add(new Map<String,String>{ 'id' => f.Id, 'name' => f.Name, 'sub' => sub });
        }
        return results;
    }

    @AuraEnabled
    public static List<Map<String,String>> searchContratos(String term) {
        String q = '%' + String.escapeSingleQuotes(term) + '%';
        List<Map<String,String>> results = new List<Map<String,String>>();
        for (Contract c : [SELECT Id, ContractNumber, Status, Suma_Fianzas__c
                           FROM Contract WHERE ContractNumber LIKE :q ORDER BY ContractNumber LIMIT 10]) {
            String sub = '';
            if (c.Status          != null) sub += c.Status;
            if (c.Suma_Fianzas__c != null) sub += (sub.length() > 0 ? ' · ' : '') + '$' + c.Suma_Fianzas__c.format();
            results.add(new Map<String,String>{ 'id' => c.Id, 'name' => c.ContractNumber, 'sub' => sub });
        }
        return results;
    }

    @AuraEnabled
    public static void addRelacion(String contratistaId, String relatedId, String tipo) {
        try {
            if      (tipo == 'Fianza')   update new Tech_Fianza__c(Id = (Id)relatedId, Contratistas__c = (Id)contratistaId);
            else if (tipo == 'Contrato') update new Contract(Id = (Id)relatedId, Contratista__c = (Id)contratistaId);
        } catch (Exception e) {
            throw new AuraHandledException('Error al agregar relación: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static TechContratistaInterfacesWrapper getContratistaInterfacesData(String contratistaId) {
        TechContratistaInterfacesWrapper wrap = new TechContratistaInterfacesWrapper();
        wrap.contratos       = new List<TechContratistaInterfacesWrapper.ContratoItem>();
        wrap.fianzas         = new List<TechContratistaInterfacesWrapper.FianzaItem>();
        wrap.fianzasVencidas = new List<TechContratistaInterfacesWrapper.FianzaVencidaItem>();

        List<Account> ctList = [SELECT Id, Name FROM Account WHERE Id = :contratistaId LIMIT 1];
        if (ctList.isEmpty()) return wrap;
        Account ct = ctList[0];

        List<Tech_Fianza__c> fianzasList = [
            SELECT Id, Name, Monto_Afianzado__c, Estatus__c,
                   Fecha_de_Emision__c, Fecha_de_Vencimiento__c,
                   DiasReclamaci_n__c,
                   Contrato__c, Contrato__r.ContractNumber, Contrato__r.Valor_Contrato_Vigente__c
            FROM Tech_Fianza__c
            WHERE Contratistas__c = :contratistaId
            ORDER BY CreatedDate DESC
        ];

        Set<Id> contratoIdsSeen = new Set<Id>();
        Decimal totalAfianzado = 0;
        Integer fianzasVencidasCount = 0;

        for (Tech_Fianza__c f : fianzasList) {
            Decimal monto  = f.Monto_Afianzado__c;
            String estatus = f.Estatus__c;
            if (monto != null) totalAfianzado += monto;

            if (f.Contrato__c != null && !contratoIdsSeen.contains(f.Contrato__c)) {
                contratoIdsSeen.add(f.Contrato__c);
                TechContratistaInterfacesWrapper.ContratoItem ci = new TechContratistaInterfacesWrapper.ContratoItem();
                ci.id          = f.Contrato__c;
                ci.name        = f.Contrato__r != null ? f.Contrato__r.ContractNumber : '—';
                ci.contratista = ct.Name;
                ci.monto       = f.Contrato__r != null ? f.Contrato__r.Valor_Contrato_Vigente__c : 0;
                ci.proyecto    = '—';
                wrap.contratos.add(ci);
            }

            TechContratistaInterfacesWrapper.FianzaItem fi = new TechContratistaInterfacesWrapper.FianzaItem();
            fi.id          = f.Id;
            fi.name        = f.Name;
            fi.contratista = ct.Name;
            fi.contrato    = f.Contrato__r != null ? f.Contrato__r.ContractNumber : null;
            fi.monto       = monto;
            fi.estatus     = estatus;
            wrap.fianzas.add(fi);

            if (estatus == 'Vencida' || estatus == 'Cancelada') {
                fianzasVencidasCount++;
                TechContratistaInterfacesWrapper.FianzaVencidaItem fv = new TechContratistaInterfacesWrapper.FianzaVencidaItem();
                fv.id             = f.Id;
                fv.name           = f.Name;
                fv.contratista    = ct.Name;
                fv.contrato       = f.Contrato__r != null ? f.Contrato__r.ContractNumber : null;
                fv.montoAfianzado = monto;
                fv.estatus        = estatus;
                Date vencimiento  = f.Fecha_de_Vencimiento__c;
                if (vencimiento != null) {
                    fv.fechaFin     = String.valueOf(vencimiento);
                    fv.diasVigencia = Date.today().daysBetween(vencimiento);
                }
                wrap.fianzasVencidas.add(fv);
            }
        }

        wrap.totalAfianzado       = totalAfianzado;
        wrap.contratosCount       = wrap.contratos.size();
        wrap.fianzasVencidasCount = fianzasVencidasCount;
        return wrap;
    }

    @AuraEnabled
    public static String saveContratistaWithRelations(Account contratista, Map<String, List<String>> relationsMap) {
        try {
            if (contratista.Id == null && contratista.RecordTypeId == null) {
                RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Contratista' LIMIT 1];
                contratista.RecordTypeId = rt.Id;
            }
            upsert contratista;
            if (relationsMap != null) {
                for (String tipo : relationsMap.keySet()) {
                    List<String> ids = relationsMap.get(tipo);
                    if (ids == null || ids.isEmpty()) continue;
                    if (tipo == 'Fianza') {
                        List<Tech_Fianza__c> toUpdate = new List<Tech_Fianza__c>();
                        for (String fId : ids) {
                            toUpdate.add(new Tech_Fianza__c(Id = (Id)fId, Contratistas__c = contratista.Id));
                        }
                        update toUpdate;
                    }
                }
            }
            return contratista.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar contratista: ' + e.getMessage());
        }
    }
}