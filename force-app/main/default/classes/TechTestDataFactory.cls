@IsTest
public class TechTestDataFactory {

    public static String pickValue(String sObjectApi, String fieldApi, List<String> preferredValues) {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey(sObjectApi)) return null;
        Map<String, Schema.SObjectField> fmap = gd.get(sObjectApi).getDescribe().fields.getMap();
        if (!fmap.containsKey(fieldApi)) return null;

        Schema.DescribeFieldResult dfr = fmap.get(fieldApi).getDescribe();
        if (dfr.getType() != Schema.DisplayType.Picklist && dfr.getType() != Schema.DisplayType.MultiPicklist) {
            return null;
        }

        if (preferredValues != null) {
            for (String preferred : preferredValues) {
                for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                    if (pe.isActive() && (pe.getValue() == preferred || pe.getLabel() == preferred)) {
                        return pe.getValue();
                    }
                }
            }
        }

        for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
            if (pe.isActive()) return pe.getValue();
        }
        return null;
    }

    public static Boolean fieldExists(String sObjectApi, String fieldApi) {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey(sObjectApi)) return false;
        return gd.get(sObjectApi).getDescribe().fields.getMap().containsKey(fieldApi);
    }

    public static void setIfFieldExists(SObject record, String fieldApi, Object value) {
        if (record == null || String.isBlank(fieldApi)) return;
        String sObjectApi = String.valueOf(record.getSObjectType());
        if (fieldExists(sObjectApi, fieldApi)) record.put(fieldApi, value);
    }

    public static void setPicklistIfExists(SObject record, String fieldApi, List<String> preferredValues) {
        if (record == null || String.isBlank(fieldApi)) return;
        String value = pickValue(String.valueOf(record.getSObjectType()), fieldApi, preferredValues);
        if (value != null) record.put(fieldApi, value);
    }

    public static Account crearCuenta(String nombre) {
        Account cuenta = new Account();
        cuenta.Name = String.isBlank(nombre) ? 'Cliente Test' : nombre;
        setIfFieldExists(cuenta, 'Email__c', 'cliente.' + String.valueOf(Crypto.getRandomInteger()).replace('-', '') + '@test.com');
        cuenta.Phone = '5555555555';
        insert cuenta;
        return cuenta;
    }

    public static Product2 crearProducto(String ramo) {
        Product2 producto = new Product2();
        producto.Name = 'Producto Test ' + ramo;
        producto.IsActive = true;
        if (fieldExists('Product2', 'Ramo__c')) {
            producto.put('Ramo__c', pickValue('Product2', 'Ramo__c', new List<String>{ ramo, 'Autos', 'Auto', 'Fianzas', 'Fianza' }));
        }
        if (fieldExists('Product2', 'Familia_Producto__c')) {
            producto.put('Familia_Producto__c', pickValue('Product2', 'Familia_Producto__c', new List<String>{ ramo, 'Autos', 'Fianzas', 'Seguro' }));
        }
        insert producto;
        return producto;
    }

    public static Tech_Vendedor__c crearVendedor(String ramo) {
        Tech_Vendedor__c vendedor = new Tech_Vendedor__c();
//        vendedor.Name = 'Vendedor Test ' + ramo;
        setIfFieldExists(vendedor, 'Email__c', 'vendedor.test@test.com');
        setIfFieldExists(vendedor, 'Telefono__c', '5555555555');
        setPicklistIfExists(vendedor, 'Estatus__c', new List<String>{ 'Activo', 'Activa' });
        setPicklistIfExists(vendedor, 'Tipo_vendedor__c', new List<String>{ 'Humano', 'Interno', 'Agente' });
        setIfFieldExists(vendedor, 'Ramos__c', ramo);
        setIfFieldExists(vendedor, 'Zona__c', 'CDMX');
        setIfFieldExists(vendedor, 'Fecha_Inicio__c', Date.today());
        setIfFieldExists(vendedor, 'Porcentaje_Comision_Ollin__c', 10);
        setIfFieldExists(vendedor, 'Carga_Trabajo__c', 0);
        setIfFieldExists(vendedor, 'Usuario_Salesforce__c', UserInfo.getUserId());
        insert vendedor;
        return vendedor;
    }

    public static String etapaAbierta() {
        List<OpportunityStage> etapas = [
            SELECT MasterLabel
            FROM OpportunityStage
            WHERE IsClosed = false
            ORDER BY SortOrder ASC
            LIMIT 1
        ];
        return etapas.isEmpty() ? 'Prospecting' : etapas[0].MasterLabel;
    }

    public static String etapaGanada() {
        List<OpportunityStage> etapas = [
            SELECT MasterLabel
            FROM OpportunityStage
            WHERE IsWon = true
            LIMIT 1
        ];
        System.assert(!etapas.isEmpty(), 'Debe existir al menos una etapa ganada en OpportunityStage.');
        return etapas[0].MasterLabel;
    }

    public static String etapaPerdida() {
        List<OpportunityStage> etapas = [
            SELECT MasterLabel
            FROM OpportunityStage
            WHERE IsClosed = true AND IsWon = false
            LIMIT 1
        ];
        System.assert(!etapas.isEmpty(), 'Debe existir al menos una etapa perdida en OpportunityStage.');
        return etapas[0].MasterLabel;
    }

    public static Opportunity crearOportunidadAbierta(
        Account cliente,
        Product2 producto,
        Tech_Vendedor__c vendedor,
        String ramo
    ) {
        Opportunity opp = new Opportunity();
        opp.Name = 'Oportunidad Test ' + ramo + ' ' + System.now().getTime();
        opp.StageName = etapaAbierta();
        opp.CloseDate = Date.today().addDays(30);
        opp.AccountId = cliente.Id;
        opp.Amount = 12000;

        if (fieldExists('Opportunity', 'Vendedor_A__c')) opp.put('Vendedor_A__c', vendedor.Id);
        if (fieldExists('Opportunity', 'Producto__c')) opp.put('Producto__c', producto.Id);
        if (fieldExists('Opportunity', 'Institucion__c')) opp.put('Institucion__c', cliente.Id);
        if (fieldExists('Opportunity', 'Contratista__c')) opp.put('Contratista__c', cliente.Id);
        if (fieldExists('Opportunity', 'Beneficiario__c')) opp.put('Beneficiario__c', cliente.Id);
        if (fieldExists('Opportunity', 'Ramo__c')) {
            opp.put('Ramo__c', pickValue('Opportunity', 'Ramo__c', new List<String>{ ramo, 'Autos', 'Auto', 'Fianzas', 'Fianza' }));
        }
        if (fieldExists('Opportunity', 'Familia_Producto__c')) {
            opp.put('Familia_Producto__c', pickValue('Opportunity', 'Familia_Producto__c', new List<String>{ ramo, 'Autos', 'Fianzas', 'Seguro' }));
        }
        if (fieldExists('Opportunity', 'Metodo_Pago__c')) {
            opp.put('Metodo_Pago__c', pickValue('Opportunity', 'Metodo_Pago__c', new List<String>{ 'Transferencia (SPEI)', 'Transferencia', 'Efectivo' }));
        }
        if (fieldExists('Opportunity', 'Periodo_Pago__c')) {
            opp.put('Periodo_Pago__c', pickValue('Opportunity', 'Periodo_Pago__c', new List<String>{ 'Mensual', 'Contado' }));
        }
        if (fieldExists('Opportunity', 'Numero_Pagos__c')) opp.put('Numero_Pagos__c', 12);
        if (fieldExists('Opportunity', 'Fecha_Inicio_Vigencia__c')) opp.put('Fecha_Inicio_Vigencia__c', Date.today());
        if (fieldExists('Opportunity', 'Fecha_Fin_Vigencia__c')) opp.put('Fecha_Fin_Vigencia__c', Date.today().addMonths(12));
        if (fieldExists('Opportunity', 'Vigencia__c')) opp.put('Vigencia__c', 12);
        if (fieldExists('Opportunity', 'Subproducto__c')) opp.put('Subproducto__c', null);
        if (fieldExists('Opportunity', 'Tipo_Originador__c')) {
            setPicklistIfExists(opp, 'Tipo_Originador__c', new List<String>{ 'Consultivo', 'Agente', 'Digital' });
        }
        insert opp;
        return opp;
    }

    public static Opportunity prepararCierrePerdido(Opportunity opp) {
        opp.StageName = etapaPerdida();
        setPicklistIfExists(opp, 'Motivo_Perdida__c', new List<String>{ 'Precio', 'Cliente no interesado', 'Otro' });
        setPicklistIfExists(opp, 'Motivo_de_Perdida__c', new List<String>{ 'Precio', 'Cliente no interesado', 'Otro' });
        setPicklistIfExists(opp, 'Motivo_Cierre_Perdido__c', new List<String>{ 'Precio', 'Cliente no interesado', 'Otro' });
        setIfFieldExists(opp, 'Descripcion_Perdida__c', 'Prueba de oportunidad perdida');
        setIfFieldExists(opp, 'Comentarios_Perdida__c', 'Prueba de oportunidad perdida');
        return opp;
    }

    public static Lead crearLeadPersonaMoral() {
        Lead prospecto = new Lead();
        prospecto.FirstName = 'Prospecto';
        prospecto.LastName = 'Moral';
        prospecto.Company = 'Empresa Test SA de CV';
        prospecto.Email = 'prospecto.' + String.valueOf(System.now().getTime()) + '@test.com';
        prospecto.Phone = '5555551111';
        setIfFieldExists(prospecto, 'RFC__c', 'ABC900101A12');
        insert prospecto;
        return prospecto;
    }

    public static Tech_Seguro__c crearSeguro(
        Account cliente,
        Product2 producto,
        Tech_Vendedor__c vendedor,
        Opportunity opp,
        String ramo,
        Date fechaFin
    ) {
        Tech_Seguro__c seguro = new Tech_Seguro__c();
        seguro.Name = 'Seguro Test ' + System.now().getTime();
        seguro.Cliente__c = cliente.Id;
        seguro.Producto__c = producto.Id;
        seguro.Vendedor__c = vendedor.Id;
        seguro.Oportunidad__c = opp == null ? null : opp.Id;
        seguro.Aseguradora__c = cliente.Id;
        seguro.Ramo__c = pickValue('Tech_Seguro__c', 'Ramo__c', new List<String>{ ramo, 'Autos', 'Auto' });
        seguro.Forma_Pago__c = pickValue('Tech_Seguro__c', 'Forma_Pago__c', new List<String>{ 'Transferencia (SPEI)', 'Transferencia', 'Efectivo' });
        seguro.Frecuencia_de_pago__c = pickValue('Tech_Seguro__c', 'Frecuencia_de_pago__c', new List<String>{ 'Mensual', 'Contado' });
        seguro.Inicio_del_seguro__c = Date.today();
        seguro.Fin_del_seguro__c = fechaFin == null ? Date.today().addMonths(12) : fechaFin;
        seguro.Vigencia__c = 12;
        seguro.Prima_neta__c = 12000;
        seguro.Estatus__c = pickValue('Tech_Seguro__c', 'Estatus__c', new List<String>{ 'Emitida', 'Vigente', 'Por renovar' });
        insert seguro;
        return seguro;
    }

    public static Tech_Fianza__c crearFianza(
        Account contratista,
        Account beneficiario,
        Account afianzadora,
        Tech_Vendedor__c vendedor,
        Opportunity opp
    ) {
        Tech_Fianza__c fianza = new Tech_Fianza__c();
//        fianza.Name = 'Fianza Test ' + System.now().getTime();
        fianza.Oportunidad__c = opp == null ? null : opp.Id;
        fianza.Contratistas__c = contratista.Id;
        fianza.Beneficiarios__c = beneficiario.Id;
        fianza.Afianzadoras__c = afianzadora.Id;
        fianza.Vendedor__c = vendedor.Id;
        fianza.Monto_Afianzado__c = 12000;
        fianza.Monto_Afianzado_Vigente__c = 12000;
        fianza.Prima_neta__c = 12000;
        fianza.Prima_Vigente__c = 12000;
        fianza.Fecha_de_Emision__c = Date.today();
        fianza.Fecha_de_Vencimiento__c = Date.today().addMonths(12);
        fianza.Fecha_Vencimiento_Vigente__c = Date.today().addMonths(12);
        fianza.Periodo_Pago__c = pickValue('Tech_Fianza__c', 'Periodo_Pago__c', new List<String>{ 'Mensual', 'Contado' });
        fianza.Estatus__c = pickValue('Tech_Fianza__c', 'Estatus__c', new List<String>{ 'Emitida', 'Activa', 'Vigente' });
        setPicklistIfExists(fianza, 'Tipo_de_Riesgo__c', new List<String>{ 'Cumplimiento', 'Anticipo', 'Otro' });
        insert fianza;
        return fianza;
    }

    public static Tech_Plan_de_Pago__c crearPlanSeguro(Tech_Seguro__c seguro, Decimal montoTotal, Integer numRecibos) {
        Tech_Plan_de_Pago__c plan = new Tech_Plan_de_Pago__c();
//        plan.Name = 'Plan Seguro Test';
        plan.Seguro__c = seguro.Id;
        plan.Periodo_Pago__c = pickValue('Tech_Plan_de_Pago__c', 'Periodo_Pago__c', new List<String>{ 'Mensual', 'Contado' });
        plan.Num_recibos__c = numRecibos;
        plan.Monto_total__c = montoTotal;
        plan.Fecha_inicio__c = Date.today();
        plan.Estatus__c = pickValue('Tech_Plan_de_Pago__c', 'Estatus__c', new List<String>{ 'Activo' });
        plan.Estado__c = pickValue('Tech_Plan_de_Pago__c', 'Estado__c', new List<String>{ 'Activo' });
        insert plan;
        return plan;
    }

    public static Tech_Plan_de_Pago__c crearPlanFianza(Tech_Fianza__c fianza, Decimal montoTotal, Integer numRecibos) {
        Tech_Plan_de_Pago__c plan = new Tech_Plan_de_Pago__c();
//        plan.Name = 'Plan Fianza Test';
        plan.Fianzas__c = fianza.Id;
        plan.Periodo_Pago__c = pickValue('Tech_Plan_de_Pago__c', 'Periodo_Pago__c', new List<String>{ 'Mensual', 'Contado' });
        plan.Num_recibos__c = numRecibos;
        plan.Monto_total__c = montoTotal;
        plan.Fecha_inicio__c = Date.today();
        plan.Estatus__c = pickValue('Tech_Plan_de_Pago__c', 'Estatus__c', new List<String>{ 'Activo' });
        plan.Estado__c = pickValue('Tech_Plan_de_Pago__c', 'Estado__c', new List<String>{ 'Activo' });
        insert plan;
        return plan;
    }

    public static Tech_Recibo_Pago__c crearRecibo(
        Tech_Plan_de_Pago__c plan,
        Tech_Seguro__c seguro,
        Integer numero,
        Date fechaProgramada,
        Decimal monto
    ) {
        Tech_Recibo_Pago__c recibo = new Tech_Recibo_Pago__c();
//        recibo.Name = 'Recibo Test ' + numero;
        recibo.Plan_de_Pagos__c = plan.Id;
        if (seguro != null) recibo.Seguro__c = seguro.Id;
        recibo.Numero__c = numero;
        recibo.Fecha_programada__c = fechaProgramada;
        recibo.Monto_programado__c = monto;
        recibo.Estado__c = pickValue('Tech_Recibo_Pago__c', 'Estado__c', new List<String>{ 'Programado' });
//        recibo.Periodo_Pago__c = pickValue('Tech_Recibo_Pago__c', 'Periodo_Pago__c', new List<String>{ 'Mensual', 'Contado' });
        insert recibo;
        return recibo;
    }
}