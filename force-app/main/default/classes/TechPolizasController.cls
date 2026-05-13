public with sharing class TechPolizasController {

    // ── Seguros ───────────────────────────────────────────────────────────────

    @AuraEnabled
    public static List<TechPolizasWrapper.PolizaItem> getSeguros() {
        List<Tech_Seguro__c> seguros = [
            SELECT Id, Name,
                   Cliente__c, Cliente__r.Name,
                   Aseguradora__c, Aseguradora__r.Name,
                   Ramo__c, Vendedor__c, Vendedor__r.Name__c, Vendedor__r.Email__c,
                   Prima_neta__c, Inicio_del_seguro__c, Fin_del_seguro__c,
                   Estatus__c
            FROM Tech_Seguro__c
            ORDER BY CreatedDate DESC
            LIMIT 300
        ];

        if (seguros.isEmpty()) return new List<TechPolizasWrapper.PolizaItem>();

        Set<Id> segIds = new Map<Id, Tech_Seguro__c>(seguros).keySet();

        Map<Id, Tech_Plan_de_Pago__c> planBySegId = new Map<Id, Tech_Plan_de_Pago__c>();
        Set<Id> planIds = new Set<Id>();
        for (Tech_Plan_de_Pago__c p : [
            SELECT Id, Name, Estado__c, Monto_total__c, Num_recibos__c,
                   Periodo_Pago__c, Fecha_inicio__c, Metodo_Pago__c, Seguro__c
            FROM Tech_Plan_de_Pago__c
            WHERE Seguro__c IN :segIds
        ]) {
            planBySegId.put(p.Seguro__c, p);
            planIds.add(p.Id);
        }

        Map<Id, List<Tech_Recibo_Pago__c>> recibosByPlanId = new Map<Id, List<Tech_Recibo_Pago__c>>();
        if (!planIds.isEmpty()) {
            for (Tech_Recibo_Pago__c r : [
                SELECT Id, Name, Numero__c, Monto_programado__c, Monto_cobrado__c, Saldo__c,
                       Fecha_programada__c, Fecha_pago__c, Estado__c,
                       Metodo_pago__c, Referencia_pago__c, Intentos_Contacto__c, Motivo_No_Pago__c,
                       Plan_de_Pagos__c
                FROM Tech_Recibo_Pago__c
                WHERE Plan_de_Pagos__c IN :planIds
                ORDER BY Numero__c ASC NULLS LAST
            ]) {
                if (!recibosByPlanId.containsKey(r.Plan_de_Pagos__c)) {
                    recibosByPlanId.put(r.Plan_de_Pagos__c, new List<Tech_Recibo_Pago__c>());
                }
                recibosByPlanId.get(r.Plan_de_Pagos__c).add(r);
            }
        }

        Map<Id, List<Tech_Endoso__c>> endososBySegId = new Map<Id, List<Tech_Endoso__c>>();
        for (Tech_Endoso__c e : [
            SELECT Id, Name, Seguro__c, Fecha_efectiva__c, Diferencia_monto__c, Estado__c,
                   Tipo_endoso__c, Nueva_prima__c, Fin_Vigencia__c, Fin_Contrato__c,
                   Motivo__c, Observaciones__c, Afecta_prima__c, Nueva_modalidad__c
            FROM Tech_Endoso__c
            WHERE Seguro__c IN :segIds
            ORDER BY CreatedDate ASC, Fecha_efectiva__c ASC NULLS LAST
        ]) {
            if (!endososBySegId.containsKey(e.Seguro__c)) {
                endososBySegId.put(e.Seguro__c, new List<Tech_Endoso__c>());
            }
            endososBySegId.get(e.Seguro__c).add(e);
        }

        Date hoy = Date.today();
        List<TechPolizasWrapper.PolizaItem> result = new List<TechPolizasWrapper.PolizaItem>();

        for (Tech_Seguro__c s : seguros) {
            TechPolizasWrapper.PolizaItem item = new TechPolizasWrapper.PolizaItem();
            item.id          = s.Id;
            item.name        = s.Name;
            item.tipo        = 'Seguro';
            item.cliente     = s.Cliente__r != null     ? s.Cliente__r.Name     : null;
            item.aseguradora = s.Aseguradora__r != null ? s.Aseguradora__r.Name : null;
            item.ramo        = s.Ramo__c;
            item.vendedorId      = s.Vendedor__c;
            item.vendedorNombre  = s.Vendedor__r != null ? s.Vendedor__r.Name__c  : null;
            item.vendedorEmail   = s.Vendedor__r != null ? s.Vendedor__r.Email__c : null;
            item.vendedor        = item.vendedorNombre;
            item.prima       = s.Prima_neta__c;
            item.vigenciaInicio = s.Inicio_del_seguro__c != null ? String.valueOf(s.Inicio_del_seguro__c) : null;
            item.vigenciaFin    = s.Fin_del_seguro__c    != null ? String.valueOf(s.Fin_del_seguro__c)    : null;
            item.diasParaVencer = s.Fin_del_seguro__c   != null ? hoy.daysBetween(s.Fin_del_seguro__c)   : null;
            item.estatus     = s.Estatus__c;

            item.endosos = new List<TechPolizasWrapper.EndosoItem>();
            if (endososBySegId.containsKey(s.Id)) {
                for (Tech_Endoso__c e : endososBySegId.get(s.Id)) {
                    TechPolizasWrapper.EndosoItem ei = new TechPolizasWrapper.EndosoItem();
                    ei.id               = e.Id;
                    ei.name             = e.Name;
                    ei.fechaEfectiva    = e.Fecha_efectiva__c != null ? String.valueOf(e.Fecha_efectiva__c) : null;
                    ei.diferenciaMonto  = e.Diferencia_monto__c;
                    ei.estado           = e.Estado__c;
                    ei.tipoEndoso       = e.Tipo_endoso__c;
                    ei.nuevaPrima       = e.Nueva_prima__c;
                    ei.finVigencia      = e.Fin_Vigencia__c    != null ? String.valueOf(e.Fin_Vigencia__c)    : null;
                    ei.finContrato      = e.Fin_Contrato__c    != null ? String.valueOf(e.Fin_Contrato__c)    : null;
                    ei.motivo           = e.Motivo__c;
                    ei.observaciones    = e.Observaciones__c;
                    ei.afectaPrima      = e.Afecta_prima__c;
                    ei.nuevaModalidad   = e.Nueva_modalidad__c;
                    item.endosos.add(ei);
                }
            }

            if (planBySegId.containsKey(s.Id)) {
                Tech_Plan_de_Pago__c p      = planBySegId.get(s.Id);
                TechPolizasWrapper.PlanItem pi = new TechPolizasWrapper.PlanItem();
                pi.id         = p.Id;
                pi.name       = p.Name;
                pi.metodoPago = p.Metodo_Pago__c;
                pi.periodoPago= p.Periodo_Pago__c;
                pi.fechaInicio= p.Fecha_inicio__c != null ? String.valueOf(p.Fecha_inicio__c) : null;
                pi.numRecibos = p.Num_recibos__c  != null ? Integer.valueOf(p.Num_recibos__c) : null;
                pi.estado     = p.Estado__c;
                pi.recibos    = new List<TechPolizasWrapper.ReciboItem>();
                if (recibosByPlanId.containsKey(p.Id)) {
                    for (Tech_Recibo_Pago__c r : recibosByPlanId.get(p.Id)) {
                        TechPolizasWrapper.ReciboItem ri = new TechPolizasWrapper.ReciboItem();
                        ri.id               = r.Id;
                        ri.name             = r.Name;
                        ri.numero           = r.Numero__c != null ? Integer.valueOf(r.Numero__c) : null;
                        ri.monto            = r.Monto_programado__c;
                        ri.montoCobrado     = r.Monto_cobrado__c;
                        ri.saldo            = r.Saldo__c;
                        ri.fechaVencimiento = r.Fecha_programada__c != null ? String.valueOf(r.Fecha_programada__c) : null;
                        ri.fechaPago        = r.Fecha_pago__c       != null ? String.valueOf(r.Fecha_pago__c)       : null;
                        ri.estado            = r.Estado__c;
                        ri.metodoPago        = r.Metodo_pago__c;
                        ri.referenciaPago    = r.Referencia_pago__c;
                        ri.intentosContacto  = r.Intentos_Contacto__c != null ? Integer.valueOf(r.Intentos_Contacto__c) : null;
                        ri.motivoNoPago      = r.Motivo_No_Pago__c;
                        pi.recibos.add(ri);
                    }
                }
                item.planPago = pi;
            }

            result.add(item);
        }
        return result;
    }

    // ── Fianzas & PPR ─────────────────────────────────────────────────────────

    @AuraEnabled
    public static List<TechPolizasWrapper.PolizaItem> getFianzas() {
        List<Tech_Fianza__c> fianzas = [
            SELECT Id, Name,
                   Contratistas__c, Contratistas__r.Name,
                   Beneficiarios__c, Beneficiarios__r.Name,
                   Institucion__c, Institucion__r.Name,
                   Tipo_de_Riesgo__c,
                   Vendedor__c, Vendedor__r.Name__c, Vendedor__r.Email__c,
                   Prima_neta__c, Monto_Afianzado__c, Monto_Afianzado_Vigente__c,
                   Prima_Vigente__c, Fecha_Vencimiento_Vigente__c, Exposicion__c,
                   Fecha_de_Emision__c, Fecha_de_Vencimiento__c,
                   Contrato__c, Estatus__c
            FROM Tech_Fianza__c
            ORDER BY CreatedDate DESC
            LIMIT 300
        ];

        if (fianzas.isEmpty()) return new List<TechPolizasWrapper.PolizaItem>();

        Set<Id> fiIds       = new Map<Id, Tech_Fianza__c>(fianzas).keySet();
        Set<Id> contractIds = new Set<Id>();
        for (Tech_Fianza__c f : fianzas) {
            if (f.Contrato__c != null) contractIds.add(f.Contrato__c);
        }

        // ── Contratos ─────────────────────────────────────────────────────────
        Map<Id, Contract> contractMap = new Map<Id, Contract>();
        if (!contractIds.isEmpty()) {
            for (Contract c : [
                SELECT Id, ContractNumber, Status,
                       Contratista__r.Name, Beneficiario__r.Name,
                       Institucion__r.Name, Tech_Vendedor__r.Name__c,
                       Proyecto__c, Valor_Contrato_Vigente__c,
                       Fin_Contrato_Vigente__c, Suma_Fianzas__c, Exposicion_del__c
                FROM Contract
                WHERE Id IN :contractIds
            ]) { contractMap.put(c.Id, c); }
        }

        // ── Partes relacionadas (Tech_Relacion__c) ────────────────────────────
        Map<Id, List<Tech_Relacion__c>> relacionesByFiId = new Map<Id, List<Tech_Relacion__c>>();
        for (Tech_Relacion__c r : [
            SELECT Id, Tipo__c, Account__r.Name, Fianza_Tech__c
            FROM Tech_Relacion__c
            WHERE Fianza_Tech__c IN :fiIds AND Account__c != null
            ORDER BY Tipo__c ASC NULLS LAST
        ]) {
            if (!relacionesByFiId.containsKey(r.Fianza_Tech__c)) {
                relacionesByFiId.put(r.Fianza_Tech__c, new List<Tech_Relacion__c>());
            }
            relacionesByFiId.get(r.Fianza_Tech__c).add(r);
        }

        // ── Convenios Modificatorios ──────────────────────────────────────────
        Map<Id, List<Tech_Convenio_Modificatorio__c>> conveniosByContractId =
            new Map<Id, List<Tech_Convenio_Modificatorio__c>>();
        if (!contractIds.isEmpty()) {
            for (Tech_Convenio_Modificatorio__c cv : [
                SELECT Id, Name, Contract__c, Fecha_del_Convenio__c,
                       Tipo_de_Modificacion__c, Descripcion__c,
                       Nuevo_Valor_Contrato__c, Nueva_Fecha_Fin__c, Diferencia_Monto__c
                FROM Tech_Convenio_Modificatorio__c
                WHERE Contract__c IN :contractIds
                ORDER BY Fecha_del_Convenio__c ASC NULLS LAST
            ]) {
                if (!conveniosByContractId.containsKey(cv.Contract__c)) {
                    conveniosByContractId.put(cv.Contract__c, new List<Tech_Convenio_Modificatorio__c>());
                }
                conveniosByContractId.get(cv.Contract__c).add(cv);
            }
        }

        // ── Comisiones ────────────────────────────────────────────────────────
        Map<Id, List<Tech_Comision__c>> comisionesByFiId = new Map<Id, List<Tech_Comision__c>>();
        for (Tech_Comision__c com : [
            SELECT Id, Name, Fianza__c, Vendedor__r.Name__c,
                   Pct_Aplicado__c, Monto_Ollin__c, Monto_Vendedor__c, Estatus__c
            FROM Tech_Comision__c
            WHERE Fianza__c IN :fiIds
            ORDER BY CreatedDate ASC
        ]) {
            if (!comisionesByFiId.containsKey(com.Fianza__c)) {
                comisionesByFiId.put(com.Fianza__c, new List<Tech_Comision__c>());
            }
            comisionesByFiId.get(com.Fianza__c).add(com);
        }

        // ── Planes de Pago ────────────────────────────────────────────────────
        Map<Id, Tech_Plan_de_Pago__c> planByFiId = new Map<Id, Tech_Plan_de_Pago__c>();
        Set<Id> planIds = new Set<Id>();
        for (Tech_Plan_de_Pago__c p : [
            SELECT Id, Name, Estado__c, Monto_total__c, Num_recibos__c,
                   Periodo_Pago__c, Fecha_inicio__c, Metodo_Pago__c, Fianzas__c
            FROM Tech_Plan_de_Pago__c
            WHERE Fianzas__c IN :fiIds
        ]) {
            planByFiId.put(p.Fianzas__c, p);
            planIds.add(p.Id);
        }

        Map<Id, List<Tech_Recibo_Pago__c>> recibosByPlanId = new Map<Id, List<Tech_Recibo_Pago__c>>();
        if (!planIds.isEmpty()) {
            for (Tech_Recibo_Pago__c r : [
                SELECT Id, Name, Numero__c, Monto_programado__c, Monto_cobrado__c, Saldo__c,
                       Fecha_programada__c, Fecha_pago__c, Estado__c,
                       Metodo_pago__c, Referencia_pago__c, Intentos_Contacto__c, Motivo_No_Pago__c,
                       Plan_de_Pagos__c
                FROM Tech_Recibo_Pago__c
                WHERE Plan_de_Pagos__c IN :planIds
                ORDER BY Numero__c ASC NULLS LAST
            ]) {
                if (!recibosByPlanId.containsKey(r.Plan_de_Pagos__c)) {
                    recibosByPlanId.put(r.Plan_de_Pagos__c, new List<Tech_Recibo_Pago__c>());
                }
                recibosByPlanId.get(r.Plan_de_Pagos__c).add(r);
            }
        }

        // ── Endosos ───────────────────────────────────────────────────────────
        Map<Id, List<Tech_Endoso__c>> endososByFiId = new Map<Id, List<Tech_Endoso__c>>();
        for (Tech_Endoso__c e : [
            SELECT Id, Name, Fianza__c, Fecha_efectiva__c, Diferencia_monto__c, Estado__c,
                   Tipo_endoso__c, Nuevo_Monto_Afianzado__c, Fin_Vigencia__c, Fin_Contrato__c,
                   Nueva_prima__c, Motivo__c, Observaciones__c, Afecta_prima__c, Nueva_modalidad__c,
                   Convenio__r.Name
            FROM Tech_Endoso__c
            WHERE Fianza__c IN :fiIds
            ORDER BY CreatedDate ASC, Fecha_efectiva__c ASC NULLS LAST
        ]) {
            if (!endososByFiId.containsKey(e.Fianza__c)) {
                endososByFiId.put(e.Fianza__c, new List<Tech_Endoso__c>());
            }
            endososByFiId.get(e.Fianza__c).add(e);
        }

        // ── Mapeo ─────────────────────────────────────────────────────────────
        Date hoy = Date.today();
        List<TechPolizasWrapper.PolizaItem> result = new List<TechPolizasWrapper.PolizaItem>();

        for (Tech_Fianza__c f : fianzas) {
            TechPolizasWrapper.PolizaItem item = new TechPolizasWrapper.PolizaItem();
            item.id          = f.Id;
            item.name        = f.Name;
            item.tipo        = 'Fianza';
            item.cliente     = f.Contratistas__r  != null ? f.Contratistas__r.Name  : null;
            item.beneficiario= f.Beneficiarios__r != null ? f.Beneficiarios__r.Name : null;
            item.aseguradora = f.Institucion__r   != null ? f.Institucion__r.Name   : null;
            item.ramo        = f.Tipo_de_Riesgo__c;
            item.vendedorId      = f.Vendedor__c;
            item.vendedorNombre  = f.Vendedor__r != null ? f.Vendedor__r.Name__c  : null;
            item.vendedorEmail   = f.Vendedor__r != null ? f.Vendedor__r.Email__c : null;
            item.vendedor        = item.vendedorNombre;
            item.prima                  = f.Prima_neta__c;
            item.montoAfianzado         = f.Monto_Afianzado__c;
            item.montoAfianzadoVigente  = f.Monto_Afianzado_Vigente__c;
            item.primaVigente           = f.Prima_Vigente__c;
            item.fechaVencimientoVigente= f.Fecha_Vencimiento_Vigente__c != null
                                          ? String.valueOf(f.Fecha_Vencimiento_Vigente__c) : null;
            item.exposicion             = f.Exposicion__c;
            item.vigenciaInicio = f.Fecha_de_Emision__c    != null ? String.valueOf(f.Fecha_de_Emision__c)    : null;
            item.vigenciaFin    = f.Fecha_de_Vencimiento__c != null ? String.valueOf(f.Fecha_de_Vencimiento__c) : null;
            item.diasParaVencer = f.Fecha_de_Vencimiento__c != null ? hoy.daysBetween(f.Fecha_de_Vencimiento__c) : null;
            item.estatus        = f.Estatus__c;

            // Contrato
            item.contrato = null;
            if (f.Contrato__c != null && contractMap.containsKey(f.Contrato__c)) {
                Contract c = contractMap.get(f.Contrato__c);
                TechPolizasWrapper.ContratoInfo ci = new TechPolizasWrapper.ContratoInfo();
                ci.id          = c.Id;
                ci.name        = c.ContractNumber;
                ci.estatus     = c.Status;
                ci.contratista = c.Contratista__r  != null ? c.Contratista__r.Name       : null;
                ci.beneficiario= c.Beneficiario__r != null ? c.Beneficiario__r.Name      : null;
                ci.institucion = c.Institucion__r  != null ? c.Institucion__r.Name       : null;
                ci.vendedor    = c.Tech_Vendedor__r != null ? c.Tech_Vendedor__r.Name__c : null;
                ci.proyecto    = c.Proyecto__c;
                ci.valorVigente= c.Valor_Contrato_Vigente__c;
                ci.finVigente  = c.Fin_Contrato_Vigente__c != null ? String.valueOf(c.Fin_Contrato_Vigente__c) : null;
                ci.sumaFianzas = c.Suma_Fianzas__c;
                ci.exposicion  = c.Exposicion_del__c;
                item.contrato  = ci;
            }

            // Partes relacionadas
            item.relaciones = new List<TechPolizasWrapper.RelacionItem>();
            if (relacionesByFiId.containsKey(f.Id)) {
                for (Tech_Relacion__c r : relacionesByFiId.get(f.Id)) {
                    TechPolizasWrapper.RelacionItem ri = new TechPolizasWrapper.RelacionItem();
                    ri.id     = r.Id;
                    ri.tipo   = r.Tipo__c;
                    ri.nombre = r.Account__r != null ? r.Account__r.Name : null;
                    item.relaciones.add(ri);
                }
            }

            // Endosos
            item.endosos = new List<TechPolizasWrapper.EndosoItem>();
            if (endososByFiId.containsKey(f.Id)) {
                for (Tech_Endoso__c e : endososByFiId.get(f.Id)) {
                    TechPolizasWrapper.EndosoItem ei = new TechPolizasWrapper.EndosoItem();
                    ei.id             = e.Id;
                    ei.name           = e.Name;
                    ei.fechaEfectiva  = e.Fecha_efectiva__c != null ? String.valueOf(e.Fecha_efectiva__c) : null;
                    ei.diferenciaMonto= e.Diferencia_monto__c;
                    ei.estado         = e.Estado__c;
                    ei.tipoEndoso     = e.Tipo_endoso__c;
                    ei.nuevoMonto     = e.Nuevo_Monto_Afianzado__c;
                    ei.finVigencia    = e.Fin_Vigencia__c    != null ? String.valueOf(e.Fin_Vigencia__c)    : null;
                    ei.finContrato    = e.Fin_Contrato__c    != null ? String.valueOf(e.Fin_Contrato__c)    : null;
                    ei.nuevaPrima     = e.Nueva_prima__c;
                    ei.motivo         = e.Motivo__c;
                    ei.observaciones  = e.Observaciones__c;
                    ei.afectaPrima    = e.Afecta_prima__c;
                    ei.nuevaModalidad = e.Nueva_modalidad__c;
                    ei.convenioNombre = e.Convenio__r != null ? e.Convenio__r.Name : null;
                    item.endosos.add(ei);
                }
            }

            // Convenios
            item.convenios = new List<TechPolizasWrapper.ConvenioItem>();
            if (f.Contrato__c != null && conveniosByContractId.containsKey(f.Contrato__c)) {
                for (Tech_Convenio_Modificatorio__c cv : conveniosByContractId.get(f.Contrato__c)) {
                    TechPolizasWrapper.ConvenioItem cvi = new TechPolizasWrapper.ConvenioItem();
                    cvi.id           = cv.Id;
                    cvi.name         = cv.Name;
                    cvi.fecha        = cv.Fecha_del_Convenio__c != null ? String.valueOf(cv.Fecha_del_Convenio__c) : null;
                    cvi.tipo         = cv.Tipo_de_Modificacion__c;
                    cvi.descripcion  = cv.Descripcion__c;
                    cvi.nuevoValor   = cv.Nuevo_Valor_Contrato__c;
                    cvi.nuevaFechaFin= cv.Nueva_Fecha_Fin__c != null ? String.valueOf(cv.Nueva_Fecha_Fin__c) : null;
                    cvi.diferencia   = cv.Diferencia_Monto__c;
                    item.convenios.add(cvi);
                }
            }

            // Comisiones
            item.comisiones = new List<TechPolizasWrapper.ComisionItem>();
            if (comisionesByFiId.containsKey(f.Id)) {
                for (Tech_Comision__c com : comisionesByFiId.get(f.Id)) {
                    TechPolizasWrapper.ComisionItem comi = new TechPolizasWrapper.ComisionItem();
                    comi.id            = com.Id;
                    comi.name          = com.Name;
                    comi.vendedor      = com.Vendedor__r != null ? com.Vendedor__r.Name__c : null;
                    comi.pctAplicado   = com.Pct_Aplicado__c;
                    comi.montoOllin    = com.Monto_Ollin__c;
                    comi.montoVendedor = com.Monto_Vendedor__c;
                    comi.estatus       = com.Estatus__c;
                    item.comisiones.add(comi);
                }
            }

            // Plan de Pago
            if (planByFiId.containsKey(f.Id)) {
                Tech_Plan_de_Pago__c p      = planByFiId.get(f.Id);
                TechPolizasWrapper.PlanItem pi = new TechPolizasWrapper.PlanItem();
                pi.id         = p.Id;
                pi.name       = p.Name;
                pi.metodoPago = p.Metodo_Pago__c;
                pi.periodoPago= p.Periodo_Pago__c;
                pi.fechaInicio= p.Fecha_inicio__c != null ? String.valueOf(p.Fecha_inicio__c) : null;
                pi.numRecibos = p.Num_recibos__c  != null ? Integer.valueOf(p.Num_recibos__c) : null;
                pi.estado     = p.Estado__c;
                pi.recibos    = new List<TechPolizasWrapper.ReciboItem>();
                if (recibosByPlanId.containsKey(p.Id)) {
                    for (Tech_Recibo_Pago__c r : recibosByPlanId.get(p.Id)) {
                        TechPolizasWrapper.ReciboItem ri = new TechPolizasWrapper.ReciboItem();
                        ri.id               = r.Id;
                        ri.name             = r.Name;
                        ri.numero           = r.Numero__c != null ? Integer.valueOf(r.Numero__c) : null;
                        ri.monto            = r.Monto_programado__c;
                        ri.montoCobrado     = r.Monto_cobrado__c;
                        ri.saldo            = r.Saldo__c;
                        ri.fechaVencimiento = r.Fecha_programada__c != null ? String.valueOf(r.Fecha_programada__c) : null;
                        ri.fechaPago        = r.Fecha_pago__c       != null ? String.valueOf(r.Fecha_pago__c)       : null;
                        ri.estado           = r.Estado__c;
                        ri.metodoPago       = r.Metodo_pago__c;
                        ri.intentosContacto = r.Intentos_Contacto__c != null ? Integer.valueOf(r.Intentos_Contacto__c) : null;
                        ri.motivoNoPago     = r.Motivo_No_Pago__c;
                        pi.recibos.add(ri);
                    }
                }
                item.planPago = pi;
            }

            result.add(item);
        }
        return result;
    }

    // ── Catálogo de vendedores ────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static List<TechPolizasWrapper.VendedorOption> getVendedores() {
        List<TechPolizasWrapper.VendedorOption> result = new List<TechPolizasWrapper.VendedorOption>();
        for (Tech_Vendedor__c v : [
            SELECT Id, Name__c, Email__c
            FROM Tech_Vendedor__c
            ORDER BY Name__c ASC NULLS LAST
        ]) {
            TechPolizasWrapper.VendedorOption opt = new TechPolizasWrapper.VendedorOption();
            opt.id     = v.Id;
            opt.nombre = v.Name__c;
            opt.email  = v.Email__c;
            result.add(opt);
        }
        return result;
    }

    // ── Actualizar vendedor de póliza ─────────────────────────────────────────

    @AuraEnabled
    public static void actualizarVendedor(Id polizaId, String tipo, Id vendedorId) {
        if (tipo == 'Seguro') {
            update new Tech_Seguro__c(Id = polizaId, Vendedor__c = vendedorId);
        } else {
            update new Tech_Fianza__c(Id = polizaId, Vendedor__c = vendedorId);
        }
    }

    // ── Búsqueda de cuentas (para agregar relaciones) ─────────────────────────

    @AuraEnabled
    public static List<TechPolizasWrapper.AccountOption> searchAccounts(String keyword) {
        String q = '%' + String.escapeSingleQuotes(keyword) + '%';
        List<TechPolizasWrapper.AccountOption> result = new List<TechPolizasWrapper.AccountOption>();
        for (Account a : [
            SELECT Id, Name, BillingCity
            FROM Account
            WHERE Name LIKE :q
            ORDER BY Name ASC
            LIMIT 20
        ]) {
            TechPolizasWrapper.AccountOption opt = new TechPolizasWrapper.AccountOption();
            opt.id     = a.Id;
            opt.name   = a.Name;
            opt.ciudad = a.BillingCity;
            result.add(opt);
        }
        return result;
    }

    // ── Agregar relación (Tech_Relacion__c) ───────────────────────────────────

    @AuraEnabled
    public static Id addRelacion(Id fianzaId, String tipo, Id accountId) {
        Tech_Relacion__c r = new Tech_Relacion__c(
            Fianza_Tech__c = fianzaId,
            Tipo__c        = tipo,
            Account__c     = accountId
        );
        insert r;
        return r.Id;
    }

    // ── Eliminar relación ─────────────────────────────────────────────────────

    @AuraEnabled
    public static void removeRelacion(Id relacionId) {
        delete new Tech_Relacion__c(Id = relacionId);
    }

    // ── Búsqueda de contratos ─────────────────────────────────────────────────

    @AuraEnabled
    public static List<TechPolizasWrapper.ContratoOption> searchContratos(String keyword) {
        String q = '%' + String.escapeSingleQuotes(keyword) + '%';
        List<TechPolizasWrapper.ContratoOption> result = new List<TechPolizasWrapper.ContratoOption>();
        for (Contract c : [
            SELECT Id, ContractNumber, Status, Valor_Contrato_Vigente__c, Proyecto__c
            FROM Contract
            WHERE ContractNumber LIKE :q OR Proyecto__c LIKE :q
            ORDER BY ContractNumber ASC
            LIMIT 20
        ]) {
            TechPolizasWrapper.ContratoOption opt = new TechPolizasWrapper.ContratoOption();
            opt.id             = c.Id;
            opt.contractNumber = c.ContractNumber;
            opt.status         = c.Status;
            opt.valor          = c.Valor_Contrato_Vigente__c;
            opt.proyecto       = c.Proyecto__c;
            result.add(opt);
        }
        return result;
    }

    // ── Vincular / desvincular contrato de fianza ─────────────────────────────

    @AuraEnabled
    public static void setContrato(Id fianzaId, Id contratoId) {
        update new Tech_Fianza__c(Id = fianzaId, Contrato__c = contratoId);
    }

    // ── Crear / editar endoso ─────────────────────────────────────────────────

    @AuraEnabled
    public static Id saveEndoso(Tech_Endoso__c endoso) {
        try {
            upsert endoso;
            return endoso.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar endoso: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void deleteEndoso(Id endosoId) {
        try {
            delete new Tech_Endoso__c(Id = endosoId);
        } catch (Exception e) {
            throw new AuraHandledException('Error al eliminar endoso: ' + e.getMessage());
        }
    }

    // ── Actualizar recibo (desde modal de cobro) ───────────────────────────────

    @AuraEnabled
    public static void actualizarRecibo(
        Id      reciboId,
        String  estado,
        String  fechaPago,
        String  fechaProgramada,
        Decimal montoCobrado,
        String  metodoPago,
        String  referenciaPago,
        String  motivoNoPago,
        Integer intentosContacto
    ) {
        Tech_Recibo_Pago__c r = new Tech_Recibo_Pago__c(Id = reciboId);
        if (String.isNotBlank(estado))           r.Estado__c            = estado;
        if (String.isNotBlank(fechaPago)) {
            try { r.Fecha_pago__c = Date.valueOf(fechaPago); } catch (Exception ex) {}
        }
        if (String.isNotBlank(fechaProgramada)) {
            try { r.Fecha_programada__c = Date.valueOf(fechaProgramada); } catch (Exception ex) {}
        }
        if (montoCobrado    != null)             r.Monto_cobrado__c     = montoCobrado;
        if (String.isNotBlank(metodoPago))       r.Metodo_pago__c       = metodoPago;
        if (referenciaPago  != null)             r.Referencia_pago__c   = referenciaPago;
        if (String.isNotBlank(motivoNoPago))     r.Motivo_No_Pago__c    = motivoNoPago;
        if (intentosContacto != null)            r.Intentos_Contacto__c = intentosContacto;
        update r;
    }
}