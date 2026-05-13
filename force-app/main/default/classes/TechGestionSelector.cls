public with sharing class TechGestionSelector {

    public static AggregateResult[] getRecibosVencidosKpi() {
        return [
            SELECT COUNT(Id) c, SUM(Monto_programado__c) s
            FROM Tech_Recibo_Pago__c
            WHERE Estado__c = 'Vencido'
        ];
    }

    public static AggregateResult[] getRecibosPorCobrarKpi() {
        Date today = Date.today();
        return [
            SELECT COUNT(Id) c, SUM(Monto_programado__c) s
            FROM Tech_Recibo_Pago__c
            WHERE Estado__c = 'Por cobrar'
            AND Fecha_programada__c >= :today
        ];
    }

    public static AggregateResult[] getRecibosCobradosMesKpi() {
        Date hoy = Date.today();
        Date ini = Date.newInstance(hoy.year(), hoy.month(), 1);
        Date fin = ini.addMonths(1);
        return [
            SELECT COUNT(Id) c, SUM(Monto_cobrado__c) s
            FROM Tech_Recibo_Pago__c
            WHERE Estado__c = 'Cobrado'
            AND Fecha_pago__c >= :ini
            AND Fecha_pago__c < :fin
        ];
    }

    public static AggregateResult[] getRecibosPendientesMesKpi() {
        Date hoy = Date.today();
        Date ini = Date.newInstance(hoy.year(), hoy.month(), 1);
        Date fin = ini.addMonths(1);
        return [
            SELECT COUNT(Id) c, SUM(Monto_programado__c) s
            FROM Tech_Recibo_Pago__c
            WHERE Estado__c IN ('Programado', 'Por cobrar')
            AND Fecha_programada__c >= :ini
            AND Fecha_programada__c < :fin
        ];
    }

    private static final String RECIBO_FIELDS =
        'Id, Numero__c, Fecha_programada__c, Monto_programado__c, Fecha_pago__c, Monto_cobrado__c, ' +
        'Seguro__r.Numero_poliza__c, Seguro__r.Name, Seguro__r.Ramo__c, Seguro__r.Cliente__r.Name, ' +
        'Plan_de_Pagos__r.Seguro__r.Numero_poliza__c, Plan_de_Pagos__r.Seguro__r.Name, ' +
        'Plan_de_Pagos__r.Seguro__r.Ramo__c, Plan_de_Pagos__r.Seguro__r.Cliente__r.Name, ' +
        'Plan_de_Pagos__r.Fianzas__r.Name, Plan_de_Pagos__r.Fianzas__r.Tipo_de_Riesgo__c, ' +
        'Plan_de_Pagos__r.Fianzas__r.Contratistas__r.Name';

    public static List<Tech_Recibo_Pago__c> getRecibosVencidos() {
        return [
            SELECT Id, Numero__c, Poliza_numero__c, Fecha_programada__c, Monto_programado__c, Fecha_pago__c, Monto_cobrado__c,
                   Seguro__r.Numero_poliza__c, Seguro__r.Name, Seguro__r.Ramo__c,
                   Seguro__r.Cliente__r.Name,
                   Plan_de_Pagos__r.Seguro__r.Numero_poliza__c, Plan_de_Pagos__r.Seguro__r.Name,
                   Plan_de_Pagos__r.Seguro__r.Ramo__c, Plan_de_Pagos__r.Seguro__r.Cliente__r.Name,
                   Plan_de_Pagos__r.Fianzas__r.Name, Plan_de_Pagos__r.Fianzas__r.Tipo_de_Riesgo__c,
                   Plan_de_Pagos__r.Fianzas__r.Contratistas__r.Name
            FROM Tech_Recibo_Pago__c
            WHERE Estado__c = 'Vencido'
            ORDER BY Fecha_programada__c ASC
            LIMIT 200
        ];
    }

    public static List<Tech_Recibo_Pago__c> getRecibosPorCobrar() {
        Date today = Date.today();
        return [
            SELECT Id, Numero__c, Poliza_numero__c, Fecha_programada__c, Monto_programado__c, Fecha_pago__c, Monto_cobrado__c,
                   Seguro__r.Numero_poliza__c, Seguro__r.Name, Seguro__r.Ramo__c,
                   Seguro__r.Cliente__r.Name,
                   Plan_de_Pagos__r.Seguro__r.Numero_poliza__c, Plan_de_Pagos__r.Seguro__r.Name,
                   Plan_de_Pagos__r.Seguro__r.Ramo__c, Plan_de_Pagos__r.Seguro__r.Cliente__r.Name,
                   Plan_de_Pagos__r.Fianzas__r.Name, Plan_de_Pagos__r.Fianzas__r.Tipo_de_Riesgo__c,
                   Plan_de_Pagos__r.Fianzas__r.Contratistas__r.Name
            FROM Tech_Recibo_Pago__c
            WHERE Estado__c = 'Por cobrar'
            AND Fecha_programada__c >= :today
            ORDER BY Fecha_programada__c ASC
            LIMIT 100
        ];
    }

    public static List<Tech_Recibo_Pago__c> getRecibosCobradosMes() {
        Date hoy = Date.today();
        Date ini = Date.newInstance(hoy.year(), hoy.month(), 1);
        Date fin = ini.addMonths(1);
        return [
            SELECT Id, Numero__c, Poliza_numero__c, Fecha_programada__c, Monto_programado__c, Fecha_pago__c, Monto_cobrado__c,
                   Seguro__r.Numero_poliza__c, Seguro__r.Name, Seguro__r.Ramo__c,
                   Seguro__r.Cliente__r.Name,
                   Plan_de_Pagos__r.Seguro__r.Numero_poliza__c, Plan_de_Pagos__r.Seguro__r.Name,
                   Plan_de_Pagos__r.Seguro__r.Ramo__c, Plan_de_Pagos__r.Seguro__r.Cliente__r.Name,
                   Plan_de_Pagos__r.Fianzas__r.Name, Plan_de_Pagos__r.Fianzas__r.Tipo_de_Riesgo__c,
                   Plan_de_Pagos__r.Fianzas__r.Contratistas__r.Name
            FROM Tech_Recibo_Pago__c
            WHERE Estado__c = 'Cobrado'
            AND Fecha_pago__c >= :ini
            AND Fecha_pago__c < :fin
            ORDER BY Fecha_pago__c DESC
            LIMIT 100
        ];
    }

    public static List<Tech_Recibo_Pago__c> getRecibosPendientesMes() {
        Date hoy = Date.today();
        Date ini = Date.newInstance(hoy.year(), hoy.month(), 1);
        Date fin = ini.addMonths(1);
        return [
            SELECT Id, Numero__c, Poliza_numero__c, Fecha_programada__c, Monto_programado__c, Fecha_pago__c, Monto_cobrado__c,
                   Seguro__r.Numero_poliza__c, Seguro__r.Name, Seguro__r.Ramo__c,
                   Seguro__r.Cliente__r.Name,
                   Plan_de_Pagos__r.Seguro__r.Numero_poliza__c, Plan_de_Pagos__r.Seguro__r.Name,
                   Plan_de_Pagos__r.Seguro__r.Ramo__c, Plan_de_Pagos__r.Seguro__r.Cliente__r.Name,
                   Plan_de_Pagos__r.Fianzas__r.Name, Plan_de_Pagos__r.Fianzas__r.Tipo_de_Riesgo__c,
                   Plan_de_Pagos__r.Fianzas__r.Contratistas__r.Name
            FROM Tech_Recibo_Pago__c
            WHERE Estado__c IN ('Programado', 'Por cobrar')
            AND Fecha_programada__c >= :ini
            AND Fecha_programada__c < :fin
            ORDER BY Fecha_programada__c ASC
            LIMIT 100
        ];
    }

    public static List<Tech_Fianza__c> getFianzasParaRenovar() {
        Date hoy  = Date.today();
        Date ini  = Date.newInstance(hoy.year(), hoy.month(), 1);
        Date tope = ini.addMonths(2);
        return [
            SELECT Id, Name, Tipo_de_Riesgo__c,
                   Fecha_Vencimiento_Vigente__c, Fecha_de_Vencimiento__c,
                   Prima_Vigente__c, Prima_neta__c,
                   Contratistas__r.Name, Estatus__c
            FROM Tech_Fianza__c
            WHERE Estatus__c IN ('Emitida', 'Vigente')
            AND (Fecha_Vencimiento_Vigente__c < :tope OR Fecha_de_Vencimiento__c < :tope)
            ORDER BY Fecha_Vencimiento_Vigente__c ASC NULLS LAST, Fecha_de_Vencimiento__c ASC NULLS LAST
            LIMIT 500
        ];
    }

    public static List<Tech_Seguro__c> getSegurosParaRenovar() {
        Date hoy  = Date.today();
        Date ini  = Date.newInstance(hoy.year(), hoy.month(), 1);
        Date tope = ini.addMonths(2);
        return [
            SELECT Id, Name, Numero_poliza__c, Ramo__c, Fin_del_seguro__c,
                   Prima_neta__c, Cliente__r.Name, Estatus__c
            FROM Tech_Seguro__c
            WHERE Estatus__c IN ('Vigente', 'Por renovar')
            AND Fin_del_seguro__c < :tope
            ORDER BY Fin_del_seguro__c ASC
            LIMIT 500
        ];
    }
}