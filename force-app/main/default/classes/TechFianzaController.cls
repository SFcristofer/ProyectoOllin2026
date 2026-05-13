public with sharing class TechFianzaController {
    @AuraEnabled(cacheable=true)
    public static List<TechFianzaWrapper> getFianzasList() {
        List<TechFianzaWrapper> wrappers = new List<TechFianzaWrapper>();
        for (Tech_Fianza__c f : TechFianzaSelector.getAllFianzas()) {
            wrappers.add(new TechFianzaWrapper(f));
        }
        return wrappers;
    }

    @AuraEnabled
    public static List<Map<String,String>> searchContratistas(String term) {
        String q = '%' + String.escapeSingleQuotes(term != null ? term : '') + '%';
        List<Map<String,String>> results = new List<Map<String,String>>();
        for (Account a : [SELECT Id, Name, RFC__c, BillingCity
                          FROM Account
                          WHERE RecordType.DeveloperName = 'Contratista' AND Name LIKE :q
                          ORDER BY Name LIMIT 10]) {
            String sub = '';
            if (a.RFC__c      != null) sub += a.RFC__c;
            if (a.BillingCity != null) sub += (sub.length() > 0 ? ' · ' : '') + a.BillingCity;
            results.add(new Map<String,String>{ 'id' => a.Id, 'name' => a.Name, 'sub' => sub });
        }
        return results;
    }

    @AuraEnabled
    public static List<Map<String,String>> searchVendedores(String term) {
        String q = '%' + String.escapeSingleQuotes(term) + '%';
        List<Map<String,String>> results = new List<Map<String,String>>();
        for (Vendedores__c v : [SELECT Id, Name, Rol__c, CorreoElectronico__c
                                 FROM Vendedores__c WHERE Name LIKE :q ORDER BY Name LIMIT 10]) {
            String sub = '';
            if (v.Rol__c               != null) sub += v.Rol__c;
            if (v.CorreoElectronico__c != null) sub += (sub.length() > 0 ? ' · ' : '') + v.CorreoElectronico__c;
            results.add(new Map<String,String>{ 'id' => v.Id, 'name' => v.Name, 'sub' => sub });
        }
        return results;
    }

    @AuraEnabled
    public static List<Map<String,String>> searchAfianzadoras(String term) {
        String q = '%' + String.escapeSingleQuotes(term != null ? term : '') + '%';
        List<Map<String,String>> results = new List<Map<String,String>>();
        for (Institucion__c i : [SELECT Id, Name, Tipo__c FROM Institucion__c
                                  WHERE Name LIKE :q ORDER BY Name LIMIT 10]) {
            results.add(new Map<String,String>{
                'id' => i.Id, 'name' => i.Name,
                'sub' => i.Tipo__c != null ? i.Tipo__c : ''
            });
        }
        return results;
    }

    @AuraEnabled
    public static List<Map<String,String>> searchBeneficiarios(String term) {
        String q = '%' + String.escapeSingleQuotes(term != null ? term : '') + '%';
        List<Map<String,String>> results = new List<Map<String,String>>();
        for (Account a : [SELECT Id, Name, RFC__c FROM Account
                          WHERE RecordType.DeveloperName = 'Beneficiario' AND Name LIKE :q
                          ORDER BY Name LIMIT 10]) {
            results.add(new Map<String,String>{
                'id' => a.Id, 'name' => a.Name,
                'sub' => a.RFC__c != null ? a.RFC__c : ''
            });
        }
        return results;
    }

    @AuraEnabled
    public static List<Map<String,String>> searchContratosForFianza(String term) {
        String q = '%' + String.escapeSingleQuotes(term) + '%';
        List<Map<String,String>> results = new List<Map<String,String>>();
        for (Contract c : [SELECT Id, ContractNumber, Status, Suma_Fianzas__c
                           FROM Contract WHERE ContractNumber LIKE :q OR Account.Name LIKE :q
                           ORDER BY ContractNumber LIMIT 10]) {
            String sub = '';
            if (c.Status          != null) sub += c.Status;
            if (c.Suma_Fianzas__c != null) sub += (sub.length() > 0 ? ' · ' : '') + '$' + c.Suma_Fianzas__c.format();
            results.add(new Map<String,String>{ 'id' => c.Id, 'name' => c.ContractNumber, 'sub' => sub });
        }
        return results;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String,Object>> getVendedoresList() {
        List<Map<String,Object>> result = new List<Map<String,Object>>();
        for (Vendedores__c v : [SELECT Id, Name, Rol__c, CorreoElectronico__c, Telefono__c, Tipo_Agente__c
                                 FROM Vendedores__c ORDER BY Name LIMIT 200]) {
            result.add(new Map<String,Object>{
                'id'         => v.Id,
                'name'       => v.Name,
                'email'      => v.CorreoElectronico__c,
                'tipo'       => v.Rol__c,
                'telefono'   => v.Telefono__c,
                'tipoAgente' => v.Tipo_Agente__c
            });
        }
        return result;
    }

    @AuraEnabled
    public static void deleteRelacion(String relId) {
        try {
            // Si es ID de Tech_Relacion__c, eliminar el registro junction
            Schema.SObjectType sot = ((Id)relId).getSObjectType();
            if (sot == Tech_Relacion__c.sObjectType) {
                delete new Tech_Relacion__c(Id = (Id)relId);
            } else {
                // Fallback: limpiar el lookup directo en Tech_Fianza__c (contrato)
                // No se puede determinar qué campo sin contexto — no-op seguro
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error al eliminar relación: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void addRelacionFianza(String fianzaId, String relatedId, String tipo) {
        try {
            if (tipo == 'Contratista') {
                Tech_Relacion__c rel = new Tech_Relacion__c(
                    Fianza_Tech__c = (Id)fianzaId,
                    Account__c     = (Id)relatedId,
                    Tipo__c        = 'Contratista'
                );
                insert rel;
            } else if (tipo == 'Vendedor') {
                Tech_Relacion__c rel = new Tech_Relacion__c(
                    Fianza_Tech__c = (Id)fianzaId,
                    Vendedor__c    = (Id)relatedId,
                    Tipo__c        = 'Vendedor'
                );
                insert rel;
            } else if (tipo == 'Contrato') {
                // Contrato usa lookup directo en Tech_Fianza__c
                Tech_Fianza__c tf = new Tech_Fianza__c(Id = (Id)fianzaId, Contrato__c = (Id)relatedId);
                update tf;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error al agregar relación: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String guardarEndoso(Map<String,Object> data) {
        try {
            Tech_Endoso__c e = (data.get('id') != null)
                ? new Tech_Endoso__c(Id = (Id)data.get('id'))
                : new Tech_Endoso__c();
            if (data.get('fianzaId')     != null) e.Fianza__c               = (Id)data.get('fianzaId');
            if (data.get('tipo')         != null) e.Tipo_endoso__c          = String.valueOf(data.get('tipo'));
            if (data.get('estado')       != null) e.Estado__c               = String.valueOf(data.get('estado'));
            if (data.get('motivo')       != null) e.Motivo__c               = String.valueOf(data.get('motivo'));
            if (data.get('observaciones')!= null) e.Observaciones__c        = String.valueOf(data.get('observaciones'));
            if (data.get('fechaEfectiva')!= null) e.Fecha_efectiva__c       = Date.valueOf(String.valueOf(data.get('fechaEfectiva')));
            if (data.get('finVigencia')  != null) e.Fin_Vigencia__c         = Date.valueOf(String.valueOf(data.get('finVigencia')));
            if (data.get('nuevoMonto')   != null) e.Nuevo_Monto_Afianzado__c= Decimal.valueOf(String.valueOf(data.get('nuevoMonto')));
            if (data.get('nuevaPrima')   != null) e.Nueva_prima__c          = Decimal.valueOf(String.valueOf(data.get('nuevaPrima')));
            upsert e;
            return e.Id;
        } catch (Exception ex) {
            throw new AuraHandledException('Error al guardar endoso: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static void eliminarEndoso(String endosoId) {
        try {
            delete new Tech_Endoso__c(Id = endosoId);
        } catch (Exception e) {
            throw new AuraHandledException('Error al eliminar endoso: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String guardarComision(Map<String,Object> data) {
        try {
            Tech_Comision__c c = (data.get('id') != null)
                ? new Tech_Comision__c(Id = (Id)data.get('id'))
                : new Tech_Comision__c();
            if (data.get('fianzaId')    != null) c.Fianza__c         = (Id)data.get('fianzaId');
            if (data.get('vendedorId')  != null) c.Vendedor__c       = (Id)data.get('vendedorId');
            if (data.get('estatus')     != null) c.Estatus__c        = String.valueOf(data.get('estatus'));
            if (data.get('pct')         != null) c.Pct_Aplicado__c   = Decimal.valueOf(String.valueOf(data.get('pct')));
            if (data.get('montoOllin')  != null) c.Monto_Ollin__c    = Decimal.valueOf(String.valueOf(data.get('montoOllin')));
            if (data.get('montoVend')   != null) c.Monto_Vendedor__c = Decimal.valueOf(String.valueOf(data.get('montoVend')));
            upsert c;
            return c.Id;
        } catch (Exception ex) {
            throw new AuraHandledException('Error al guardar comisión: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static void marcarReciboCobrado(String reciboId, Decimal montoCobrado, String fechaPago) {
        try {
            Tech_Recibo_Pago__c r = new Tech_Recibo_Pago__c(
                Id = reciboId, Estado__c = 'Cobrado', Monto_cobrado__c = montoCobrado
            );
            if (fechaPago != null) r.Fecha_pago__c = Date.valueOf(fechaPago);
            update r;
        } catch (Exception e) {
            throw new AuraHandledException('Error al registrar cobro: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void eliminarComision(String comisionId) {
        try {
            delete new Tech_Comision__c(Id = comisionId);
        } catch (Exception e) {
            throw new AuraHandledException('Error al eliminar comisión: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String guardarPlan(Map<String,Object> data) {
        try {
            Tech_Plan_de_Pago__c p = (data.get('id') != null)
                ? new Tech_Plan_de_Pago__c(Id = (Id)data.get('id'))
                : new Tech_Plan_de_Pago__c();
            if (data.get('fianzaId')   != null) p.Fianzas__c        = (Id)data.get('fianzaId');
            if (data.get('estatus')    != null) p.Estatus__c        = String.valueOf(data.get('estatus'));
            if (data.get('periodo')    != null) p.Periodo_Pago__c   = String.valueOf(data.get('periodo'));
            if (data.get('metodo')     != null) p.Metodo_Pago__c    = String.valueOf(data.get('metodo'));
            if (data.get('fechaInicio') != null && String.isNotBlank(String.valueOf(data.get('fechaInicio'))))
                p.Fecha_inicio__c = Date.valueOf(String.valueOf(data.get('fechaInicio')));
            if (data.get('montoTotal') != null)
                p.Monto_total__c  = Decimal.valueOf(String.valueOf(data.get('montoTotal')));
            if (data.get('numRecibos') != null)
                p.Num_recibos__c  = Decimal.valueOf(String.valueOf(data.get('numRecibos')));
            upsert p;
            return p.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar plan: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void eliminarPlan(String planId) {
        try {
            delete new Tech_Plan_de_Pago__c(Id = planId);
        } catch (Exception e) {
            throw new AuraHandledException('Error al eliminar plan: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String guardarRecibo(Map<String,Object> data) {
        try {
            Tech_Recibo_Pago__c r = (data.get('id') != null)
                ? new Tech_Recibo_Pago__c(Id = (Id)data.get('id'))
                : new Tech_Recibo_Pago__c();
            if (data.get('planId')   != null) r.Plan_de_Pagos__c    = (Id)data.get('planId');
            if (data.get('estado')   != null) r.Estado__c           = String.valueOf(data.get('estado'));
            if (data.get('numero')   != null)
                r.Numero__c = Decimal.valueOf(String.valueOf(data.get('numero')));
            if (data.get('fechaProg') != null && String.isNotBlank(String.valueOf(data.get('fechaProg'))))
                r.Fecha_programada__c = Date.valueOf(String.valueOf(data.get('fechaProg')));
            if (data.get('montoProg') != null)
                r.Monto_programado__c = Decimal.valueOf(String.valueOf(data.get('montoProg')));
            upsert r;
            return r.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar recibo: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void eliminarRecibo(String reciboId) {
        try {
            delete new Tech_Recibo_Pago__c(Id = reciboId);
        } catch (Exception e) {
            throw new AuraHandledException('Error al eliminar recibo: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String,Object> getSubmodulosFianza(String fianzaId) {
        Id fId = (Id) fianzaId;

        // ── Endosos de la fianza ─────────────────────────────
        List<Tech_Endoso__c> endosos = [
            SELECT Id, Name, Tipo_endoso__c, Estado__c, Fecha_efectiva__c,
                   Diferencia_monto__c, Nuevo_Monto_Afianzado__c, Nueva_prima__c,
                   Fin_Vigencia__c, Motivo__c, Observaciones__c,
                   Convenio__c, Convenio__r.Name
            FROM Tech_Endoso__c
            WHERE Fianza__c = :fId
            ORDER BY CreatedDate DESC
        ];

        List<Map<String,Object>> endososData = new List<Map<String,Object>>();
        for (Tech_Endoso__c en : endosos) {
            String ec = en.Estado__c == 'Aplicado'     ? 'tfi-badge tfi-badge-green'
                      : en.Estado__c == 'Aprobado'     ? 'tfi-badge tfi-badge-blue'
                      : en.Estado__c == 'En revisión'  ? 'tfi-badge tfi-badge-orange'
                      : en.Estado__c == 'Rechazado'    ? 'tfi-badge tfi-badge-red'
                      :                                  'tfi-badge tfi-badge-gray';
            endososData.add(new Map<String,Object>{
                'id'             => en.Id,
                'name'           => en.Name,
                'tipo'           => en.Tipo_endoso__c,
                'estado'         => en.Estado__c,
                'estadoClass'    => ec,
                'fechaEfectiva'  => en.Fecha_efectiva__c    != null ? String.valueOf(en.Fecha_efectiva__c)    : null,
                'diferenciaMonto'=> en.Diferencia_monto__c,
                'nuevoMonto'     => en.Nuevo_Monto_Afianzado__c,
                'nuevaPrima'     => en.Nueva_prima__c,
                'finVigencia'    => en.Fin_Vigencia__c       != null ? String.valueOf(en.Fin_Vigencia__c)      : null,
                'motivo'         => en.Motivo__c,
                'observaciones'  => en.Observaciones__c,
                'convenio'       => en.Convenio__r           != null ? en.Convenio__r.Name                    : null,
                'isAplicado'     => en.Estado__c == 'Aplicado'
            });
        }

        // ── Planes de pago de la fianza ──────────────────────────
        List<Tech_Plan_de_Pago__c> planes = [
            SELECT Id, Name, Estatus__c, Fecha_inicio__c, Monto_total__c,
                   Num_recibos__c, Periodo_Pago__c, Metodo_Pago__c
            FROM Tech_Plan_de_Pago__c
            WHERE Fianzas__c = :fId
            ORDER BY Fecha_inicio__c ASC NULLS LAST
        ];

        // ── Recibos de esos planes ───────────────────────────────
        Set<Id> planIds = (new Map<Id, Tech_Plan_de_Pago__c>(planes)).keySet();
        List<Tech_Recibo_Pago__c> recibos = planIds.isEmpty()
            ? new List<Tech_Recibo_Pago__c>()
            : [
                SELECT Id, Numero__c, Estado__c, Plan_de_Pagos__c,
                       Fecha_programada__c, Fecha_pago__c,
                       Monto_programado__c, Monto_cobrado__c
                FROM Tech_Recibo_Pago__c
                WHERE Plan_de_Pagos__c IN :planIds
                ORDER BY Numero__c ASC NULLS LAST
                LIMIT 200
              ];

        // ── Comisiones de la fianza ──────────────────────────────
        List<Tech_Comision__c> comisiones = [
            SELECT Id, Name, Estatus__c,
                   Monto_Ollin__c, Monto_Vendedor__c, Pct_Aplicado__c,
                   Vendedor__c, Vendedor__r.Name
            FROM Tech_Comision__c
            WHERE Fianza__c = :fId
            ORDER BY CreatedDate ASC
        ];

        // ── Agrupar recibos por plan ─────────────────────────────
        Map<Id, List<Map<String,Object>>> recibosByPlan = new Map<Id, List<Map<String,Object>>>();
        for (Tech_Recibo_Pago__c r : recibos) {
            if (!recibosByPlan.containsKey(r.Plan_de_Pagos__c)) {
                recibosByPlan.put(r.Plan_de_Pagos__c, new List<Map<String,Object>>());
            }
            String ec = r.Estado__c == 'Cobrado'    ? 'tfi-badge-green'
                      : r.Estado__c == 'Vencido'    ? 'tfi-badge-red'
                      : r.Estado__c == 'Parcial'    ? 'tfi-badge-orange'
                      : r.Estado__c == 'Anulado'    ? 'tfi-badge-gray'
                      :                               'tfi-badge-blue';
            recibosByPlan.get(r.Plan_de_Pagos__c).add(new Map<String,Object>{
                'id'          => r.Id,
                'numero'      => r.Numero__c != null ? String.valueOf(r.Numero__c.intValue()) : '—',
                'estado'      => r.Estado__c != null ? r.Estado__c : '—',
                'estadoClass' => ec,
                'fechaProg'   => r.Fecha_programada__c != null ? r.Fecha_programada__c.format() : '—',
                'fechaPago'   => r.Fecha_pago__c       != null ? r.Fecha_pago__c.format()       : '—',
                'montoProg'   => r.Monto_programado__c,
                'montoCob'    => r.Monto_cobrado__c
            });
        }

        // ── Serializar planes ────────────────────────────────────
        List<Map<String,Object>> planesData = new List<Map<String,Object>>();
        for (Tech_Plan_de_Pago__c p : planes) {
            List<Map<String,Object>> pRecs = recibosByPlan.containsKey(p.Id)
                ? recibosByPlan.get(p.Id)
                : new List<Map<String,Object>>();
            String ec = p.Estatus__c == 'Activo' ? 'tfi-badge-green'
                      : p.Estatus__c == 'En mora'? 'tfi-badge-red'
                      :                            'tfi-badge-gray';
            planesData.add(new Map<String,Object>{
                'id'          => p.Id,
                'name'        => p.Name,
                'estatus'     => p.Estatus__c,
                'estatusClass'=> ec,
                'fechaInicio' => p.Fecha_inicio__c != null ? p.Fecha_inicio__c.format() : '—',
                'montoTotal'  => p.Monto_total__c,
                'numRecibos'  => p.Num_recibos__c != null ? String.valueOf(p.Num_recibos__c.intValue()) : '—',
                'periodo'     => p.Periodo_Pago__c,
                'metodo'      => p.Metodo_Pago__c,
                'recibos'     => pRecs,
                'hasRecibos'  => !pRecs.isEmpty()
            });
        }

        // ── Serializar comisiones ────────────────────────────────
        List<Map<String,Object>> comisionesData = new List<Map<String,Object>>();
        Decimal totalOllin = 0; Decimal totalVendedor = 0;
        for (Tech_Comision__c c : comisiones) {
            if (c.Monto_Ollin__c    != null) totalOllin    += c.Monto_Ollin__c;
            if (c.Monto_Vendedor__c != null) totalVendedor += c.Monto_Vendedor__c;
            String cc = c.Estatus__c == 'Pagada'   ? 'tfi-badge tfi-badge-green'
                      : c.Estatus__c == 'Liberada'  ? 'tfi-badge tfi-badge-blue'
                      : c.Estatus__c == 'Revertida' ? 'tfi-badge tfi-badge-red'
                      :                               'tfi-badge tfi-badge-orange';
            comisionesData.add(new Map<String,Object>{
                'id'            => c.Id,
                'vendedorId'    => c.Vendedor__c,
                'vendedor'      => c.Vendedor__r != null ? c.Vendedor__r.Name : '—',
                'estatus'       => c.Estatus__c,
                'estatusClass'  => cc,
                'pct'           => c.Pct_Aplicado__c != null ? c.Pct_Aplicado__c.format() + '%' : '—',
                'montoOllin'    => c.Monto_Ollin__c,
                'montoVendedor' => c.Monto_Vendedor__c
            });
        }

        return new Map<String,Object>{
            'endosos'       => endososData,
            'planes'        => planesData,
            'comisiones'    => comisionesData,
            'totalOllin'    => totalOllin,
            'totalVendedor' => totalVendedor
        };
    }

    @AuraEnabled
    public static String saveFianzaWithRelations(Tech_Fianza__c fianza, Map<String, List<String>> relationsMap) {
        try {
            upsert fianza;
            if (relationsMap != null) {
                Tech_Fianza__c toUpdate = new Tech_Fianza__c(Id = fianza.Id);
                Boolean needsUpdate = false;
                for (String tipo : relationsMap.keySet()) {
                    List<String> ids = relationsMap.get(tipo);
                    if (ids == null || ids.isEmpty()) continue;
                    String relatedId = ids[0];
                    if      (tipo == 'Beneficiario') { toUpdate.Beneficiarios__c = (Id)relatedId; needsUpdate = true; }
                    else if (tipo == 'Afianzadora')  { toUpdate.Afianzadoras__c  = (Id)relatedId; needsUpdate = true; }
                    else if (tipo == 'Contrato')     { toUpdate.Contrato__c      = (Id)relatedId; needsUpdate = true; }
                }
                if (needsUpdate) update toUpdate;
            }
            return fianza.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar fianza y relaciones: ' + e.getMessage());
        }
    }
}