public without sharing class TechConvenioTriggerHandler {

    /*
     * =====================================================================================
     * CLASE: TechConvenioTriggerHandler
     * =====================================================================================
     *
     * Objetivo:
     * - Procesar convenios modificatorios relacionados a Contract.
     * - Cuando el convenio esté en Estado__c = 'Aprobado':
     *      1. Actualiza datos vigentes del Contract.
     *      2. Identifica fianzas relacionadas al contrato.
     *      3. Genera endosos automáticos para las fianzas afectadas.
     *      4. Marca el convenio como 'Aplicado'.
     *
     * Modelo funcional:
     * Contract → Tech_Convenio_Modificatorio__c → Tech_Endoso__c → Tech_Fianza__c
     */

    private static Boolean enEjecucionAfter = false;
    private static Boolean marcandoAplicado = false;

    private static final String ESTADO_APROBADO = 'Aprobado';
    private static final String ESTADO_APLICADO = 'Aplicado';

    /*
     * =====================================================================================
     * BEFORE INSERT / BEFORE UPDATE
     * =====================================================================================
     */
    public static void beforeSave(
        List<Tech_Convenio_Modificatorio__c> nuevosConvenios,
        Map<Id, Tech_Convenio_Modificatorio__c> conveniosAnteriores
    ) {

        if (marcandoAplicado) {
            return;
        }

        if (nuevosConvenios == null || nuevosConvenios.isEmpty()) {
            return;
        }

        for (Tech_Convenio_Modificatorio__c convenio : nuevosConvenios) {

            String estado = getString(convenio, 'Estado__c');

            if (estado != ESTADO_APROBADO) {
                continue;
            }

            Id contractId = getId(convenio, 'Contract__c');

            if (contractId == null) {
                convenio.addError(
                    'El convenio modificatorio debe estar relacionado con un contrato.'
                );
                continue;
            }

            Decimal nuevoMonto = getDecimal(convenio, 'Nuevo_Monto__c');
            Date nuevaFechaFin = getDate(convenio, 'Nueva_Fecha_Fin__c');

            if (nuevoMonto == null && nuevaFechaFin == null) {
                convenio.addError(
                    'Para aprobar el convenio debes capturar Nuevo Monto o Nueva Fecha Fin.'
                );
            }

            if (nuevoMonto != null && nuevoMonto <= 0) {
                convenio.addError(
                    'El Nuevo Monto del convenio debe ser mayor a cero.'
                );
            }
        }
    }

    /*
     * =====================================================================================
     * AFTER INSERT / AFTER UPDATE
     * =====================================================================================
     */
    public static void afterSave(
        List<Tech_Convenio_Modificatorio__c> nuevosConvenios,
        Map<Id, Tech_Convenio_Modificatorio__c> conveniosAnteriores,
        Boolean esInsert
    ) {

        if (enEjecucionAfter) {
            return;
        }

        if (nuevosConvenios == null || nuevosConvenios.isEmpty()) {
            return;
        }

        List<Tech_Convenio_Modificatorio__c> conveniosProcesables =
            new List<Tech_Convenio_Modificatorio__c>();

        for (Tech_Convenio_Modificatorio__c convenio : nuevosConvenios) {

            if (
                debeProcesarConvenio(
                    convenio,
                    conveniosAnteriores,
                    esInsert
                )
            ) {
                conveniosProcesables.add(convenio);
            }
        }

        if (conveniosProcesables.isEmpty()) {
            return;
        }

        enEjecucionAfter = true;

        try {

            Set<Id> contractIds = new Set<Id>();

            for (Tech_Convenio_Modificatorio__c convenio : conveniosProcesables) {
                Id contractId = getId(convenio, 'Contract__c');

                if (contractId != null) {
                    contractIds.add(contractId);
                }
            }

            if (contractIds.isEmpty()) {
                return;
            }

            Map<Id, SObject> contratosPorId =
                obtenerContratos(contractIds);

            Map<Id, List<SObject>> fianzasPorContrato =
                obtenerFianzasPorContrato(contractIds);

            Map<Id, SObject> planPorFianzaId =
                obtenerPlanesPorFianza(fianzasPorContrato);

            actualizarContratos(
                conveniosProcesables,
                contratosPorId
            );

            List<Tech_Endoso__c> endososPorInsertar =
                construirEndososDesdeConvenios(
                    conveniosProcesables,
                    contratosPorId,
                    fianzasPorContrato,
                    planPorFianzaId
                );

            if (!endososPorInsertar.isEmpty()) {
                insert endososPorInsertar;
            }

            marcarConveniosComoAplicados(conveniosProcesables);

        } finally {
            enEjecucionAfter = false;
        }
    }

    /*
     * =====================================================================================
     * DETERMINAR SI EL CONVENIO DEBE PROCESARSE
     * =====================================================================================
     */
    private static Boolean debeProcesarConvenio(
        Tech_Convenio_Modificatorio__c convenio,
        Map<Id, Tech_Convenio_Modificatorio__c> conveniosAnteriores,
        Boolean esInsert
    ) {

        if (convenio == null) {
            return false;
        }

        String estado = getString(convenio, 'Estado__c');

        if (estado != ESTADO_APROBADO) {
            return false;
        }

        if (esInsert) {
            return true;
        }

        if (
            conveniosAnteriores == null ||
            !conveniosAnteriores.containsKey(convenio.Id)
        ) {
            return false;
        }

        Tech_Convenio_Modificatorio__c anterior =
            conveniosAnteriores.get(convenio.Id);

        String estadoAnterior = getString(anterior, 'Estado__c');

        if (estadoAnterior == ESTADO_APLICADO) {
            return false;
        }

        return
            estadoAnterior != ESTADO_APROBADO ||
            getDecimal(convenio, 'Nuevo_Monto__c') != getDecimal(anterior, 'Nuevo_Monto__c') ||
            getDate(convenio, 'Nueva_Fecha_Fin__c') != getDate(anterior, 'Nueva_Fecha_Fin__c') ||
            getId(convenio, 'Contract__c') != getId(anterior, 'Contract__c');
    }

    /*
     * =====================================================================================
     * ACTUALIZAR CONTRACT
     * =====================================================================================
     */
    private static void actualizarContratos(
        List<Tech_Convenio_Modificatorio__c> convenios,
        Map<Id, SObject> contratosPorId
    ) {

        if (convenios == null || convenios.isEmpty()) {
            return;
        }

        Map<Id, SObject> contratosPorActualizar = new Map<Id, SObject>();

        for (Tech_Convenio_Modificatorio__c convenio : convenios) {

            Id contractId = getId(convenio, 'Contract__c');

            if (contractId == null || !contratosPorId.containsKey(contractId)) {
                continue;
            }

            Decimal nuevoMonto = getDecimal(convenio, 'Nuevo_Monto__c');
            Date nuevaFechaFin = getDate(convenio, 'Nueva_Fecha_Fin__c');

            Contract contratoActualizar = new Contract(Id = contractId);
            Boolean requiereActualizar = false;

            if (nuevoMonto != null) {
                putIfExists(
                    contratoActualizar,
                    'Monto_Contrato_Vigente__c',
                    nuevoMonto
                );
                requiereActualizar = true;
            }

            if (nuevaFechaFin != null) {
                putIfExists(
                    contratoActualizar,
                    'Fecha_Fin_Vigente__c',
                    nuevaFechaFin
                );
                requiereActualizar = true;
            }

            if (requiereActualizar) {
                contratosPorActualizar.put(contractId, contratoActualizar);
            }
        }

        if (!contratosPorActualizar.isEmpty()) {
            update contratosPorActualizar.values();
        }
    }

    /*
     * =====================================================================================
     * CONSTRUIR ENDOSOS DESDE CONVENIOS
     * =====================================================================================
     */
    private static List<Tech_Endoso__c> construirEndososDesdeConvenios(
        List<Tech_Convenio_Modificatorio__c> convenios,
        Map<Id, SObject> contratosPorId,
        Map<Id, List<SObject>> fianzasPorContrato,
        Map<Id, SObject> planPorFianzaId
    ) {

        List<Tech_Endoso__c> endosos = new List<Tech_Endoso__c>();

        if (convenios == null || convenios.isEmpty()) {
            return endosos;
        }

        Set<Id> convenioIds = new Set<Id>();
        Set<Id> fianzaIds = new Set<Id>();

        for (Tech_Convenio_Modificatorio__c convenio : convenios) {
            if (convenio.Id != null) {
                convenioIds.add(convenio.Id);
            }

            Id contractId = getId(convenio, 'Contract__c');

            if (
                contractId != null &&
                fianzasPorContrato.containsKey(contractId)
            ) {
                for (SObject fianza : fianzasPorContrato.get(contractId)) {
                    fianzaIds.add((Id) fianza.get('Id'));
                }
            }
        }

        Set<String> endososExistentes =
            obtenerLlavesEndososExistentes(convenioIds, fianzaIds);

        for (Tech_Convenio_Modificatorio__c convenio : convenios) {

            Id contractId = getId(convenio, 'Contract__c');

            if (
                contractId == null ||
                !contratosPorId.containsKey(contractId) ||
                !fianzasPorContrato.containsKey(contractId)
            ) {
                continue;
            }

            SObject contrato = contratosPorId.get(contractId);

            Decimal montoContratoActual =
                getDecimal(contrato, 'Monto_Contrato_Vigente__c');

            if (montoContratoActual == null || montoContratoActual <= 0) {
                montoContratoActual = getDecimal(contrato, 'Monto_Contrato__c');
            }

            Decimal nuevoMontoContrato = getDecimal(convenio, 'Nuevo_Monto__c');
            Date nuevaFechaFin = getDate(convenio, 'Nueva_Fecha_Fin__c');

            Boolean afectaMonto =
                nuevoMontoContrato != null &&
                montoContratoActual != null &&
                montoContratoActual > 0 &&
                nuevoMontoContrato != montoContratoActual;

            Decimal factorMonto = 1;

            if (afectaMonto) {
                factorMonto =
                    (nuevoMontoContrato / montoContratoActual).setScale(6);
            }

            for (SObject fianza : fianzasPorContrato.get(contractId)) {

                Id fianzaId = (Id) fianza.get('Id');

                String llave = String.valueOf(convenio.Id) + '-' + String.valueOf(fianzaId);

                if (endososExistentes.contains(llave)) {
                    continue;
                }

                Decimal primaActual = getDecimal(fianza, 'Prima_Vigente__c');

                if (primaActual == null || primaActual <= 0) {
                    primaActual = getDecimal(fianza, 'Prima_neta__c');
                }

                Decimal montoAfianzadoActual =
                    getDecimal(fianza, 'Monto_Afianzado_Vigente__c');

                if (montoAfianzadoActual == null || montoAfianzadoActual <= 0) {
                    montoAfianzadoActual =
                        getDecimal(fianza, 'Monto_Afianzado__c');
                }

                Decimal nuevaPrima = primaActual;
                Decimal nuevoMontoAfianzado = montoAfianzadoActual;

                if (afectaMonto) {
                    if (primaActual != null) {
                        nuevaPrima = (primaActual * factorMonto).setScale(2);
                    }

                    if (montoAfianzadoActual != null) {
                        nuevoMontoAfianzado =
                            (montoAfianzadoActual * factorMonto).setScale(2);
                    }
                }

                Boolean afectaPrima =
                    nuevaPrima != null &&
                    primaActual != null &&
                    nuevaPrima != primaActual;

                Boolean afectaVigencia =
                    nuevaFechaFin != null &&
                    nuevaFechaFin != getDate(fianza, 'Fecha_Vencimiento_Vigente__c');

                if (!afectaPrima && !afectaVigencia) {
                    continue;
                }

                Tech_Endoso__c endoso = new Tech_Endoso__c();

                putIfExists(
                    endoso,
                    'Name',
                    'Endoso convenio - ' + String.valueOf(convenio.Id)
                );

                putIfExists(endoso, 'Fianza__c', fianzaId);
                putIfExists(endoso, 'Estado__c', ESTADO_APROBADO);
                putIfExists(endoso, 'Afecta_prima__c', afectaPrima);

                if (afectaPrima) {
                    putIfExists(endoso, 'Nueva_prima__c', nuevaPrima);
                    putIfExists(
                        endoso,
                        'Diferencia_monto__c',
                        nuevaPrima - primaActual
                    );
                }

                if (nuevaFechaFin != null) {
                    putIfExists(endoso, 'Fin_Vigencia__c', nuevaFechaFin);
                }

                /*
                 * Fecha efectiva del endoso:
                 * - Si existe Fecha_Efectiva__c en el convenio, se toma esa fecha.
                 * - Si no existe, se usa Date.today().
                 */
                Date fechaEfectiva = getDate(convenio, 'Fecha_Efectiva__c');

                if (fechaEfectiva == null) {
                    fechaEfectiva = Date.today();
                }

                putIfExists(endoso, 'Fecha_efectiva__c', fechaEfectiva);

                if (planPorFianzaId.containsKey(fianzaId)) {
                    putIfExists(
                        endoso,
                        'Plan_de_pago__c',
                        (Id) planPorFianzaId.get(fianzaId).get('Id')
                    );
                }

                /*
                 * Campos opcionales recomendados.
                 * Si no existen en la org, se omiten automáticamente.
                 */
                putIfExists(
                    endoso,
                    'Nuevo_Monto_Afianzado__c',
                    nuevoMontoAfianzado
                );

                if (
                    nuevoMontoAfianzado != null &&
                    montoAfianzadoActual != null
                ) {
                    putIfExists(
                        endoso,
                        'Diferencia_Monto_Afianzado__c',
                        nuevoMontoAfianzado - montoAfianzadoActual
                    );
                }

                putIfExists(endoso, 'Convenio_Modificatorio__c', convenio.Id);
                putIfExists(endoso, 'Convenio__c', convenio.Id);

                endosos.add(endoso);
            }
        }

        return endosos;
    }

    /*
     * =====================================================================================
     * MARCAR CONVENIOS COMO APLICADOS
     * =====================================================================================
     */
    private static void marcarConveniosComoAplicados(
        List<Tech_Convenio_Modificatorio__c> convenios
    ) {

        if (convenios == null || convenios.isEmpty()) {
            return;
        }

        List<Tech_Convenio_Modificatorio__c> conveniosPorActualizar =
            new List<Tech_Convenio_Modificatorio__c>();

        for (Tech_Convenio_Modificatorio__c convenio : convenios) {

            if (convenio.Id == null) {
                continue;
            }

            Tech_Convenio_Modificatorio__c actualizar =
                new Tech_Convenio_Modificatorio__c(Id = convenio.Id);

            putIfExists(actualizar, 'Estado__c', ESTADO_APLICADO);

            conveniosPorActualizar.add(actualizar);
        }

        if (conveniosPorActualizar.isEmpty()) {
            return;
        }

        try {
            marcandoAplicado = true;
            update conveniosPorActualizar;
        } finally {
            marcandoAplicado = false;
        }
    }

    /*
     * =====================================================================================
     * CONSULTAS
     * =====================================================================================
     */
    private static Map<Id, SObject> obtenerContratos(Set<Id> contractIds) {

        Map<Id, SObject> contratos = new Map<Id, SObject>();

        if (contractIds == null || contractIds.isEmpty()) {
            return contratos;
        }

        List<String> campos = new List<String>{
            'Id',
            'AccountId',
            'StartDate',
            'EndDate',
            'Status',
            'ContractNumber'
        };

        Schema.DescribeSObjectResult d = Contract.SObjectType.getDescribe();

        agregarCampoSiExiste(d, campos, 'Monto_Contrato__c');
        agregarCampoSiExiste(d, campos, 'Monto_Contrato_Vigente__c');
        agregarCampoSiExiste(d, campos, 'Fecha_Fin__c');
        agregarCampoSiExiste(d, campos, 'Fecha_Fin_Vigente__c');

        String soql =
            'SELECT ' + String.join(campos, ',') +
            ' FROM Contract WHERE Id IN :contractIds';

        for (SObject contrato : Database.query(soql)) {
            contratos.put((Id) contrato.get('Id'), contrato);
        }

        return contratos;
    }

    private static Map<Id, List<SObject>> obtenerFianzasPorContrato(
        Set<Id> contractIds
    ) {

        Map<Id, List<SObject>> mapa = new Map<Id, List<SObject>>();

        if (contractIds == null || contractIds.isEmpty()) {
            return mapa;
        }

        if (!campoExiste(Tech_Fianza__c.SObjectType, 'Contrato__c')) {
            return mapa;
        }

        List<String> campos = new List<String>{ 'Id' };

        Schema.DescribeSObjectResult d =
            Tech_Fianza__c.SObjectType.getDescribe();

        agregarCampoSiExiste(d, campos, 'Contrato__c');
        agregarCampoSiExiste(d, campos, 'Prima_neta__c');
        agregarCampoSiExiste(d, campos, 'Prima_Vigente__c');
        agregarCampoSiExiste(d, campos, 'Monto_Afianzado__c');
        agregarCampoSiExiste(d, campos, 'Monto_Afianzado_Vigente__c');
        agregarCampoSiExiste(d, campos, 'Fecha_de_Vencimiento__c');
        agregarCampoSiExiste(d, campos, 'Fecha_Vencimiento_Vigente__c');
        agregarCampoSiExiste(d, campos, 'Estatus__c');

        String soql =
            'SELECT ' + String.join(campos, ',') +
            ' FROM Tech_Fianza__c ' +
            ' WHERE Contrato__c IN :contractIds ' +
            ' AND Estatus__c != \'Cancelada\'';

        for (SObject fianza : Database.query(soql)) {

            Id contractId = getId(fianza, 'Contrato__c');

            if (contractId == null) {
                continue;
            }

            if (!mapa.containsKey(contractId)) {
                mapa.put(contractId, new List<SObject>());
            }

            mapa.get(contractId).add(fianza);
        }

        return mapa;
    }

    private static Map<Id, SObject> obtenerPlanesPorFianza(
        Map<Id, List<SObject>> fianzasPorContrato
    ) {

        Map<Id, SObject> planPorFianza = new Map<Id, SObject>();

        Set<Id> fianzaIds = new Set<Id>();

        for (List<SObject> fianzas : fianzasPorContrato.values()) {
            for (SObject fianza : fianzas) {
                fianzaIds.add((Id) fianza.get('Id'));
            }
        }

        if (fianzaIds.isEmpty()) {
            return planPorFianza;
        }

        if (!campoExiste(Tech_Plan_de_Pago__c.SObjectType, 'Fianzas__c')) {
            return planPorFianza;
        }

        for (SObject plan : Database.query(
            'SELECT Id, Fianzas__c, Monto_total__c, Pendiente_de_Pago__c, Periodo_Pago__c ' +
            'FROM Tech_Plan_de_Pago__c ' +
            'WHERE Fianzas__c IN :fianzaIds'
        )) {
            Id fianzaId = getId(plan, 'Fianzas__c');

            if (fianzaId != null && !planPorFianza.containsKey(fianzaId)) {
                planPorFianza.put(fianzaId, plan);
            }
        }

        return planPorFianza;
    }

    private static Set<String> obtenerLlavesEndososExistentes(
        Set<Id> convenioIds,
        Set<Id> fianzaIds
    ) {

        Set<String> llaves = new Set<String>();

        if (
            convenioIds == null ||
            convenioIds.isEmpty() ||
            fianzaIds == null ||
            fianzaIds.isEmpty()
        ) {
            return llaves;
        }

        String campoConvenio = obtenerCampoConvenioEnEndoso();

        if (campoConvenio == null) {
            return llaves;
        }

        String soql =
            'SELECT Id, Fianza__c, ' + campoConvenio +
            ' FROM Tech_Endoso__c ' +
            ' WHERE Fianza__c IN :fianzaIds ' +
            ' AND ' + campoConvenio + ' IN :convenioIds';

        for (SObject endoso : Database.query(soql)) {

            Id convenioId = getId(endoso, campoConvenio);
            Id fianzaId = getId(endoso, 'Fianza__c');

            if (convenioId != null && fianzaId != null) {
                llaves.add(
                    String.valueOf(convenioId) + '-' + String.valueOf(fianzaId)
                );
            }
        }

        return llaves;
    }

    private static String obtenerCampoConvenioEnEndoso() {

        if (campoExiste(Tech_Endoso__c.SObjectType, 'Convenio_Modificatorio__c')) {
            return 'Convenio_Modificatorio__c';
        }

        if (campoExiste(Tech_Endoso__c.SObjectType, 'Convenio__c')) {
            return 'Convenio__c';
        }

        return null;
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
}