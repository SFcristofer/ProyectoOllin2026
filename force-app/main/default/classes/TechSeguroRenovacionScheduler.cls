public with sharing class TechSeguroRenovacionScheduler implements Schedulable {

    public void execute(SchedulableContext context) {
        procesarRenovaciones();
    }

    public static void procesarRenovaciones() {

        Date hoy = Date.today();
        Date fechaMaxima = hoy.addDays(60);

        List<Tech_Seguro__c> seguros = [
            SELECT Id,
                   Name,
                   Cliente__c,
                   Cliente__r.Name,
                   Vendedor__c,
                   Vendedor__r.Name,
                   Vendedor__r.Email__c,
                   Vendedor__r.Usuario_Salesforce__r.Email,
                   Producto__c,
                   Producto__r.Name,
                   Subproducto__c,
                   Aseguradora__c,
                   Aseguradora__r.Name,
                   Ramo__c,
                   Inicio_del_seguro__c,
                   Fin_del_seguro__c,
                   Prima_neta__c,
                   Forma_Pago__c,
                   Frecuencia_de_pago__c,
                   Vigencia__c,
                   Estatus__c
            FROM Tech_Seguro__c
            WHERE Fin_del_seguro__c != null
              AND Fin_del_seguro__c >= :hoy
              AND Fin_del_seguro__c <= :fechaMaxima
              AND Estatus__c != 'Por renovar'
              AND Estatus__c != 'Renovado'
              AND Estatus__c != 'Cancelado'
        ];

        if (seguros.isEmpty()) {
            return;
        }

        Set<Id> seguroIds = new Set<Id>();

        for (Tech_Seguro__c seguro : seguros) {
            seguroIds.add(seguro.Id);
        }

        Map<Id, Opportunity> oportunidadRenovacionPorSeguro =
            new Map<Id, Opportunity>();

        for (Opportunity opp : [
            SELECT Id,
                   Poliza_Renovar__c,
                   IsClosed
            FROM Opportunity
            WHERE Poliza_Renovar__c IN :seguroIds
              AND IsClosed = false
        ]) {
            oportunidadRenovacionPorSeguro.put(opp.Poliza_Renovar__c, opp);
        }

        List<Tech_Seguro__c> segurosPorActualizar = new List<Tech_Seguro__c>();
        List<Opportunity> oportunidadesPorInsertar = new List<Opportunity>();
        List<Tech_Seguro__c> segurosPorNotificar = new List<Tech_Seguro__c>();

        String etapaInicial = obtenerEtapaInicialOpportunity();

        for (Tech_Seguro__c seguro : seguros) {

            Integer diasAntes = obtenerDiasAntesRenovacion(seguro.Ramo__c);
            Date fechaInicioRenovacion = seguro.Fin_del_seguro__c.addDays(-diasAntes);

            if (hoy < fechaInicioRenovacion) {
                continue;
            }

            seguro.Estatus__c = 'Por renovar';
            segurosPorActualizar.add(seguro);

            if (oportunidadRenovacionPorSeguro.containsKey(seguro.Id)) {
                continue;
            }

            Opportunity oppRenovacion = new Opportunity();

            oppRenovacion.Name = 'Renovación - ' + seguro.Name;
            oppRenovacion.StageName = etapaInicial;
            oppRenovacion.CloseDate = seguro.Fin_del_seguro__c;
            oppRenovacion.AccountId = seguro.Cliente__c;

            oppRenovacion.Vendedor_A__c = seguro.Vendedor__c;
            oppRenovacion.Producto__c = seguro.Producto__c;
            oppRenovacion.Subproducto__c = seguro.Subproducto__c;
            oppRenovacion.Institucion__c = seguro.Aseguradora__c;
            oppRenovacion.Ramo__c = seguro.Ramo__c;

            oppRenovacion.Fecha_Inicio_Vigencia__c =
                seguro.Fin_del_seguro__c.addDays(1);

            if (seguro.Vigencia__c != null && seguro.Vigencia__c > 0) {
                oppRenovacion.Fecha_Fin_Vigencia__c =
                    oppRenovacion.Fecha_Inicio_Vigencia__c.addMonths(
                        seguro.Vigencia__c.intValue()
                    );
            }

            oppRenovacion.Vigencia__c = seguro.Vigencia__c;
            oppRenovacion.Metodo_Pago__c = seguro.Forma_Pago__c;
            oppRenovacion.Periodo_Pago__c = seguro.Frecuencia_de_pago__c;
            oppRenovacion.Amount = seguro.Prima_neta__c;
            oppRenovacion.Poliza_Renovar__c = seguro.Id;

            oportunidadesPorInsertar.add(oppRenovacion);
            segurosPorNotificar.add(seguro);
        }

        if (!segurosPorActualizar.isEmpty()) {
            update segurosPorActualizar;
        }

        if (!oportunidadesPorInsertar.isEmpty()) {
            insert oportunidadesPorInsertar;

            enviarNotificacionesRenovacion(
                segurosPorNotificar,
                oportunidadesPorInsertar
            );
        }
    }

    private static Integer obtenerDiasAntesRenovacion(String ramo) {

        if (String.isBlank(ramo)) {
            return 30;
        }

        if (ramo == 'Auto' || ramo == 'Autos') {
            return 30;
        }

        if (ramo == 'Gastos Médicos' || ramo == 'GMM') {
            return 45;
        }

        if (ramo == 'Vida') {
            return 60;
        }

        if (ramo == 'PPR') {
            return 60;
        }

        if (ramo == 'Daños' || ramo == 'Danos') {
            return 45;
        }

        if (ramo == 'Fianzas' || ramo == 'Fianza') {
            return 30;
        }

        return 30;
    }

    private static String obtenerEtapaInicialOpportunity() {

        List<OpportunityStage> etapas = [
            SELECT MasterLabel
            FROM OpportunityStage
            WHERE IsClosed = false
            ORDER BY SortOrder ASC
            LIMIT 1
        ];

        if (!etapas.isEmpty()) {
            return etapas[0].MasterLabel;
        }

        return 'Prospecting';
    }

    private static void enviarNotificacionesRenovacion(
        List<Tech_Seguro__c> seguros,
        List<Opportunity> oportunidades
    ) {
        if (seguros == null || seguros.isEmpty()) {
            return;
        }

        List<Messaging.SingleEmailMessage> correos =
            new List<Messaging.SingleEmailMessage>();

        for (Integer i = 0; i < seguros.size(); i++) {

            Tech_Seguro__c seguro = seguros[i];
            Opportunity oportunidad = oportunidades[i];

            String emailVendedor;

            if (
                seguro.Vendedor__r != null &&
                !String.isBlank(seguro.Vendedor__r.Email__c)
            ) {
                emailVendedor = seguro.Vendedor__r.Email__c;
            } else if (
                seguro.Vendedor__r != null &&
                seguro.Vendedor__r.Usuario_Salesforce__r != null &&
                !String.isBlank(seguro.Vendedor__r.Usuario_Salesforce__r.Email)
            ) {
                emailVendedor = seguro.Vendedor__r.Usuario_Salesforce__r.Email;
            }

            if (String.isBlank(emailVendedor)) {
                continue;
            }

            String nombreVendedor = seguro.Vendedor__r != null
                ? seguro.Vendedor__r.Name
                : 'Vendedor';

            String nombreCliente = seguro.Cliente__r != null
                ? seguro.Cliente__r.Name
                : 'Cliente no especificado';

            String nombreProducto = seguro.Producto__r != null
                ? seguro.Producto__r.Name
                : 'Producto no especificado';

            String nombreAseguradora = seguro.Aseguradora__r != null
                ? seguro.Aseguradora__r.Name
                : 'Aseguradora no especificada';

            String asunto = 'Renovación próxima - ' + seguro.Name;

            String cuerpo =
                'Hola ' + nombreVendedor + ',\n\n' +
                'Se ha generado una oportunidad de renovación para el siguiente seguro:\n\n' +
                'Cliente: ' + nombreCliente + '\n' +
                'Seguro: ' + seguro.Name + '\n' +
                'Ramo: ' + seguro.Ramo__c + '\n' +
                'Producto: ' + nombreProducto + '\n' +
                'Aseguradora: ' + nombreAseguradora + '\n' +
                'Fecha de vencimiento: ' + String.valueOf(seguro.Fin_del_seguro__c) + '\n' +
                'Prima actual: $' + String.valueOf(seguro.Prima_neta__c) + '\n\n' +
                'Oportunidad creada: ' + oportunidad.Name + '\n' +
                'Fecha estimada de cierre: ' + String.valueOf(oportunidad.CloseDate) + '\n\n' +
                'Acción requerida:\n' +
                '1. Contactar al cliente.\n' +
                '2. Confirmar condiciones de renovación.\n' +
                '3. Actualizar la oportunidad con la nueva propuesta.\n\n' +
                'Este mensaje fue generado automáticamente por Salesforce.\n';

            Messaging.SingleEmailMessage correo =
                new Messaging.SingleEmailMessage();

            correo.setToAddresses(new List<String>{ emailVendedor });
//            correo.setReplyTo('abner.trujillo@technovalue.com.mx');
            correo.setSenderDisplayName('Ollin Protección');
            correo.setSubject(asunto);
            correo.setPlainTextBody(cuerpo);
            correo.setSaveAsActivity(false);

            correos.add(correo);
        }

        if (!correos.isEmpty()) {
            try {
                Messaging.sendEmail(correos, false);
            } catch (Exception e) {
                System.debug(
                    'Error al enviar notificaciones de renovación: ' +
                    e.getMessage()
                );
            }
        }
    }

    public static void programarDiario() {

        String cron = '0 0 2 * * ?';

        System.schedule(
            'TECH - Renovación diaria de seguros',
            cron,
            new TechSeguroRenovacionScheduler()
        );
    }
}