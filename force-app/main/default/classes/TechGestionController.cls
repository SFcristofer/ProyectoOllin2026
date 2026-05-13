public with sharing class TechGestionController {

    @AuraEnabled(cacheable=true)
    public static TechGestionWrapper getGestionData() {
        TechGestionWrapper w = new TechGestionWrapper();
        w.kpis            = new TechGestionWrapper.KpiBlock();
        w.recibosVencidos     = new List<TechGestionWrapper.ReciboRow>();
        w.recibosPorCobrar    = new List<TechGestionWrapper.ReciboRow>();
        w.recibosCobradosMes  = new List<TechGestionWrapper.ReciboRow>();
        w.recibosPendientesMes = new List<TechGestionWrapper.ReciboRow>();
        w.renovaciones    = new TechGestionWrapper.RenovacionesBlock();
        w.renovaciones.atrasadas    = new List<TechGestionWrapper.SeguroRow>();
        w.renovaciones.mesActual    = new List<TechGestionWrapper.SeguroRow>();
        w.renovaciones.mesSiguiente = new List<TechGestionWrapper.SeguroRow>();

        Date hoy         = Date.today();
        Date iniMes      = Date.newInstance(hoy.year(), hoy.month(), 1);
        Date iniMesSig   = iniMes.addMonths(1);

        // ── KPIs de cobranza ──────────────────────────────────────────────
        AggregateResult[] arVenc = TechGestionSelector.getRecibosVencidosKpi();
        w.kpis.vencidosCount     = (Integer) arVenc[0].get('c');
        w.kpis.vencidosAmountFmt = TechGestionWrapper.fmtMxn((Decimal) arVenc[0].get('s'));

        AggregateResult[] arCobr = TechGestionSelector.getRecibosPorCobrarKpi();
        w.kpis.porCobrarCount     = (Integer) arCobr[0].get('c');
        w.kpis.porCobrarAmountFmt = TechGestionWrapper.fmtMxn((Decimal) arCobr[0].get('s'));

        AggregateResult[] arPag = TechGestionSelector.getRecibosCobradosMesKpi();
        w.kpis.cobradoMesCount     = (Integer) arPag[0].get('c');
        w.kpis.cobradoMesAmountFmt = TechGestionWrapper.fmtMxn((Decimal) arPag[0].get('s'));

        AggregateResult[] arPend = TechGestionSelector.getRecibosPendientesMesKpi();
        w.kpis.pendienteMesCount     = (Integer) arPend[0].get('c');
        w.kpis.pendienteMesAmountFmt = TechGestionWrapper.fmtMxn((Decimal) arPend[0].get('s'));

        // ── Tablas de recibos ─────────────────────────────────────────────
        for (Tech_Recibo_Pago__c r : TechGestionSelector.getRecibosVencidos()) {
            w.recibosVencidos.add(buildReciboRow(r, hoy, false));
        }
        for (Tech_Recibo_Pago__c r : TechGestionSelector.getRecibosPorCobrar()) {
            w.recibosPorCobrar.add(buildReciboRow(r, hoy, false));
        }
        for (Tech_Recibo_Pago__c r : TechGestionSelector.getRecibosCobradosMes()) {
            w.recibosCobradosMes.add(buildReciboRow(r, hoy, true));
        }
        for (Tech_Recibo_Pago__c r : TechGestionSelector.getRecibosPendientesMes()) {
            w.recibosPendientesMes.add(buildReciboRow(r, hoy, false));
        }

        // ── Renovaciones: 3 buckets ───────────────────────────────────────
        Decimal montoAtrasadas = 0, montoMesActual = 0, montoMesSig = 0;

        for (Tech_Seguro__c s : TechGestionSelector.getSegurosParaRenovar()) {
            TechGestionWrapper.SeguroRow row = new TechGestionWrapper.SeguroRow();
            row.id           = s.Id;
            row.tipo         = 'seguro';
            row.numeroPoliza = String.isNotBlank(s.Numero_poliza__c) ? s.Numero_poliza__c : s.Name;
            row.cliente      = s.Cliente__r != null ? s.Cliente__r.Name : '—';
            row.ramo         = s.Ramo__c != null ? s.Ramo__c : '—';
            row.finVigencia  = s.Fin_del_seguro__c != null ? String.valueOf(s.Fin_del_seguro__c) : '—';
            row.primaFmt     = TechGestionWrapper.fmtMxn(s.Prima_neta__c);

            if (s.Fin_del_seguro__c < hoy) {
                Integer atraso = s.Fin_del_seguro__c.daysBetween(hoy);
                row.diasTexto = 'hace ' + atraso + (atraso == 1 ? ' día' : ' días');
                w.renovaciones.atrasadas.add(row);
                montoAtrasadas += (s.Prima_neta__c != null ? s.Prima_neta__c : 0);
            } else if (s.Fin_del_seguro__c < iniMesSig) {
                Integer restantes = hoy.daysBetween(s.Fin_del_seguro__c);
                row.diasTexto = restantes + (restantes == 1 ? ' día' : ' días');
                w.renovaciones.mesActual.add(row);
                montoMesActual += (s.Prima_neta__c != null ? s.Prima_neta__c : 0);
            } else {
                Integer restantes = hoy.daysBetween(s.Fin_del_seguro__c);
                row.diasTexto = restantes + (restantes == 1 ? ' día' : ' días');
                w.renovaciones.mesSiguiente.add(row);
                montoMesSig += (s.Prima_neta__c != null ? s.Prima_neta__c : 0);
            }
        }

        for (Tech_Fianza__c f : TechGestionSelector.getFianzasParaRenovar()) {
            Date finVig = f.Fecha_Vencimiento_Vigente__c != null
                          ? f.Fecha_Vencimiento_Vigente__c : f.Fecha_de_Vencimiento__c;
            if (finVig == null || finVig >= iniMes.addMonths(2)) continue;

            Decimal prima = f.Prima_Vigente__c != null ? f.Prima_Vigente__c : f.Prima_neta__c;

            TechGestionWrapper.SeguroRow row = new TechGestionWrapper.SeguroRow();
            row.id           = f.Id;
            row.tipo         = 'fianza';
            row.numeroPoliza = f.Name;
            row.cliente      = f.Contratistas__r != null ? f.Contratistas__r.Name : '—';
            row.ramo         = f.Tipo_de_Riesgo__c != null ? f.Tipo_de_Riesgo__c : '—';
            row.finVigencia  = String.valueOf(finVig);
            row.primaFmt     = TechGestionWrapper.fmtMxn(prima);

            if (finVig < hoy) {
                Integer atraso = finVig.daysBetween(hoy);
                row.diasTexto = 'hace ' + atraso + (atraso == 1 ? ' día' : ' días');
                w.renovaciones.atrasadas.add(row);
                montoAtrasadas += (prima != null ? prima : 0);
            } else if (finVig < iniMesSig) {
                Integer restantes = hoy.daysBetween(finVig);
                row.diasTexto = restantes + (restantes == 1 ? ' día' : ' días');
                w.renovaciones.mesActual.add(row);
                montoMesActual += (prima != null ? prima : 0);
            } else {
                Integer restantes = hoy.daysBetween(finVig);
                row.diasTexto = restantes + (restantes == 1 ? ' día' : ' días');
                w.renovaciones.mesSiguiente.add(row);
                montoMesSig += (prima != null ? prima : 0);
            }
        }

        w.kpis.atrasadasCount          = w.renovaciones.atrasadas.size();
        w.kpis.atrasadasAmountFmt       = TechGestionWrapper.fmtMxn(montoAtrasadas);
        w.kpis.renovMesActualCount      = w.renovaciones.mesActual.size();
        w.kpis.renovMesActualAmountFmt  = TechGestionWrapper.fmtMxn(montoMesActual);
        w.kpis.renovMesSigCount         = w.renovaciones.mesSiguiente.size();

        return w;
    }

    private static TechGestionWrapper.ReciboRow buildReciboRow(Tech_Recibo_Pago__c r, Date hoy, Boolean isCobrado) {
        TechGestionWrapper.ReciboRow row = new TechGestionWrapper.ReciboRow();
        row.id     = r.Id;
        row.numero = r.Numero__c != null ? String.valueOf(r.Numero__c) : '—';

        // Path 1: recibo ligado directamente a Tech_Seguro__c
        Boolean esSeguroDirecto = r.Seguro__r != null;
        // Path 2: recibo ligado a Plan_de_Pago → Tech_Seguro__c
        Boolean esSeguroPlan = !esSeguroDirecto
                               && r.Plan_de_Pagos__r != null
                               && r.Plan_de_Pagos__r.Seguro__r != null;
        // Path 3: recibo ligado a Plan_de_Pago → Tech_Fianza__c
        Boolean esFianza = !esSeguroDirecto && !esSeguroPlan
                           && r.Plan_de_Pagos__r != null
                           && r.Plan_de_Pagos__r.Fianzas__r != null;

        row.tipo = esFianza ? 'fianza' : 'seguro';

        String polizaNum = null, ramo = null, clienteNom = null;

        // ── Póliza y ramo ────────────────────────────────────────────────────
        if (esSeguroDirecto) {
            polizaNum = String.isNotBlank(r.Seguro__r.Numero_poliza__c) ? r.Seguro__r.Numero_poliza__c : r.Seguro__r.Name;
            ramo      = r.Seguro__r.Ramo__c;
        } else if (esSeguroPlan) {
            Tech_Seguro__c s = r.Plan_de_Pagos__r.Seguro__r;
            polizaNum = String.isNotBlank(s.Numero_poliza__c) ? s.Numero_poliza__c : s.Name;
            ramo      = s.Ramo__c;
        } else if (esFianza) {
            polizaNum = r.Plan_de_Pagos__r.Fianzas__r.Name;
            ramo      = r.Plan_de_Pagos__r.Fianzas__r.Tipo_de_Riesgo__c;
        }
        if (polizaNum == null && String.isNotBlank(r.Poliza_numero__c)) {
            polizaNum = r.Poliza_numero__c;
        }

        // ── Cliente — busca en todos los paths disponibles ───────────────────
        if (esSeguroDirecto && r.Seguro__r.Cliente__r != null) {
            clienteNom = r.Seguro__r.Cliente__r.Name;
        }
        if (clienteNom == null && r.Plan_de_Pagos__r != null) {
            if (r.Plan_de_Pagos__r.Seguro__r != null && r.Plan_de_Pagos__r.Seguro__r.Cliente__r != null) {
                clienteNom = r.Plan_de_Pagos__r.Seguro__r.Cliente__r.Name;
            } else if (r.Plan_de_Pagos__r.Fianzas__r != null && r.Plan_de_Pagos__r.Fianzas__r.Contratistas__r != null) {
                clienteNom = r.Plan_de_Pagos__r.Fianzas__r.Contratistas__r.Name;
            }
        }

        row.poliza  = polizaNum  != null ? polizaNum  : '—';
        row.ramo    = ramo       != null ? ramo        : '—';
        row.cliente = clienteNom != null ? clienteNom : '—';

        if (isCobrado) {
            row.fechaFmt = r.Fecha_pago__c != null ? String.valueOf(r.Fecha_pago__c) : '—';
            row.montoFmt = TechGestionWrapper.fmtMxn(r.Monto_cobrado__c);
            row.diasMora = 0;
            row.semaforoClass = '';
        } else {
            row.fechaFmt = r.Fecha_programada__c != null ? String.valueOf(r.Fecha_programada__c) : '—';
            row.montoFmt = TechGestionWrapper.fmtMxn(r.Monto_programado__c);
            Integer mora = r.Fecha_programada__c != null ? r.Fecha_programada__c.daysBetween(hoy) : 0;
            row.diasMora = mora > 0 ? mora : 0;
            row.semaforoClass = mora > 30 ? 'tg-sem-rojo' : (mora > 7 ? 'tg-sem-amarillo' : 'tg-sem-naranja');
        }
        return row;
    }

    @AuraEnabled
    public static void marcarNoRenovada(String seguroId) {
        if (String.isBlank(seguroId)) {
            throw new AuraHandledException('ID requerido.');
        }
        try {
            Id recId    = (Id) seguroId;
            String tipo = recId.getSObjectType().getDescribe().getName();
            if (tipo == 'Tech_Seguro__c') {
                update new Tech_Seguro__c(Id = recId, Estatus__c = 'Cancelada');
            } else if (tipo == 'Tech_Fianza__c') {
                update new Tech_Fianza__c(Id = recId, Estatus__c = 'Cancelada');
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error al actualizar: ' + e.getMessage());
        }
    }
}