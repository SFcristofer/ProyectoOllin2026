public with sharing class TechReciboPagoTriggerHandler {

    /*
     * =====================================================================================
     * CLASE: TechReciboPagoTriggerHandler
     * =====================================================================================
     *
     * Objetivo:
     * - Controlar la lógica del objeto Tech_Recibo_Pago__c.
     * - Validar datos mínimos del recibo.
     * - Calcular automáticamente el Estado del recibo.
     * - Calcular Saldo__c del recibo.
     * - Validar pagos completos y parciales.
     * - Evitar pagos mayores al monto programado.
     * - Actualizar el Estado del Tech_Plan_de_Pago__c relacionado.
     * - Actualizar Pendiente_de_Pago__c del Tech_Plan_de_Pago__c relacionado.
     *
     * Estados usados en Tech_Recibo_Pago__c:
     * - Programado
     * - Por cobrar
     * - Cobrado
     * - Vencido
     * - Parcial
     * - Anulado
     *
     * Estados usados en Tech_Plan_de_Pago__c:
     * - Activo
     * - En mora
     */

    private static Boolean enEjecucionAfter = false;

    private static final String ESTADO_PROGRAMADO = 'Programado';
    private static final String ESTADO_POR_COBRAR = 'Por cobrar';
    private static final String ESTADO_COBRADO = 'Cobrado';
    private static final String ESTADO_VENCIDO = 'Vencido';
    private static final String ESTADO_PARCIAL = 'Parcial';
    private static final String ESTADO_ANULADO = 'Anulado';

    private static final String PLAN_ESTADO_ACTIVO = 'Activo';
    private static final String PLAN_ESTADO_EN_MORA = 'En mora';

    private static final String METODO_EFECTIVO = 'Efectivo';

    /*
     * =====================================================================================
     * BEFORE INSERT / BEFORE UPDATE
     * =====================================================================================
     */
    public static void beforeSave(
        List<Tech_Recibo_Pago__c> recibosNuevos,
        Map<Id, Tech_Recibo_Pago__c> recibosAnteriores
    ) {

        if (recibosNuevos == null || recibosNuevos.isEmpty()) {
            return;
        }

        for (Tech_Recibo_Pago__c recibo : recibosNuevos) {

            /*
             * -----------------------------------------------------------------
             * 1. Estado por defecto.
             * -----------------------------------------------------------------
             */
            if (String.isBlank(recibo.Estado__c)) {
                recibo.Estado__c = ESTADO_PROGRAMADO;
            }

            /*
             * -----------------------------------------------------------------
             * 2. Validar datos mínimos.
             * -----------------------------------------------------------------
             */
            validarDatosMinimos(recibo);

            /*
             * -----------------------------------------------------------------
             * 3. Validar montos y fechas.
             * -----------------------------------------------------------------
             */
            validarMontosYFechas(recibo);

            /*
             * -----------------------------------------------------------------
             * 4. Calcular estado automático del recibo.
             * -----------------------------------------------------------------
             */
            calcularEstadoRecibo(recibo);

            /*
             * -----------------------------------------------------------------
             * 5. Validaciones específicas por estado.
             * -----------------------------------------------------------------
             */
            validarEstadoPago(recibo);
        }
    }

    /*
     * =====================================================================================
     * AFTER INSERT / AFTER UPDATE / AFTER DELETE / AFTER UNDELETE
     * =====================================================================================
     *
     * Se usa para:
     * - Actualizar Estado__c del Plan de Pago.
     * - Actualizar Pendiente_de_Pago__c del Plan de Pago.
     */
    public static void afterChange(
        List<Tech_Recibo_Pago__c> recibos,
        Map<Id, Tech_Recibo_Pago__c> recibosAnteriores
    ) {

        if (enEjecucionAfter) {
            return;
        }

        if (recibos == null || recibos.isEmpty()) {
            return;
        }

        enEjecucionAfter = true;

        try {

            Set<Id> planIds = new Set<Id>();

            /*
             * -----------------------------------------------------------------
             * 1. Obtener planes afectados.
             * -----------------------------------------------------------------
             */
            for (Tech_Recibo_Pago__c recibo : recibos) {

                if (recibo.Plan_de_Pagos__c != null) {
                    planIds.add(recibo.Plan_de_Pagos__c);
                }

                /*
                 * Si el recibo cambió de plan, también recalcular el plan anterior.
                 */
                if (
                    recibosAnteriores != null &&
                    recibosAnteriores.containsKey(recibo.Id)
                ) {
                    Tech_Recibo_Pago__c anterior = recibosAnteriores.get(recibo.Id);

                    if (anterior.Plan_de_Pagos__c != null) {
                        planIds.add(anterior.Plan_de_Pagos__c);
                    }
                }
            }

            if (planIds.isEmpty()) {
                return;
            }

            /*
             * -----------------------------------------------------------------
             * 2. Actualizar estado y pendiente de pago de los planes.
             * -----------------------------------------------------------------
             */
            actualizarPlanes(planIds);

        } finally {
            enEjecucionAfter = false;
        }
    }

    /*
     * =====================================================================================
     * VALIDAR DATOS MÍNIMOS DEL RECIBO
     * =====================================================================================
     */
    private static void validarDatosMinimos(Tech_Recibo_Pago__c recibo) {

        if (recibo.Plan_de_Pagos__c == null) {
            recibo.addError('El recibo debe estar relacionado con un Plan de Pago.');
        }

        if (recibo.Numero__c == null || recibo.Numero__c <= 0) {
            recibo.addError('El recibo debe tener un número de cuota mayor a cero.');
        }

        if (recibo.Fecha_programada__c == null) {
            recibo.addError('El recibo debe tener Fecha Programada.');
        }

        if (recibo.Monto_programado__c == null || recibo.Monto_programado__c <= 0) {
            recibo.addError('El recibo debe tener un Monto Programado mayor a cero.');
        }
    }

    /*
     * =====================================================================================
     * VALIDAR MONTOS Y FECHAS
     * =====================================================================================
     */
    private static void validarMontosYFechas(Tech_Recibo_Pago__c recibo) {

        if (recibo.Monto_cobrado__c != null && recibo.Monto_cobrado__c < 0) {
            recibo.addError('El Monto Cobrado no puede ser negativo.');
        }

        if (
            recibo.Monto_cobrado__c != null &&
            recibo.Monto_programado__c != null &&
            recibo.Monto_cobrado__c > recibo.Monto_programado__c
        ) {
            recibo.addError('El Monto Cobrado no puede ser mayor al Monto Programado.');
        }

        if (
            recibo.Fecha_pago__c != null &&
            recibo.Fecha_pago__c > Date.today()
        ) {
            recibo.addError('La Fecha de Pago no puede ser futura.');
        }
    }

    /*
     * =====================================================================================
     * CALCULAR ESTADO DEL RECIBO
     * =====================================================================================
     */
    private static void calcularEstadoRecibo(Tech_Recibo_Pago__c recibo) {

        /*
         * Si el recibo está anulado, se respeta el estado.
         */
        if (recibo.Estado__c == ESTADO_ANULADO) {
            return;
        }

        Decimal montoProgramado =
            recibo.Monto_programado__c == null
            ? 0
            : recibo.Monto_programado__c;

        Decimal montoCobrado =
            recibo.Monto_cobrado__c == null
            ? 0
            : recibo.Monto_cobrado__c;

        /*
         * Cobrado.
         */
        if (
            montoProgramado > 0 &&
            montoCobrado == montoProgramado &&
            recibo.Fecha_pago__c != null
        ) {
            recibo.Estado__c = ESTADO_COBRADO;
            return;
        }

        /*
         * Parcial.
         */
        if (
            montoProgramado > 0 &&
            montoCobrado > 0 &&
            montoCobrado < montoProgramado &&
            recibo.Fecha_pago__c != null
        ) {
            recibo.Estado__c = ESTADO_PARCIAL;
            return;
        }

        /*
         * Sin cobro.
         */
        if (montoCobrado == 0 && recibo.Fecha_programada__c != null) {

            if (recibo.Fecha_programada__c < Date.today()) {
                recibo.Estado__c = ESTADO_VENCIDO;
                return;
            }

            if (recibo.Fecha_programada__c == Date.today()) {
                recibo.Estado__c = ESTADO_POR_COBRAR;
                return;
            }

            if (recibo.Fecha_programada__c > Date.today()) {
                recibo.Estado__c = ESTADO_PROGRAMADO;
                return;
            }
        }
    }


    /*
     * =====================================================================================
     * VALIDAR ESTADO DE PAGO
     * =====================================================================================
     */
    private static void validarEstadoPago(Tech_Recibo_Pago__c recibo) {

        /*
         * ---------------------------------------------------------------------
         * Validar Cobrado.
         * ---------------------------------------------------------------------
         */
        if (recibo.Estado__c == ESTADO_COBRADO) {

            if (recibo.Monto_cobrado__c == null || recibo.Monto_cobrado__c <= 0) {
                recibo.addError(
                    'Para marcar un recibo como Cobrado debes capturar Monto Cobrado.'
                );
            }

            if (recibo.Fecha_pago__c == null) {
                recibo.addError(
                    'Para marcar un recibo como Cobrado debes capturar Fecha de Pago.'
                );
            }

            if (
                recibo.Monto_programado__c != null &&
                recibo.Monto_cobrado__c != null &&
                recibo.Monto_cobrado__c < recibo.Monto_programado__c
            ) {
                recibo.addError(
                    'Un recibo Cobrado debe tener Monto Cobrado igual al Monto Programado.'
                );
            }

            /*
             * Si el pago no fue en efectivo, se recomienda exigir referencia.
             */
            if (
                !String.isBlank(recibo.Metodo_pago__c) &&
                recibo.Metodo_pago__c != METODO_EFECTIVO &&
                String.isBlank(recibo.Referencia_pago__c)
            ) {
                recibo.addError(
                    'Para pagos no realizados en efectivo debes capturar la Referencia de Pago.'
                );
            }
        }

        /*
         * ---------------------------------------------------------------------
         * Validar Parcial.
         * ---------------------------------------------------------------------
         */
        if (recibo.Estado__c == ESTADO_PARCIAL) {

            if (recibo.Monto_cobrado__c == null || recibo.Monto_cobrado__c <= 0) {
                recibo.addError(
                    'Para marcar un recibo como Parcial debes capturar Monto Cobrado mayor a cero.'
                );
            }

            if (recibo.Fecha_pago__c == null) {
                recibo.addError(
                    'Para marcar un recibo como Parcial debes capturar Fecha de Pago.'
                );
            }

            if (
                recibo.Monto_programado__c != null &&
                recibo.Monto_cobrado__c != null &&
                recibo.Monto_cobrado__c >= recibo.Monto_programado__c
            ) {
                recibo.addError(
                    'Un recibo Parcial debe tener Monto Cobrado menor al Monto Programado.'
                );
            }
        }

        /*
         * ---------------------------------------------------------------------
         * Validar Anulado.
         * ---------------------------------------------------------------------
         */
        if (recibo.Estado__c == ESTADO_ANULADO) {

            if (String.isBlank(recibo.Motivo_No_Pago__c)) {
                recibo.addError(
                    'Para anular un recibo debes capturar el Motivo de No Pago.'
                );
            }
        }
    }

    /*
     * =====================================================================================
     * ACTUALIZAR PLANES DE PAGO
     * =====================================================================================
     *
     * Acciones:
     * - Estado__c = En mora si tiene al menos un recibo vencido.
     * - Estado__c = Activo si no tiene recibos vencidos.
     * - Pendiente_de_Pago__c = suma de saldos de recibos no anulados.
     */
    private static void actualizarPlanes(Set<Id> planIds) {

        if (planIds == null || planIds.isEmpty()) {
            return;
        }

        Map<Id, Tech_Plan_de_Pago__c> planesPorId =
            new Map<Id, Tech_Plan_de_Pago__c>([
                SELECT Id,
                       Estado__c,
                       Pendiente_de_Pago__c
                FROM Tech_Plan_de_Pago__c
                WHERE Id IN :planIds
            ]);

        if (planesPorId.isEmpty()) {
            return;
        }

        Map<Id, Decimal> pendientePorPlan = new Map<Id, Decimal>();
        Map<Id, Boolean> planTieneVencidos = new Map<Id, Boolean>();

        for (Id planId : planesPorId.keySet()) {
            pendientePorPlan.put(planId, 0);
            planTieneVencidos.put(planId, false);
        }

        /*
         * ---------------------------------------------------------------------
         * Consultar recibos vivos de los planes.
         * ---------------------------------------------------------------------
         */
        List<Tech_Recibo_Pago__c> recibos = [
            SELECT Id,
                   Plan_de_Pagos__c,
                   Estado__c,
                   Monto_programado__c,
                   Monto_cobrado__c,
                   Saldo__c
            FROM Tech_Recibo_Pago__c
            WHERE Plan_de_Pagos__c IN :planesPorId.keySet()
        ];

        for (Tech_Recibo_Pago__c recibo : recibos) {

            if (recibo.Plan_de_Pagos__c == null) {
                continue;
            }

            Id planId = recibo.Plan_de_Pagos__c;

            /*
             * Vencidos.
             */
            if (recibo.Estado__c == ESTADO_VENCIDO) {
                planTieneVencidos.put(planId, true);
            }

            /*
             * No sumar recibos anulados al pendiente.
             */
            if (recibo.Estado__c == ESTADO_ANULADO) {
                continue;
            }

            Decimal pendienteRecibo;

            if (recibo.Saldo__c != null) {
                pendienteRecibo = recibo.Saldo__c;
            } else {

                Decimal montoProgramado =
                    recibo.Monto_programado__c == null
                    ? 0
                    : recibo.Monto_programado__c;

                Decimal montoCobrado =
                    recibo.Monto_cobrado__c == null
                    ? 0
                    : recibo.Monto_cobrado__c;

                pendienteRecibo = montoProgramado - montoCobrado;
            }

            if (pendienteRecibo < 0) {
                pendienteRecibo = 0;
            }

            Decimal acumulado =
                pendientePorPlan.containsKey(planId)
                ? pendientePorPlan.get(planId)
                : 0;

            pendientePorPlan.put(
                planId,
                acumulado + pendienteRecibo
            );
        }

        /*
         * ---------------------------------------------------------------------
         * Preparar actualización de planes.
         * ---------------------------------------------------------------------
         */
        List<Tech_Plan_de_Pago__c> planesPorActualizar =
            new List<Tech_Plan_de_Pago__c>();

        for (Id planId : planesPorId.keySet()) {

            Tech_Plan_de_Pago__c planActual = planesPorId.get(planId);

            String nuevoEstado =
                planTieneVencidos.get(planId) == true
                ? PLAN_ESTADO_EN_MORA
                : PLAN_ESTADO_ACTIVO;

            Decimal nuevoPendiente =
                pendientePorPlan.containsKey(planId)
                ? pendientePorPlan.get(planId)
                : 0;

            Boolean requiereActualizar = false;

            Tech_Plan_de_Pago__c planActualizar =
                new Tech_Plan_de_Pago__c(Id = planId);

            if (planActual.Estado__c != nuevoEstado) {
                planActualizar.Estado__c = nuevoEstado;
                requiereActualizar = true;
            }

            if (planActual.Pendiente_de_Pago__c != nuevoPendiente) {
                planActualizar.Pendiente_de_Pago__c = nuevoPendiente;
                requiereActualizar = true;
            }

            if (requiereActualizar) {
                planesPorActualizar.add(planActualizar);
            }
        }

        if (!planesPorActualizar.isEmpty()) {
            update planesPorActualizar;
        }
    }
}