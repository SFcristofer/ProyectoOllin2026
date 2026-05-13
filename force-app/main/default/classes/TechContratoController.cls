public with sharing class TechContratoController {
    @AuraEnabled(cacheable=true)
    public static List<TechContratoWrapper> getContratosList() {
        List<TechContratoWrapper> wrappers = new List<TechContratoWrapper>();
        for (Contract c : TechContratoSelector.getAllContratos()) {
            wrappers.add(new TechContratoWrapper(c));
        }
        return wrappers;
    }

    @AuraEnabled
    public static String saveContratoWithRelations(Contract contrato, Map<String, List<String>> relationsMap) {
        try {
            upsert contrato;
            if (relationsMap != null) {
                Contract toUpdate = new Contract(Id = contrato.Id);
                Boolean needsUpdate = false;
                for (String tipo : relationsMap.keySet()) {
                    List<String> ids = relationsMap.get(tipo);
                    if (ids == null || ids.isEmpty()) continue;
                    String relatedId = ids[0];
                    if (tipo == 'Contratista') { toUpdate.Contratista__c = (Id)relatedId; needsUpdate = true; }
                }
                if (needsUpdate) update toUpdate;
            }
            return contrato.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar contrato: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String crearContratoConFianzas(Map<String,Object> contratoData, List<Map<String,Object>> fianzasData) {
        Savepoint sp = Database.setSavepoint();
        try {
            Contract c = new Contract();
            c.AccountId          = contratoData.containsKey('contratistaId') ? (Id)contratoData.get('contratistaId') : null;
            c.Contratista__c     = contratoData.containsKey('contratistaId') ? (Id)contratoData.get('contratistaId') : null;
            c.Beneficiario__c    = contratoData.containsKey('beneficiarioId') ? (Id)contratoData.get('beneficiarioId') : null;
            c.Institucion__c     = contratoData.containsKey('institucionId') ? (Id)contratoData.get('institucionId') : null;
            c.Status             = 'Draft';
            if (contratoData.containsKey('startDate') && contratoData.get('startDate') != null)
                c.StartDate = Date.valueOf(String.valueOf(contratoData.get('startDate')));
            if (contratoData.containsKey('endDate') && contratoData.get('endDate') != null)
                c.Fin_Contrato_Vigente__c = Date.valueOf(String.valueOf(contratoData.get('endDate')));
            if (contratoData.containsKey('valorContrato') && contratoData.get('valorContrato') != null)
                c.Valor_Contrato_Vigente__c = Decimal.valueOf(String.valueOf(contratoData.get('valorContrato')));
            if (contratoData.containsKey('proyecto') && contratoData.get('proyecto') != null)
                c.Proyecto__c = String.valueOf(contratoData.get('proyecto'));
            if (contratoData.containsKey('precalificacionId') && contratoData.get('precalificacionId') != null)
                c.Precalificacion__c = (Id)contratoData.get('precalificacionId');
            insert c;

            if (fianzasData != null && !fianzasData.isEmpty()) {
                List<Tech_Fianza__c> fianzas = new List<Tech_Fianza__c>();
                for (Map<String,Object> fd : fianzasData) {
                    Tech_Fianza__c f = new Tech_Fianza__c();
                    f.Contrato__c        = c.Id;
                    f.Beneficiarios__c   = contratoData.containsKey('beneficiarioId') ? (Id)contratoData.get('beneficiarioId') : null;
                    f.Institucion__c     = contratoData.containsKey('institucionId') ? (Id)contratoData.get('institucionId') : null;
                    if (fd.containsKey('tipoRiesgo'))     f.Tipo_de_Riesgo__c        = String.valueOf(fd.get('tipoRiesgo'));
                    if (fd.containsKey('monto') && fd.get('monto') != null)
                        f.Monto_Afianzado__c  = Decimal.valueOf(String.valueOf(fd.get('monto')));
                    if (fd.containsKey('primaNeta') && fd.get('primaNeta') != null)
                        f.Prima_neta__c       = Decimal.valueOf(String.valueOf(fd.get('primaNeta')));
                    if (fd.containsKey('fechaEmision') && fd.get('fechaEmision') != null)
                        f.Fecha_de_Emision__c = Date.valueOf(String.valueOf(fd.get('fechaEmision')));
                    if (fd.containsKey('fechaVencimiento') && fd.get('fechaVencimiento') != null)
                        f.Fecha_de_Vencimiento__c = Date.valueOf(String.valueOf(fd.get('fechaVencimiento')));
                    f.Estatus__c = 'Emitida';
                    fianzas.add(f);
                }
                insert fianzas;

                if (contratoData.containsKey('contratistaId') && contratoData.get('contratistaId') != null) {
                    List<Tech_Relacion__c> rels = new List<Tech_Relacion__c>();
                    for (Tech_Fianza__c f : fianzas) {
                        rels.add(new Tech_Relacion__c(
                            Fianza_Tech__c = f.Id,
                            Account__c     = (Id)contratoData.get('contratistaId'),
                            Tipo__c        = 'Contratista'
                        ));
                    }
                    insert rels;
                }
            }
            return c.Id;
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Error al crear contrato con fianzas: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void actualizarContratoConFianzas(
        String contratoId,
        Map<String,Object> contratoData,
        List<Map<String,Object>> fianzasData
    ) {
        Savepoint sp = Database.setSavepoint();
        try {
            Contract c = new Contract(Id = (Id) contratoId);
            if (contratoData.containsKey('contratistaId') && contratoData.get('contratistaId') != null)
                c.Contratista__c = (Id) contratoData.get('contratistaId');
            if (contratoData.containsKey('beneficiarioId') && contratoData.get('beneficiarioId') != null)
                c.Beneficiario__c = (Id) contratoData.get('beneficiarioId');
            if (contratoData.containsKey('institucionId') && contratoData.get('institucionId') != null)
                c.Institucion__c = (Id) contratoData.get('institucionId');
            if (contratoData.containsKey('valorContrato') && contratoData.get('valorContrato') != null)
                c.Valor_Contrato_Vigente__c = Decimal.valueOf(String.valueOf(contratoData.get('valorContrato')));
            if (contratoData.containsKey('startDate') && contratoData.get('startDate') != null)
                c.StartDate = Date.valueOf(String.valueOf(contratoData.get('startDate')));
            if (contratoData.containsKey('endDate') && contratoData.get('endDate') != null)
                c.Fin_Contrato_Vigente__c = Date.valueOf(String.valueOf(contratoData.get('endDate')));
            if (contratoData.containsKey('proyecto'))
                c.Proyecto__c = contratoData.get('proyecto') != null ? String.valueOf(contratoData.get('proyecto')) : null;
            if (contratoData.containsKey('precalificacionId'))
                c.Precalificacion__c = contratoData.get('precalificacionId') != null ? (Id)contratoData.get('precalificacionId') : null;
            update c;

            if (fianzasData != null && !fianzasData.isEmpty()) {
                List<Tech_Fianza__c> toInsert = new List<Tech_Fianza__c>();
                List<Tech_Fianza__c> toUpdate = new List<Tech_Fianza__c>();
                for (Map<String,Object> fd : fianzasData) {
                    String existingId = fd.containsKey('id') && fd.get('id') != null ? String.valueOf(fd.get('id')) : null;
                    Tech_Fianza__c f  = new Tech_Fianza__c();
                    if (String.isNotBlank(existingId) && existingId != 'null') {
                        f.Id = (Id) existingId;
                    } else {
                        f.Contrato__c = (Id) contratoId;
                        if (contratoData.containsKey('beneficiarioId') && contratoData.get('beneficiarioId') != null)
                            f.Beneficiarios__c = (Id) contratoData.get('beneficiarioId');
                        if (contratoData.containsKey('institucionId') && contratoData.get('institucionId') != null)
                            f.Institucion__c   = (Id) contratoData.get('institucionId');
                        f.Estatus__c = 'Emitida';
                    }
                    if (fd.containsKey('tipoRiesgo') && fd.get('tipoRiesgo') != null)
                        f.Tipo_de_Riesgo__c = String.valueOf(fd.get('tipoRiesgo'));
                    if (fd.containsKey('monto') && fd.get('monto') != null)
                        f.Monto_Afianzado__c = Decimal.valueOf(String.valueOf(fd.get('monto')));
                    if (fd.containsKey('primaNeta') && fd.get('primaNeta') != null)
                        f.Prima_neta__c = Decimal.valueOf(String.valueOf(fd.get('primaNeta')));
                    if (fd.containsKey('fechaEmision') && fd.get('fechaEmision') != null && String.isNotBlank(String.valueOf(fd.get('fechaEmision'))))
                        f.Fecha_de_Emision__c = Date.valueOf(String.valueOf(fd.get('fechaEmision')));
                    if (fd.containsKey('fechaVencimiento') && fd.get('fechaVencimiento') != null && String.isNotBlank(String.valueOf(fd.get('fechaVencimiento'))))
                        f.Fecha_de_Vencimiento__c = Date.valueOf(String.valueOf(fd.get('fechaVencimiento')));
                    if (f.Id != null) {
                        toUpdate.add(f);
                    } else {
                        toInsert.add(f);
                    }
                }
                if (!toUpdate.isEmpty()) update toUpdate;
                if (!toInsert.isEmpty()) {
                    insert toInsert;
                    if (contratoData.containsKey('contratistaId') && contratoData.get('contratistaId') != null) {
                        List<Tech_Relacion__c> rels = new List<Tech_Relacion__c>();
                        for (Tech_Fianza__c f : toInsert) {
                            rels.add(new Tech_Relacion__c(
                                Fianza_Tech__c = f.Id,
                                Account__c     = (Id) contratoData.get('contratistaId'),
                                Tipo__c        = 'Contratista'
                            ));
                        }
                        insert rels;
                    }
                }
            }
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Error al actualizar contrato con fianzas: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getContratoMonto(String contratoId) {
        Contract c = [SELECT Valor_Contrato_Vigente__c FROM Contract WHERE Id = :contratoId LIMIT 1];
        return new Map<String,Object>{ 'montoVigente' => c.Valor_Contrato_Vigente__c };
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String,Object>> getFianzasByContrato(String contratoId) {
        List<Map<String,Object>> result = new List<Map<String,Object>>();
        for (Tech_Fianza__c f : [
            SELECT Id, Name, Tipo_de_Riesgo__c, Monto_Afianzado__c, Monto_Afianzado_Vigente__c,
                   Prima_neta__c, Prima_Vigente__c, Estatus__c,
                   Fecha_de_Emision__c, Fecha_de_Vencimiento__c, Fecha_Vencimiento_Vigente__c
            FROM Tech_Fianza__c
            WHERE Contrato__c = :contratoId
            ORDER BY Tipo_de_Riesgo__c ASC NULLS LAST
        ]) {
            result.add(new Map<String,Object>{
                'id'             => f.Id,
                'name'           => f.Name,
                'tipoRiesgo'     => f.Tipo_de_Riesgo__c,
                'monto'          => f.Monto_Afianzado__c,
                'montoVigente'   => f.Monto_Afianzado_Vigente__c,
                'primaNeta'      => f.Prima_neta__c,
                'primaVigente'   => f.Prima_Vigente__c,
                'estatus'        => f.Estatus__c,
                'fechaEmision'        => f.Fecha_de_Emision__c          != null ? String.valueOf(f.Fecha_de_Emision__c)          : null,
                'fechaVencimiento'    => f.Fecha_de_Vencimiento__c      != null ? String.valueOf(f.Fecha_de_Vencimiento__c)      : null,
                'fechaVencimientoVig' => f.Fecha_Vencimiento_Vigente__c != null ? String.valueOf(f.Fecha_Vencimiento_Vigente__c) : null
            });
        }
        return result;
    }
}