public without sharing class TechEndosoTriggerHandler {

    /*
     * =====================================================================================
     * CLASE: TechEndosoTriggerHandler
     * =====================================================================================
     *
     * Objetivo:
     * - Procesar endosos de Seguro y Fianza.
     * - Solo se ejecutan endosos con Estado__c = 'Aprobado'.
     * - Al finalizar se actualizan a Estado__c = 'Aplicado'.
     *
     * Reglas principales:
     * - Si afecta prima y existen recibos futuros desde Fecha_efectiva__c:
     *      Ajusta recibos futuros.
     *
     * - Si afecta prima y Fecha_efectiva__c es posterior al último recibo programado:
     *      Crea un nuevo Tech_Plan_de_Pago__c complementario.
     *      Crea un solo Tech_Recibo_Pago__c en una sola exhibición.
     *
     * - El monto complementario se calcula como:
     *      Nueva_prima__c - suma de recibos no anulados del plan actual.
     *
     * - Si la diferencia es negativa y ya no existen pagos futuros:
     *      No genera recibo. Se recomienda gestionar como devolución o nota de crédito.
     */

    private static Boolean enEjecucionAfter = false;
    private static Boolean marcandoAplicado = false;

    private static final String ESTADO_APROBADO = 'Aprobado';
    private static final String ESTADO_APLICADO = 'Aplicado';
    private static final String ESTADO_ANULADO = 'Anulado';
    private static final String ESTADO_CANCELADO = 'Cancelado';

    private static final String ESTADO_PLAN_ACTIVO = 'Activo';
    private static final String ESTADO_PLAN_MORA = 'En mora';

    private static final String ESTADO_RECIBO_PROGRAMADO = 'Programado';

    private static final Set<String> ESTADOS_RECIBO_AJUSTABLES =
        new Set<String>{
            'Programado',
            'Por cobrar',
            'Pendiente'
        };

    /*
     * =====================================================================================
     * BEFORE INSERT / BEFORE UPDATE
     * =====================================================================================
     */
    public static void beforeSave(
        List<Tech_Endoso__c> nuevosEndosos,
        Map<Id, Tech_Endoso__c> endososAnteriores
    ) {

        if (marcandoAplicado) {
            return;
        }

        if (nuevosEndosos == null || nuevosEndosos.isEmpty()) {
            return;
        }

        Set<Id> fianzaIds = new Set<Id>();
        Set<Id> seguroIds = new Set<Id>();

        for (Tech_Endoso__c endoso : nuevosEndosos) {

            if (endoso == null) {
                continue;
            }

            Id fianzaId = getId(endoso, 'Fianza__c');
            Id seguroId = getId(endoso, 'Seguro__c');

            if (fianzaId != null) {
                fianzaIds.add(fianzaId);
            }

            if (seguroId != null) {
                seguroIds.add(seguroId);
            }
        }

        Map<Id, SObject> fianzasPorId = obtenerFianzas(fianzaIds);
        Map<Id, SObject> segurosPorId = obtenerSeguros(seguroIds);

        for (Tech_Endoso__c endoso : nuevosEndosos) {

            if (endoso == null) {
                continue;
            }

            if (
                endososAnteriores != null &&
                endoso.Id != null &&
                endososAnteriores.containsKey(endoso.Id)
            ) {
                Tech_Endoso__c anterior = endososAnteriores.get(endoso.Id);

                if (
                    getString(anterior, 'Estado__c') == ESTADO_APLICADO &&
                    getString(endoso, 'Estado__c') == ESTADO_APLICADO
                ) {
                    endoso.addError(
                        'No se puede modificar un endoso que ya fue aplicado.'
                    );
                    continue;
                }
            }

            Id fianzaId = getId(endoso, 'Fianza__c');
            Id seguroId = getId(endoso, 'Seguro__c');

            Boolean tieneFianza = fianzaId != null;
            Boolean tieneSeguro = seguroId != null;

            if (!tieneFianza && !tieneSeguro) {
                endoso.addError(
                    'El endoso debe estar relacionado con una Fianza o con un Seguro.'
                );
                continue;
            }

            if (tieneFianza && tieneSeguro) {
                endoso.addError(
                    'El endoso no puede estar relacionado al mismo tiempo con Fianza y Seguro.'
                );
                continue;
            }

            Date fechaEfectiva = getDate(endoso, 'Fecha_efectiva__c');
            Date finVigencia = getDate(endoso, 'Fin_Vigencia__c');

            if (
                fechaEfectiva != null &&
                finVigencia != null &&
                finVigencia <= fechaEfectiva
            ) {
                endoso.addError(
                    'La fecha fin de vigencia del endoso debe ser mayor que la fecha efectiva.'
                );
                continue;
            }

            Boolean afectaPrima = getBoolean(endoso, 'Afecta_prima__c');

            if (afectaPrima == true) {

                Decimal nuevaPrima = getDecimal(endoso, 'Nueva_prima__c');

                if (nuevaPrima == null || nuevaPrima <= 0) {
                    endoso.addError(
                        'Si el endoso afecta prima, debes capturar una Nueva Prima mayor a cero.'
                    );
                    continue;
                }

                if (fechaEfectiva == null) {
                    endoso.addError(
                        'Si el endoso afecta prima, debes capturar la Fecha Efectiva.'
                    );
                    continue;
                }

                Decimal primaActual = null;

                if (fianzaId != null && fianzasPorId.containsKey(fianzaId)) {
                    SObject fianza = fianzasPorId.get(fianzaId);

                    primaActual = getDecimal(fianza, 'Prima_Vigente__c');

                    if (primaActual == null || primaActual <= 0) {
                        primaActual = getDecimal(fianza, 'Prima_neta__c');
                    }
                }

                if (seguroId != null && segurosPorId.containsKey(seguroId)) {
                    SObject seguro = segurosPorId.get(seguroId);
                    primaActual = getDecimal(seguro, 'Prima_neta__c');
                }

                if (primaActual != null) {
                    putIfExists(
                        endoso,
                        'Diferencia_monto__c',
                        nuevaPrima - primaActual
                    );
                }
            }
        }
    }

    /*
     * =====================================================================================
     * AFTER INSERT / AFTER UPDATE
     * =====================================================================================
     */
    public static void afterSave(
        List<Tech_Endoso__c> nuevosEndosos,
        Map<Id, Tech_Endoso__c> endososAnteriores,
        Boolean esInsert
    ) {

        if (enEjecucionAfter) {
            return;
        }

        if (nuevosEndosos == null || nuevosEndosos.isEmpty()) {
            return;
        }

        List<Tech_Endoso__c> endososProcesables =
            new List<Tech_Endoso__c>();

        for (Tech_Endoso__c endoso : nuevosEndosos) {

            if (
                debeProcesarse(
                    endoso,
                    endososAnteriores,
                    esInsert
                )
            ) {
                endososProcesables.add(endoso);
            }
        }

        if (endososProcesables.isEmpty()) {
            return;
        }

        enEjecucionAfter = true;

        try {

            actualizarSeguroOFianza(endososProcesables);

            Set<Id> planIdsImpactados =
                actualizarPlanYRecibos(endososProcesables);

            actualizarPendientePagoPlanes(planIdsImpactados);

            marcarEndososComoAplicados(endososProcesables);

        } finally {
            enEjecucionAfter = false;
        }
    }

    /*
     * =====================================================================================
     * DETERMINAR SI EL ENDOSO SE PROCESA
     * =====================================================================================
     */
    private static Boolean debeProcesarse(
        Tech_Endoso__c endoso,
        Map<Id, Tech_Endoso__c> endososAnteriores,
        Boolean esInsert
    ) {

        if (endoso == null) {
            return false;
        }

        String estado = getString(endoso, 'Estado__c');

        if (estado != ESTADO_APROBADO) {
            return false;
        }

        if (esInsert) {
            return true;
        }

        if (
            endososAnteriores == null ||
            !endososAnteriores.containsKey(endoso.Id)
        ) {
            return false;
        }

        Tech_Endoso__c anterior = endososAnteriores.get(endoso.Id);

        if (getString(anterior, 'Estado__c') == ESTADO_APLICADO) {
            return false;
        }

        return
            getString(anterior, 'Estado__c') != ESTADO_APROBADO ||
            getBoolean(endoso, 'Afecta_prima__c') != getBoolean(anterior, 'Afecta_prima__c') ||
            getDecimal(endoso, 'Nueva_prima__c') != getDecimal(anterior, 'Nueva_prima__c') ||
            getDate(endoso, 'Fecha_efectiva__c') != getDate(anterior, 'Fecha_efectiva__c') ||
            getDate(endoso, 'Fin_Vigencia__c') != getDate(anterior, 'Fin_Vigencia__c') ||
            getString(endoso, 'Nueva_modalidad__c') != getString(anterior, 'Nueva_modalidad__c') ||
            getId(endoso, 'Fianza__c') != getId(anterior, 'Fianza__c') ||
            getId(endoso, 'Seguro__c') != getId(anterior, 'Seguro__c') ||
            getId(endoso, 'Plan_de_pago__c') != getId(anterior, 'Plan_de_pago__c');
    }

    /*
     * =====================================================================================
     * ACTUALIZAR SEGURO O FIANZA
     * =====================================================================================
     */
    private static void actualizarSeguroOFianza(
        List<Tech_Endoso__c> endosos
    ) {

        Map<Id, SObject> fianzasPorActualizar = new Map<Id, SObject>();
        Map<Id, SObject> segurosPorActualizar = new Map<Id, SObject>();

        for (Tech_Endoso__c endoso : endosos) {

            Id fianzaId = getId(endoso, 'Fianza__c');
            Id seguroId = getId(endoso, 'Seguro__c');

            Decimal nuevaPrima = getDecimal(endoso, 'Nueva_prima__c');
            Decimal nuevoMontoAfianzado =
                getDecimal(endoso, 'Nuevo_Monto_Afianzado__c');

            Date finVigencia = getDate(endoso, 'Fin_Vigencia__c');
            String nuevaModalidad = getString(endoso, 'Nueva_modalidad__c');

            if (fianzaId != null) {

                Tech_Fianza__c fianzaActualizar =
                    new Tech_Fianza__c(Id = fianzaId);

                Boolean requiereActualizar = false;

                if (nuevaPrima != null && nuevaPrima > 0) {
                    putIfExists(
                        fianzaActualizar,
                        'Prima_Vigente__c',
                        nuevaPrima
                    );
                    requiereActualizar = true;
                }

                if (nuevoMontoAfianzado != null && nuevoMontoAfianzado > 0) {
                    putIfExists(
                        fianzaActualizar,
                        'Monto_Afianzado_Vigente__c',
                        nuevoMontoAfianzado
                    );
                    requiereActualizar = true;
                }

                if (finVigencia != null) {
                    putIfExists(
                        fianzaActualizar,
                        'Fecha_Vencimiento_Vigente__c',
                        finVigencia
                    );
                    requiereActualizar = true;
                }

                if (!String.isBlank(nuevaModalidad)) {
                    putIfExists(
                        fianzaActualizar,
                        'Periodo_Pago__c',
                        nuevaModalidad
                    );
                    requiereActualizar = true;
                }

                if (requiereActualizar) {
                    fianzasPorActualizar.put(fianzaId, fianzaActualizar);
                }
            }

            if (seguroId != null) {

                Tech_Seguro__c seguroActualizar =
                    new Tech_Seguro__c(Id = seguroId);

                Boolean requiereActualizar = false;

                if (nuevaPrima != null && nuevaPrima > 0) {
                    putIfExists(
                        seguroActualizar,
                        'Prima_neta__c',
                        nuevaPrima
                    );
                    requiereActualizar = true;
                }

                if (finVigencia != null) {
                    putIfExists(
                        seguroActualizar,
                        'Fin_del_seguro__c',
                        finVigencia
                    );
                    requiereActualizar = true;
                }

                if (!String.isBlank(nuevaModalidad)) {
                    putIfExists(
                        seguroActualizar,
                        'Frecuencia_de_pago__c',
                        nuevaModalidad
                    );
                    requiereActualizar = true;
                }

                if (requiereActualizar) {
                    segurosPorActualizar.put(seguroId, seguroActualizar);
                }
            }
        }

        if (!fianzasPorActualizar.isEmpty()) {
            update fianzasPorActualizar.values();
        }

        if (!segurosPorActualizar.isEmpty()) {
            update segurosPorActualizar.values();
        }
    }

    /*
     * =====================================================================================
     * ACTUALIZAR PLAN Y RECIBOS
     * =====================================================================================
     */
    private static Set<Id> actualizarPlanYRecibos(
        List<Tech_Endoso__c> endosos
    ) {

        Set<Id> planIdsImpactados = new Set<Id>();

        if (endosos == null || endosos.isEmpty()) {
            return planIdsImpactados;
        }

        Set<Id> planIdsDirectos = new Set<Id>();
        Set<Id> fianzaIds = new Set<Id>();
        Set<Id> seguroIds = new Set<Id>();

        for (Tech_Endoso__c endoso : endosos) {

            Id planId = getId(endoso, 'Plan_de_pago__c');
            Id fianzaId = getId(endoso, 'Fianza__c');
            Id seguroId = getId(endoso, 'Seguro__c');

            if (planId != null) {
                planIdsDirectos.add(planId);
            }

            if (fianzaId != null) {
                fianzaIds.add(fianzaId);
            }

            if (seguroId != null) {
                seguroIds.add(seguroId);
            }
        }

        Map<Id, SObject> planesPorId = new Map<Id, SObject>();
        Map<Id, SObject> planPorFianzaId = new Map<Id, SObject>();
        Map<Id, SObject> planPorSeguroId = new Map<Id, SObject>();

        List<String> condiciones = new List<String>();

        if (!planIdsDirectos.isEmpty()) {
            condiciones.add('Id IN :planIdsDirectos');
        }

        if (
            !fianzaIds.isEmpty() &&
            campoExiste(Tech_Plan_de_Pago__c.SObjectType, 'Fianzas__c')
        ) {
            condiciones.add('Fianzas__c IN :fianzaIds');
        }

        if (
            !seguroIds.isEmpty() &&
            campoExiste(Tech_Plan_de_Pago__c.SObjectType, 'Seguro__c')
        ) {
            condiciones.add('Seguro__c IN :seguroIds');
        }

        if (condiciones.isEmpty()) {
            return planIdsImpactados;
        }

        List<String> camposPlan = new List<String>{ 'Id' };

        Schema.DescribeSObjectResult dPlan =
            Tech_Plan_de_Pago__c.SObjectType.getDescribe();

        agregarCampoSiExiste(dPlan, camposPlan, 'Fianzas__c');
        agregarCampoSiExiste(dPlan, camposPlan, 'Seguro__c');
        agregarCampoSiExiste(dPlan, camposPlan, 'Monto_total__c');
        agregarCampoSiExiste(dPlan, camposPlan, 'Pendiente_de_Pago__c');
        agregarCampoSiExiste(dPlan, camposPlan, 'Periodo_Pago__c');
        agregarCampoSiExiste(dPlan, camposPlan, 'Estado__c');
        agregarCampoSiExiste(dPlan, camposPlan, 'Estatus__c');
        agregarCampoSiExiste(dPlan, camposPlan, 'Fecha_Inicio__c');

        String soqlPlan =
            'SELECT ' + String.join(camposPlan, ',') +
            ' FROM Tech_Plan_de_Pago__c WHERE ' +
            String.join(condiciones, ' OR ');

        for (SObject plan : Database.query(soqlPlan)) {

            Id planId = (Id) plan.get('Id');

            planesPorId.put(planId, plan);

            Id fianzaId = getId(plan, 'Fianzas__c');
            Id seguroId = getId(plan, 'Seguro__c');

            if (fianzaId != null && !planPorFianzaId.containsKey(fianzaId)) {
                planPorFianzaId.put(fianzaId, plan);
            }

            if (seguroId != null && !planPorSeguroId.containsKey(seguroId)) {
                planPorSeguroId.put(seguroId, plan);
            }
        }

        if (planesPorId.isEmpty()) {
            return planIdsImpactados;
        }

        Set<Id> planesAjustados =
            ajustarRecibosFuturosOCrearPlanComplementario(
                endosos,
                planesPorId,
                planPorFianzaId,
                planPorSeguroId
            );

        planIdsImpactados.addAll(planesAjustados);

        return planIdsImpactados;
    }

    /*
     * =====================================================================================
     * AJUSTAR RECIBOS FUTUROS O CREAR PLAN COMPLEMENTARIO
     * =====================================================================================
     */
    private static Set<Id> ajustarRecibosFuturosOCrearPlanComplementario(
        List<Tech_Endoso__c> endosos,
        Map<Id, SObject> planesPorId,
        Map<Id, SObject> planPorFianzaId,
        Map<Id, SObject> planPorSeguroId
    ) {

        Set<Id> planIdsImpactados = new Set<Id>();

        Set<Id> planIds = new Set<Id>();

        for (Tech_Endoso__c endoso : endosos) {

            SObject plan = obtenerPlanDelEndoso(
                endoso,
                planesPorId,
                planPorFianzaId,
                planPorSeguroId
            );

            if (plan != null) {
                planIds.add((Id) plan.get('Id'));
            }
        }

        if (planIds.isEmpty()) {
            return planIdsImpactados;
        }

        Map<Id, List<Tech_Recibo_Pago__c>> recibosPorPlan =
            new Map<Id, List<Tech_Recibo_Pago__c>>();

        for (Tech_Recibo_Pago__c recibo : [
            SELECT Id,
                   Plan_de_Pagos__c,
                   Numero__c,
                   Fecha_programada__c,
                   Monto_programado__c,
                   Monto_cobrado__c,
                   Saldo__c,
                   Estado__c
            FROM Tech_Recibo_Pago__c
            WHERE Plan_de_Pagos__c IN :planIds
            ORDER BY Plan_de_Pagos__c,
                     Fecha_programada__c,
                     Numero__c
        ]) {

            if (!recibosPorPlan.containsKey(recibo.Plan_de_Pagos__c)) {
                recibosPorPlan.put(
                    recibo.Plan_de_Pagos__c,
                    new List<Tech_Recibo_Pago__c>()
                );
            }

            recibosPorPlan.get(recibo.Plan_de_Pagos__c).add(recibo);
        }

        Map<Id, Tech_Recibo_Pago__c> recibosPorActualizar =
            new Map<Id, Tech_Recibo_Pago__c>();

        List<Tech_Plan_de_Pago__c> planesOriginalesPorActualizar =
            new List<Tech_Plan_de_Pago__c>();

        List<Tech_Plan_de_Pago__c> planesComplementariosPorInsertar =
            new List<Tech_Plan_de_Pago__c>();

        Map<Integer, Tech_Endoso__c> endosoPorIndicePlanComplementario =
            new Map<Integer, Tech_Endoso__c>();

        Integer indicePlanComplementario = 0;

        for (Tech_Endoso__c endoso : endosos) {

            Boolean afectaPrima = getBoolean(endoso, 'Afecta_prima__c');
            Decimal nuevaPrima = getDecimal(endoso, 'Nueva_prima__c');
            Date fechaEfectiva = getDate(endoso, 'Fecha_efectiva__c');

            if (afectaPrima != true) {
                continue;
            }

            if (nuevaPrima == null || nuevaPrima <= 0) {
                continue;
            }

            if (fechaEfectiva == null) {
                fechaEfectiva = Date.today();
            }

            SObject plan = obtenerPlanDelEndoso(
                endoso,
                planesPorId,
                planPorFianzaId,
                planPorSeguroId
            );

            if (plan == null) {
                continue;
            }

            Id planId = (Id) plan.get('Id');

            if (!recibosPorPlan.containsKey(planId)) {
                continue;
            }

            List<Tech_Recibo_Pago__c> recibos = recibosPorPlan.get(planId);

            Decimal totalActualProgramado = 0;
            Date ultimaFechaProgramada;
            List<Tech_Recibo_Pago__c> recibosElegibles =
                new List<Tech_Recibo_Pago__c>();

            for (Tech_Recibo_Pago__c recibo : recibos) {

                if (recibo.Estado__c == ESTADO_ANULADO) {
                    continue;
                }

                Decimal montoProgramado =
                    recibo.Monto_programado__c == null
                    ? 0
                    : recibo.Monto_programado__c;

                totalActualProgramado += montoProgramado;

                if (
                    recibo.Fecha_programada__c != null &&
                    (
                        ultimaFechaProgramada == null ||
                        recibo.Fecha_programada__c > ultimaFechaProgramada
                    )
                ) {
                    ultimaFechaProgramada = recibo.Fecha_programada__c;
                }

                Boolean esFuturo =
                    recibo.Fecha_programada__c != null &&
                    recibo.Fecha_programada__c >= fechaEfectiva;

                Boolean esAjustable =
                    ESTADOS_RECIBO_AJUSTABLES.contains(recibo.Estado__c);

                if (esFuturo && esAjustable) {
                    recibosElegibles.add(recibo);
                }
            }

            Decimal diferenciaReal =
                (nuevaPrima - totalActualProgramado).setScale(2);

            if (diferenciaReal == 0) {
                continue;
            }

            /*
             * REGLA NUEVA:
             * Si la fecha efectiva es posterior al último recibo programado,
             * no hay pagos futuros que ajustar. Se crea un nuevo plan complementario.
             */
            Boolean fechaPosteriorAlUltimoPago =
                ultimaFechaProgramada != null &&
                fechaEfectiva > ultimaFechaProgramada;

            if (fechaPosteriorAlUltimoPago) {

                if (diferenciaReal > 0) {

                    Tech_Plan_de_Pago__c planComplementario =
                        construirPlanComplementarioUnaExhibicion(
                            endoso,
                            plan,
                            diferenciaReal,
                            fechaEfectiva
                        );

                    if (planComplementario != null) {
                        planesComplementariosPorInsertar.add(planComplementario);

                        endosoPorIndicePlanComplementario.put(
                            indicePlanComplementario,
                            endoso
                        );

                        indicePlanComplementario++;
                    }
                }

                /*
                 * Si diferenciaReal < 0 y ya no hay pagos futuros, no se genera
                 * cobro. Debe gestionarse como devolución o nota de crédito.
                 */
                continue;
            }

            /*
             * Ruta normal:
             * Si existen recibos futuros, distribuir la diferencia real.
             */
            if (recibosElegibles.isEmpty()) {
                continue;
            }

            Decimal ajusteBase =
                (diferenciaReal / Decimal.valueOf(recibosElegibles.size()))
                .setScale(2);

            Decimal ajusteAcumulado = 0;

            for (Integer i = 0; i < recibosElegibles.size(); i++) {

                Tech_Recibo_Pago__c recibo = recibosElegibles[i];

                Decimal ajusteRecibo;

                if (i < recibosElegibles.size() - 1) {
                    ajusteRecibo = ajusteBase;
                    ajusteAcumulado += ajusteBase;
                } else {
                    ajusteRecibo =
                        (diferenciaReal - ajusteAcumulado).setScale(2);
                }

                Decimal montoActual =
                    recibo.Monto_programado__c == null
                    ? 0
                    : recibo.Monto_programado__c;

                Decimal montoCobrado =
                    recibo.Monto_cobrado__c == null
                    ? 0
                    : recibo.Monto_cobrado__c;

                Decimal nuevoMonto =
                    (montoActual + ajusteRecibo).setScale(2);

                if (nuevoMonto < 0) {
                    nuevoMonto = 0;
                }

                Decimal nuevoSaldo =
                    (nuevoMonto - montoCobrado).setScale(2);

                if (nuevoSaldo < 0) {
                    nuevoSaldo = 0;
                }

                recibo.Monto_programado__c = nuevoMonto;
//                recibo.Saldo__c = nuevoSaldo;

                recibosPorActualizar.put(recibo.Id, recibo);
                planIdsImpactados.add(planId);
            }

            Tech_Plan_de_Pago__c planActualizar =
                new Tech_Plan_de_Pago__c(Id = planId);

            putIfExists(planActualizar, 'Monto_total__c', nuevaPrima);

            String nuevaModalidad = getString(endoso, 'Nueva_modalidad__c');

            if (!String.isBlank(nuevaModalidad)) {
                putIfExists(planActualizar, 'Periodo_Pago__c', nuevaModalidad);
            }

            planesOriginalesPorActualizar.add(planActualizar);
        }

        if (!recibosPorActualizar.isEmpty()) {
            update recibosPorActualizar.values();
        }

        if (!planesOriginalesPorActualizar.isEmpty()) {
            update planesOriginalesPorActualizar;
        }

        if (!planesComplementariosPorInsertar.isEmpty()) {

            insert planesComplementariosPorInsertar;

            List<Tech_Recibo_Pago__c> recibosComplementarios =
                new List<Tech_Recibo_Pago__c>();

            for (Integer i = 0; i < planesComplementariosPorInsertar.size(); i++) {

                Tech_Plan_de_Pago__c planComplementario =
                    planesComplementariosPorInsertar[i];

                Tech_Endoso__c endoso =
                    endosoPorIndicePlanComplementario.get(i);

                Tech_Recibo_Pago__c recibo =
                    construirReciboComplementarioUnaExhibicion(
                        planComplementario,
                        endoso
                    );

                recibosComplementarios.add(recibo);
                planIdsImpactados.add(planComplementario.Id);
            }

            if (!recibosComplementarios.isEmpty()) {
                insert recibosComplementarios;
            }
        }

        return planIdsImpactados;
    }

    /*
     * =====================================================================================
     * CONSTRUIR PLAN COMPLEMENTARIO A UNA EXHIBICIÓN
     * =====================================================================================
     */
    private static Tech_Plan_de_Pago__c construirPlanComplementarioUnaExhibicion(
        Tech_Endoso__c endoso,
        SObject planOriginal,
        Decimal montoComplementario,
        Date fechaEfectiva
    ) {

        if (
            endoso == null ||
            planOriginal == null ||
            montoComplementario == null ||
            montoComplementario <= 0
        ) {
            return null;
        }

        Tech_Plan_de_Pago__c plan = new Tech_Plan_de_Pago__c();

        Id fianzaId = getId(endoso, 'Fianza__c');
        Id seguroId = getId(endoso, 'Seguro__c');

        if (fianzaId == null) {
            fianzaId = getId(planOriginal, 'Fianzas__c');
        }

        if (seguroId == null) {
            seguroId = getId(planOriginal, 'Seguro__c');
        }

        if (fianzaId != null) {
            putIfExists(plan, 'Fianzas__c', fianzaId);
        }

        if (seguroId != null) {
            putIfExists(plan, 'Seguro__c', seguroId);
        }

        putIfExists(plan, 'Periodo_Pago__c', 'Contado');
        putIfExists(plan, 'Num_recibos__c', 1);
        putIfExists(plan, 'Monto_total__c', montoComplementario);
        putIfExists(plan, 'Pendiente_de_Pago__c', montoComplementario);
        putIfExists(plan, 'Fecha_Inicio__c', fechaEfectiva);
        putIfExists(plan, 'Estado__c', ESTADO_PLAN_ACTIVO);
        putIfExists(plan, 'Estatus__c', ESTADO_PLAN_ACTIVO);

        /*
         * Campos opcionales recomendados.
         * Si no existen, se omiten automáticamente.
         */
        putIfExists(plan, 'Plan_Origen__c', getId(planOriginal, 'Id'));
        putIfExists(plan, 'Endoso__c', endoso.Id);
        putIfExists(plan, 'Tipo_Plan__c', 'Complementario por Endoso');

        return plan;
    }

    /*
     * =====================================================================================
     * CONSTRUIR RECIBO COMPLEMENTARIO A UNA EXHIBICIÓN
     * =====================================================================================
     */
    private static Tech_Recibo_Pago__c construirReciboComplementarioUnaExhibicion(
        Tech_Plan_de_Pago__c planComplementario,
        Tech_Endoso__c endoso
    ) {

        Tech_Recibo_Pago__c recibo = new Tech_Recibo_Pago__c();

        Date fechaProgramada = getDate(endoso, 'Fecha_efectiva__c');

        if (fechaProgramada == null) {
            fechaProgramada = Date.today();
        }

        Decimal monto =
            planComplementario.Monto_total__c == null
            ? 0
            : planComplementario.Monto_total__c;

        recibo.Plan_de_Pagos__c = planComplementario.Id;
        recibo.Numero__c = 1;
        recibo.Fecha_programada__c = fechaProgramada;
        recibo.Monto_programado__c = monto;
//        recibo.Saldo__c = monto;
        recibo.Estado__c = ESTADO_RECIBO_PROGRAMADO;
//        recibo.Periodo_Pago__c = 'Contado';

        if (planComplementario.Seguro__c != null) {
            recibo.Seguro__c = planComplementario.Seguro__c;
        }

        /*
         * Campos opcionales para reportabilidad.
         */
        putIfExists(recibo, 'Fianza__c', getId(planComplementario, 'Fianzas__c'));
        putIfExists(recibo, 'Fianzas__c', getId(planComplementario, 'Fianzas__c'));
        putIfExists(recibo, 'Endoso__c', endoso.Id);
        putIfExists(recibo, 'Tipo_Recibo__c', 'Complementario por Endoso');

        return recibo;
    }

    /*
     * =====================================================================================
     * ACTUALIZAR PENDIENTE DE PAGO DEL PLAN
     * =====================================================================================
     */
    private static void actualizarPendientePagoPlanes(Set<Id> planIds) {

        if (planIds == null || planIds.isEmpty()) {
            return;
        }

        Map<Id, Decimal> pendientePorPlan = new Map<Id, Decimal>();
        Map<Id, Boolean> tieneVencidosPorPlan = new Map<Id, Boolean>();

        for (Id planId : planIds) {
            pendientePorPlan.put(planId, 0);
            tieneVencidosPorPlan.put(planId, false);
        }

        for (Tech_Recibo_Pago__c recibo : [
            SELECT Id,
                   Plan_de_Pagos__c,
                   Estado__c,
                   Monto_programado__c,
                   Monto_cobrado__c,
                   Saldo__c
            FROM Tech_Recibo_Pago__c
            WHERE Plan_de_Pagos__c IN :planIds
        ]) {

            if (recibo.Plan_de_Pagos__c == null) {
                continue;
            }

            if (recibo.Estado__c == 'Vencido') {
                tieneVencidosPorPlan.put(
                    recibo.Plan_de_Pagos__c,
                    true
                );
            }

            if (recibo.Estado__c == ESTADO_ANULADO) {
                continue;
            }

            Decimal saldo = recibo.Saldo__c;

            if (saldo == null) {

                Decimal montoProgramado =
                    recibo.Monto_programado__c == null
                    ? 0
                    : recibo.Monto_programado__c;

                Decimal montoCobrado =
                    recibo.Monto_cobrado__c == null
                    ? 0
                    : recibo.Monto_cobrado__c;

                saldo = montoProgramado - montoCobrado;
            }

            if (saldo < 0) {
                saldo = 0;
            }

            pendientePorPlan.put(
                recibo.Plan_de_Pagos__c,
                pendientePorPlan.get(recibo.Plan_de_Pagos__c) + saldo
            );
        }

        List<Tech_Plan_de_Pago__c> planesActualizar =
            new List<Tech_Plan_de_Pago__c>();

        for (Id planId : planIds) {

            Tech_Plan_de_Pago__c plan =
                new Tech_Plan_de_Pago__c(Id = planId);

            putIfExists(
                plan,
                'Pendiente_de_Pago__c',
                pendientePorPlan.get(planId)
            );

            putIfExists(
                plan,
                'Estado__c',
                tieneVencidosPorPlan.get(planId)
                    ? ESTADO_PLAN_MORA
                    : ESTADO_PLAN_ACTIVO
            );

            putIfExists(
                plan,
                'Estatus__c',
                tieneVencidosPorPlan.get(planId)
                    ? ESTADO_PLAN_MORA
                    : ESTADO_PLAN_ACTIVO
            );

            planesActualizar.add(plan);
        }

        if (!planesActualizar.isEmpty()) {
            update planesActualizar;
        }
    }

    /*
     * =====================================================================================
     * MARCAR ENDOSOS COMO APLICADOS
     * =====================================================================================
     */
    private static void marcarEndososComoAplicados(
        List<Tech_Endoso__c> endosos
    ) {

        if (endosos == null || endosos.isEmpty()) {
            return;
        }

        List<Tech_Endoso__c> endososActualizar =
            new List<Tech_Endoso__c>();

        for (Tech_Endoso__c endoso : endosos) {

            if (endoso.Id == null) {
                continue;
            }

            Tech_Endoso__c actualizar =
                new Tech_Endoso__c(Id = endoso.Id);

            putIfExists(actualizar, 'Estado__c', ESTADO_APLICADO);

            endososActualizar.add(actualizar);
        }

        if (endososActualizar.isEmpty()) {
            return;
        }

        try {
            marcandoAplicado = true;
            update endososActualizar;
        } finally {
            marcandoAplicado = false;
        }
    }

    /*
     * =====================================================================================
     * OBTENER PLAN DEL ENDOSO
     * =====================================================================================
     */
    private static SObject obtenerPlanDelEndoso(
        Tech_Endoso__c endoso,
        Map<Id, SObject> planesPorId,
        Map<Id, SObject> planPorFianzaId,
        Map<Id, SObject> planPorSeguroId
    ) {

        Id planId = getId(endoso, 'Plan_de_pago__c');

        if (planId != null && planesPorId.containsKey(planId)) {
            return planesPorId.get(planId);
        }

        Id fianzaId = getId(endoso, 'Fianza__c');

        if (fianzaId != null && planPorFianzaId.containsKey(fianzaId)) {
            return planPorFianzaId.get(fianzaId);
        }

        Id seguroId = getId(endoso, 'Seguro__c');

        if (seguroId != null && planPorSeguroId.containsKey(seguroId)) {
            return planPorSeguroId.get(seguroId);
        }

        return null;
    }

    /*
     * =====================================================================================
     * CONSULTAS DE FIANZA Y SEGURO
     * =====================================================================================
     */
    private static Map<Id, SObject> obtenerFianzas(Set<Id> fianzaIds) {

        Map<Id, SObject> mapa = new Map<Id, SObject>();

        if (fianzaIds == null || fianzaIds.isEmpty()) {
            return mapa;
        }

        List<String> campos = new List<String>{ 'Id' };

        Schema.DescribeSObjectResult d =
            Tech_Fianza__c.SObjectType.getDescribe();

        agregarCampoSiExiste(d, campos, 'Prima_neta__c');
        agregarCampoSiExiste(d, campos, 'Prima_Vigente__c');
        agregarCampoSiExiste(d, campos, 'Monto_Afianzado__c');
        agregarCampoSiExiste(d, campos, 'Monto_Afianzado_Vigente__c');

        String soql =
            'SELECT ' + String.join(campos, ',') +
            ' FROM Tech_Fianza__c WHERE Id IN :fianzaIds';

        for (SObject fianza : Database.query(soql)) {
            mapa.put((Id) fianza.get('Id'), fianza);
        }

        return mapa;
    }

    private static Map<Id, SObject> obtenerSeguros(Set<Id> seguroIds) {

        Map<Id, SObject> mapa = new Map<Id, SObject>();

        if (seguroIds == null || seguroIds.isEmpty()) {
            return mapa;
        }

        List<String> campos = new List<String>{ 'Id' };

        Schema.DescribeSObjectResult d =
            Tech_Seguro__c.SObjectType.getDescribe();

        agregarCampoSiExiste(d, campos, 'Prima_neta__c');
        agregarCampoSiExiste(d, campos, 'Fin_del_seguro__c');
        agregarCampoSiExiste(d, campos, 'Frecuencia_de_pago__c');

        String soql =
            'SELECT ' + String.join(campos, ',') +
            ' FROM Tech_Seguro__c WHERE Id IN :seguroIds';

        for (SObject seguro : Database.query(soql)) {
            mapa.put((Id) seguro.get('Id'), seguro);
        }

        return mapa;
    }

    /*
     * =====================================================================================
     * HELPERS
     * =====================================================================================
     */
    private static Boolean campoExiste(Schema.SObjectType tipo, String campo) {

        if (tipo == null || String.isBlank(campo)) {
            return false;
        }

        return tipo.getDescribe().fields.getMap().containsKey(campo);
    }

    private static void agregarCampoSiExiste(
        Schema.DescribeSObjectResult describe,
        List<String> campos,
        String campo
    ) {

        if (describe == null || campos == null || String.isBlank(campo)) {
            return;
        }

        if (
            describe.fields.getMap().containsKey(campo) &&
            !campos.contains(campo)
        ) {
            campos.add(campo);
        }
    }

    private static void putIfExists(
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

        Schema.DescribeFieldResult d =
            campos.get(campo).getDescribe();

        if (!d.isCreateable() && !d.isUpdateable()) {
            return;
        }

        registro.put(campo, valor);
    }

    private static Object getValue(SObject registro, String campo) {

        if (registro == null || String.isBlank(campo)) {
            return null;
        }

        try {
            return registro.get(campo);
        } catch (Exception e) {
            return null;
        }
    }

    private static Id getId(SObject registro, String campo) {

        Object valor = getValue(registro, campo);

        if (valor == null) {
            return null;
        }

        try {
            return (Id) valor;
        } catch (Exception e) {
            return null;
        }
    }

    private static String getString(SObject registro, String campo) {

        Object valor = getValue(registro, campo);

        if (valor == null) {
            return null;
        }

        return String.valueOf(valor);
    }

    private static Date getDate(SObject registro, String campo) {

        Object valor = getValue(registro, campo);

        if (valor == null) {
            return null;
        }

        try {
            return (Date) valor;
        } catch (Exception e) {
            return null;
        }
    }

    private static Decimal getDecimal(SObject registro, String campo) {

        Object valor = getValue(registro, campo);

        if (valor == null) {
            return null;
        }

        if (valor instanceof Decimal) {
            return (Decimal) valor;
        }

        try {
            return Decimal.valueOf(String.valueOf(valor));
        } catch (Exception e) {
            return null;
        }
    }

    private static Boolean getBoolean(SObject registro, String campo) {

        Object valor = getValue(registro, campo);

        if (valor == null) {
            return false;
        }

        if (valor instanceof Boolean) {
            return (Boolean) valor;
        }

        String texto = String.valueOf(valor).trim().toLowerCase();

        return texto == 'true' || texto == 'sí' || texto == 'si';
    }
}