public without sharing class TechPlanPagoService {

    /*
     * =====================================================================================
     * CLASE: TechPlanPagoService
     * =====================================================================================
     *
     * Objetivo:
     * - Generar Planes de Pago y Recibos para Seguros y Fianzas.
     * - Para Seguros, el monto base es Tech_Seguro__c.Prima_neta__c.
     * - Para Fianzas, el monto base es Tech_Fianza__c.Prima_neta__c o Prima_Vigente__c.
     *
     * Reglas:
     * - No duplicar planes si ya existe uno para el Seguro o Fianza.
     * - Los recibos se generan con Fecha_programada__c.
     * - Pendiente_de_Pago__c inicia con el monto total del plan.
     */

    private static final String ESTADO_PLAN_ACTIVO = 'Activo';
    private static final String ESTADO_RECIBO_PROGRAMADO = 'Programado';

    public static void generarPlanesYRecibosPorSeguroIds(Set<Id> seguroIds) {

        if (seguroIds == null || seguroIds.isEmpty()) {
            return;
        }

        Map<Id, Tech_Seguro__c> seguros = new Map<Id, Tech_Seguro__c>([
            SELECT Id,
                   Prima_neta__c,
                   Forma_pago__c,
                   Frecuencia_de_pago__c,
                   Inicio_del_seguro__c,
                   Fin_del_seguro__c
            FROM Tech_Seguro__c
            WHERE Id IN :seguroIds
        ]);

        Set<Id> segurosConPlan = new Set<Id>();

        for (Tech_Plan_de_Pago__c plan : [
            SELECT Id,
                   Seguro__c
            FROM Tech_Plan_de_Pago__c
            WHERE Seguro__c IN :seguroIds
        ]) {
            segurosConPlan.add(plan.Seguro__c);
        }

        List<Tech_Plan_de_Pago__c> planesPorInsertar =
            new List<Tech_Plan_de_Pago__c>();

        for (Tech_Seguro__c seguro : seguros.values()) {

            if (segurosConPlan.contains(seguro.Id)) {
                continue;
            }

            Decimal montoTotal = seguro.Prima_neta__c;

            if (montoTotal == null || montoTotal <= 0) {
                continue;
            }

            String periodo = seguro.Frecuencia_de_pago__c;

            if (String.isBlank(periodo)) {
                periodo = 'Contado';
            }

            Date fechaInicio = seguro.Inicio_del_seguro__c;
            Date fechaFin = seguro.Fin_del_seguro__c;

            Integer numeroRecibos = calcularNumeroRecibos(
                fechaInicio,
                fechaFin,
                periodo
            );

            Tech_Plan_de_Pago__c plan = new Tech_Plan_de_Pago__c();

            plan.Seguro__c = seguro.Id;
            plan.Periodo_Pago__c = periodo;
            plan.Num_recibos__c = numeroRecibos;
            plan.Monto_total__c = montoTotal;
            plan.Fecha_Inicio__c = fechaInicio;

            setIfWritable(plan, 'Estado__c', ESTADO_PLAN_ACTIVO);
            setIfWritable(plan, 'Estatus__c', ESTADO_PLAN_ACTIVO);
            setIfWritable(plan, 'Pendiente_de_Pago__c', montoTotal);

            planesPorInsertar.add(plan);
        }

        insertarPlanesYRecibos(planesPorInsertar);
    }

    public static void generarPlanesYRecibosPorFianzaIds(Set<Id> fianzaIds) {

        if (fianzaIds == null || fianzaIds.isEmpty()) {
            return;
        }

        Map<Id, Tech_Fianza__c> fianzas = new Map<Id, Tech_Fianza__c>([
            SELECT Id,
                   Prima_neta__c,
                   Prima_Vigente__c,
                   Periodo_Pago__c,
                   Fecha_de_Emision__c,
                   Fecha_de_Vencimiento__c,
                   Fecha_Vencimiento_Vigente__c
            FROM Tech_Fianza__c
            WHERE Id IN :fianzaIds
        ]);

        Set<Id> fianzasConPlan = new Set<Id>();

        for (Tech_Plan_de_Pago__c plan : [
            SELECT Id,
                   Fianzas__c
            FROM Tech_Plan_de_Pago__c
            WHERE Fianzas__c IN :fianzaIds
        ]) {
            fianzasConPlan.add(plan.Fianzas__c);
        }

        List<Tech_Plan_de_Pago__c> planesPorInsertar =
            new List<Tech_Plan_de_Pago__c>();

        for (Tech_Fianza__c fianza : fianzas.values()) {

            if (fianzasConPlan.contains(fianza.Id)) {
                continue;
            }

            Decimal montoTotal =
                fianza.Prima_Vigente__c != null && fianza.Prima_Vigente__c > 0
                ? fianza.Prima_Vigente__c
                : fianza.Prima_neta__c;

            if (montoTotal == null || montoTotal <= 0) {
                continue;
            }

            String periodo = fianza.Periodo_Pago__c;

            if (String.isBlank(periodo)) {
                periodo = 'Contado';
            }

            Date fechaInicio = fianza.Fecha_de_Emision__c;

            Date fechaFin =
                fianza.Fecha_Vencimiento_Vigente__c != null
                ? fianza.Fecha_Vencimiento_Vigente__c
                : fianza.Fecha_de_Vencimiento__c;

            Integer numeroRecibos = calcularNumeroRecibos(
                fechaInicio,
                fechaFin,
                periodo
            );

            Tech_Plan_de_Pago__c plan = new Tech_Plan_de_Pago__c();

            plan.Fianzas__c = fianza.Id;
            plan.Periodo_Pago__c = periodo;
            plan.Num_recibos__c = numeroRecibos;
            plan.Monto_total__c = montoTotal;
            plan.Fecha_Inicio__c = fechaInicio;

            setIfWritable(plan, 'Estado__c', ESTADO_PLAN_ACTIVO);
            setIfWritable(plan, 'Estatus__c', ESTADO_PLAN_ACTIVO);
            setIfWritable(plan, 'Pendiente_de_Pago__c', montoTotal);

            planesPorInsertar.add(plan);
        }

        insertarPlanesYRecibos(planesPorInsertar);
    }

    private static void insertarPlanesYRecibos(
        List<Tech_Plan_de_Pago__c> planesPorInsertar
    ) {

        if (planesPorInsertar == null || planesPorInsertar.isEmpty()) {
            return;
        }

        insert planesPorInsertar;

        List<Tech_Recibo_Pago__c> recibosPorInsertar =
            new List<Tech_Recibo_Pago__c>();

        for (Tech_Plan_de_Pago__c plan : planesPorInsertar) {

            recibosPorInsertar.addAll(
                construirRecibos(plan)
            );
        }

        if (!recibosPorInsertar.isEmpty()) {
            insert recibosPorInsertar;
        }
    }

    private static List<Tech_Recibo_Pago__c> construirRecibos(
        Tech_Plan_de_Pago__c plan
    ) {

        List<Tech_Recibo_Pago__c> recibos =
            new List<Tech_Recibo_Pago__c>();

        if (
            plan == null ||
            plan.Id == null ||
            plan.Monto_total__c == null ||
            plan.Monto_total__c <= 0 ||
            plan.Num_recibos__c == null ||
            plan.Num_recibos__c <= 0
        ) {
            return recibos;
        }

        Integer numeroRecibos = plan.Num_recibos__c.intValue();
        Decimal montoTotal = plan.Monto_total__c;

        Decimal montoBase =
            (montoTotal / Decimal.valueOf(numeroRecibos)).setScale(2);

        Decimal acumulado = 0;

        Integer diasPorPeriodo = obtenerDiasPorPeriodo(plan.Periodo_Pago__c);

        Date fechaBase =
            plan.Fecha_Inicio__c != null
            ? plan.Fecha_Inicio__c
            : Date.today();

        for (Integer i = 1; i <= numeroRecibos; i++) {

            Decimal montoRecibo;

            if (i < numeroRecibos) {
                montoRecibo = montoBase;
                acumulado += montoBase;
            } else {
                montoRecibo = (montoTotal - acumulado).setScale(2);
            }

            Date fechaProgramada =
                diasPorPeriodo == 0
                ? fechaBase
                : fechaBase.addDays(diasPorPeriodo * i);

            Tech_Recibo_Pago__c recibo = new Tech_Recibo_Pago__c();

            recibo.Plan_de_Pagos__c = plan.Id;
            recibo.Numero__c = i;
            recibo.Fecha_programada__c = fechaProgramada;
            recibo.Monto_programado__c = montoRecibo;
            recibo.Estado__c = ESTADO_RECIBO_PROGRAMADO;
//            recibo.Periodo_Pago__c = plan.Periodo_Pago__c;
//            recibo.Saldo__c = montoRecibo;

            if (plan.Seguro__c != null) {
                recibo.Seguro__c = plan.Seguro__c;
            }

            recibos.add(recibo);
        }

        return recibos;
    }

    private static Integer calcularNumeroRecibos(
        Date fechaInicio,
        Date fechaFin,
        String periodo
    ) {

        if (String.isBlank(periodo) || periodo == 'Contado') {
            return 1;
        }

        if (fechaInicio == null || fechaFin == null || fechaFin <= fechaInicio) {
            return 1;
        }

        Integer diasPorPeriodo = obtenerDiasPorPeriodo(periodo);

        if (diasPorPeriodo <= 0) {
            return 1;
        }

        Integer duracionDias = fechaInicio.daysBetween(fechaFin);

        Decimal numero =
            Decimal.valueOf(duracionDias) /
            Decimal.valueOf(diasPorPeriodo);

        Integer recibos =
            numero.setScale(0, System.RoundingMode.CEILING).intValue();

        return recibos <= 0 ? 1 : recibos;
    }

    private static Integer obtenerDiasPorPeriodo(String periodo) {

        if (String.isBlank(periodo)) {
            return 0;
        }

        if (periodo == 'Contado') {
            return 0;
        }

        if (periodo == 'Mensual') {
            return 30;
        }

        if (periodo == 'Bimestral') {
            return 60;
        }

        if (periodo == 'Trimestral') {
            return 90;
        }

        if (periodo == 'Semestral') {
            return 180;
        }

        if (periodo == 'Anual') {
            return 365;
        }

        return 30;
    }

    private static void setIfWritable(
        SObject registro,
        String campo,
        Object valor
    ) {

        if (registro == null || String.isBlank(campo)) {
            return;
        }

        Map<String, Schema.SObjectField> campos =
            registro.getSObjectType().getDescribe().fields.getMap();

        if (!campos.containsKey(campo)) {
            return;
        }

        Schema.DescribeFieldResult d = campos.get(campo).getDescribe();

        if (!d.isCreateable() && !d.isUpdateable()) {
            return;
        }

        registro.put(campo, valor);
    }
}