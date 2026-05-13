public with sharing class TechProspectoConversionService {

    /*
     * =====================================================================================
     * SERVICIO: Conversión de Prospecto / Lead a Cuenta
     * =====================================================================================
     *
     * Reglas principales:
     *
     * 1. Valida si el cliente ya existe como Account por:
     *    - CURP__c
     *    - RFC__c
     *    - Email
     *    - Phone
     *
     * 2. Si el Lead tiene CURP__c:
     *    - Se considera Persona Física.
     *    - Si no existe Account, se crea primero una Person Account.
     *    - Después se convierte el Lead usando esa Person Account.
     *
     * 3. Si el Lead NO tiene CURP__c:
     *    - Se considera Persona Moral / Empresa.
     *    - Si no existe Account, Salesforce crea una Business Account durante la conversión.
     *
     * 4. Después de convertir:
     *    - Se actualiza la Opportunity relacionada al Lead.
     *
     * IMPORTANTE:
     * - Este código asume que Person Accounts está habilitado en la org.
     * - Este código asume que Account tiene los campos personalizados RFC__c, CURP__c y Email__c.
     * - Este código asume que Opportunity tiene el campo personalizado Prospecto__c hacia Lead.
     */

    public static void convertirProspectosACuenta(List<Id> leadIds) {

        // ---------------------------------------------------------------------
        // 1. Validar entrada del método.
        // ---------------------------------------------------------------------
        if (leadIds == null || leadIds.isEmpty()) {
            return;
        }

        // ---------------------------------------------------------------------
        // 2. Consultar Prospectos / Leads a convertir.
        // ---------------------------------------------------------------------
        List<Lead> prospectos = [
            SELECT Id,
                   FirstName,
                   LastName,
                   Company,
                   Status,
                   IsConverted,
                   OwnerId,
                   RFC__c,
                   CURP__c,
                   Phone,
                   Email
            FROM Lead
            WHERE Id IN :leadIds
        ];

        if (prospectos.isEmpty()) {
            return;
        }

        // ---------------------------------------------------------------------
        // 3. Preparar valores para búsqueda de cuentas existentes.
        // ---------------------------------------------------------------------
        Set<String> rfcs = new Set<String>();
        Set<String> curps = new Set<String>();
        Set<String> telefonos = new Set<String>();
        Set<String> emails = new Set<String>();

        for (Lead prospecto : prospectos) {

            // Si el Lead ya está convertido, no se procesa.
            if (prospecto.IsConverted) {
                continue;
            }

            if (!String.isBlank(prospecto.RFC__c)) {
                rfcs.add(normalizarTexto(prospecto.RFC__c));
            }

            if (!String.isBlank(prospecto.CURP__c)) {
                curps.add(normalizarTexto(prospecto.CURP__c));
            }

            if (!String.isBlank(prospecto.Phone)) {
                telefonos.add(normalizarTelefono(prospecto.Phone));
            }

            if (!String.isBlank(prospecto.Email)) {
                emails.add(normalizarEmail(prospecto.Email));
            }
        }

        // ---------------------------------------------------------------------
        // 4. Consultar Accounts existentes por CURP, RFC, teléfono o email.
        //
        // Nota:
        // - Email__c es un campo personalizado sugerido para Business Account.
        // - PersonEmail es estándar para Person Account.
        // - PersonMobilePhone es estándar para Person Account.
        // ---------------------------------------------------------------------
        List<Account> cuentasExistentes = new List<Account>();

        if (
            !rfcs.isEmpty() ||
            !curps.isEmpty() ||
            !telefonos.isEmpty() ||
            !emails.isEmpty()
        ) {
            cuentasExistentes = [
                SELECT Id,
                       Name,
                       IsPersonAccount,
                       RecordTypeId,
                       RFC__c,
                       CURP__c,
                       Phone,
                       PersonMobilePhone,
                       Email__c,
                       PersonEmail
                FROM Account
                WHERE RFC__c IN :rfcs
                   OR CURP__c IN :curps
                   OR Phone IN :telefonos
                   OR PersonMobilePhone IN :telefonos
                   OR Email__c IN :emails
                   OR PersonEmail IN :emails
            ];
        }

        // ---------------------------------------------------------------------
        // 5. Crear mapas para búsqueda rápida de cuentas existentes.
        //
        // Prioridad:
        // 1) CURP
        // 2) RFC
        // 3) Email
        // 4) Teléfono
        // ---------------------------------------------------------------------
        Map<String, Account> cuentaPorCURP = new Map<String, Account>();
        Map<String, Account> cuentaPorRFC = new Map<String, Account>();
        Map<String, Account> cuentaPorEmail = new Map<String, Account>();
        Map<String, Account> cuentaPorTelefono = new Map<String, Account>();

        for (Account cuenta : cuentasExistentes) {

            if (!String.isBlank(cuenta.CURP__c)) {
                cuentaPorCURP.put(normalizarTexto(cuenta.CURP__c), cuenta);
            }

            if (!String.isBlank(cuenta.RFC__c)) {
                cuentaPorRFC.put(normalizarTexto(cuenta.RFC__c), cuenta);
            }

            if (!String.isBlank(cuenta.Email__c)) {
                cuentaPorEmail.put(normalizarEmail(cuenta.Email__c), cuenta);
            }

            if (!String.isBlank(cuenta.PersonEmail)) {
                cuentaPorEmail.put(normalizarEmail(cuenta.PersonEmail), cuenta);
            }

            if (!String.isBlank(cuenta.Phone)) {
                cuentaPorTelefono.put(normalizarTelefono(cuenta.Phone), cuenta);
            }

            if (!String.isBlank(cuenta.PersonMobilePhone)) {
                cuentaPorTelefono.put(normalizarTelefono(cuenta.PersonMobilePhone), cuenta);
            }
        }

        // ---------------------------------------------------------------------
        // 6. Relacionar cada Lead con una Account existente, si aplica.
        // ---------------------------------------------------------------------
        Map<Id, Account> cuentaExistentePorLead = new Map<Id, Account>();

        for (Lead prospecto : prospectos) {

            if (prospecto.IsConverted) {
                continue;
            }

            Account cuentaEncontrada = buscarCuentaExistente(
                prospecto,
                cuentaPorCURP,
                cuentaPorRFC,
                cuentaPorEmail,
                cuentaPorTelefono
            );

            if (cuentaEncontrada != null) {
                cuentaExistentePorLead.put(prospecto.Id, cuentaEncontrada);
            }
        }

        // ---------------------------------------------------------------------
        // 7. Crear Person Accounts para Leads con CURP que no tengan Account.
        //
        // Salesforce LeadConvert no permite indicar RecordTypeId para una Account
        // nueva, por eso primero creamos la Person Account y luego convertimos
        // el Lead usando setAccountId().
        // ---------------------------------------------------------------------
        Map<Id, Id> personAccountCreadaPorLead =
            crearPersonAccountsParaLeadsConCURP(
                prospectos,
                cuentaExistentePorLead
            );

        // ---------------------------------------------------------------------
        // 8. Obtener estatus válido para conversión de Lead.
        // ---------------------------------------------------------------------
        LeadStatus estatusConvertido = [
            SELECT Id, MasterLabel
            FROM LeadStatus
            WHERE IsConverted = true
            LIMIT 1
        ];

        // ---------------------------------------------------------------------
        // 9. Preparar conversiones de Lead.
        // ---------------------------------------------------------------------
        List<Database.LeadConvert> conversiones = new List<Database.LeadConvert>();

        for (Lead prospecto : prospectos) {

            if (prospecto.IsConverted) {
                continue;
            }

            Database.LeadConvert conversion = new Database.LeadConvert();

            // Lead a convertir.
            conversion.setLeadId(prospecto.Id);

            // Estatus convertido configurado en Salesforce.
            conversion.setConvertedStatus(estatusConvertido.MasterLabel);

            // Evita crear una Opportunity nueva, porque se actualizará la existente.
            conversion.setDoNotCreateOpportunity(true);

            // Si existe una cuenta previa, usarla.
            if (cuentaExistentePorLead.containsKey(prospecto.Id)) {

                conversion.setAccountId(
                    cuentaExistentePorLead.get(prospecto.Id).Id
                );

            }
            // Si se creó una Person Account para este Lead, usarla.
            else if (personAccountCreadaPorLead.containsKey(prospecto.Id)) {

                conversion.setAccountId(
                    personAccountCreadaPorLead.get(prospecto.Id)
                );
            }

            conversiones.add(conversion);
        }

        if (conversiones.isEmpty()) {
            return;
        }

        // ---------------------------------------------------------------------
        // 10. Ejecutar conversiones.
        //
        // allOrNone = false permite que si un Lead falla, los demás continúen.
        // ---------------------------------------------------------------------
        List<Database.LeadConvertResult> resultados =
            Database.convertLead(conversiones, false);

        // ---------------------------------------------------------------------
        // 11. Construir mapa Lead -> Account resultante.
        // ---------------------------------------------------------------------
        Map<Id, Id> cuentaPorLeadConvertido = new Map<Id, Id>();

        for (Database.LeadConvertResult resultado : resultados) {

            if (resultado.isSuccess()) {

                cuentaPorLeadConvertido.put(
                    resultado.getLeadId(),
                    resultado.getAccountId()
                );

            } else {

                // En producción conviene guardar estos errores en un objeto de bitácora.
                for (Database.Error error : resultado.getErrors()) {
                    System.debug(
                        'Error al convertir Lead ' +
                        resultado.getLeadId() +
                        ': ' +
                        error.getMessage()
                    );
                }
            }
        }

        if (cuentaPorLeadConvertido.isEmpty()) {
            return;
        }

        // ---------------------------------------------------------------------
        // 12. Actualizar datos fiscales y contacto en Account resultante.
        // ---------------------------------------------------------------------
        actualizarDatosFiscalesEnCuenta(cuentaPorLeadConvertido);

        // ---------------------------------------------------------------------
        // 13. Actualizar Opportunity relacionada al Lead convertido.
        // ---------------------------------------------------------------------
        actualizarOportunidadesRelacionadas(cuentaPorLeadConvertido);
    }

    /*
     * =====================================================================================
     * Crea Person Accounts para Leads con CURP cuando no existe Account relacionada.
     * =====================================================================================
     */
    private static Map<Id, Id> crearPersonAccountsParaLeadsConCURP(
        List<Lead> prospectos,
        Map<Id, Account> cuentaExistentePorLead
    ) {
        Map<Id, Id> accountIdPorLead = new Map<Id, Id>();

        // ---------------------------------------------------------------------
        // 1. Obtener Record Type de Person Account.
        // ---------------------------------------------------------------------
        Id personAccountRecordTypeId = obtenerPersonAccountRecordTypeId();

        // ---------------------------------------------------------------------
        // 2. Si no existe Record Type de Person Account, no se pueden crear.
        // ---------------------------------------------------------------------
        if (personAccountRecordTypeId == null) {

            for (Lead prospecto : prospectos) {

                if (
                    !prospecto.IsConverted &&
                    !String.isBlank(prospecto.CURP__c) &&
                    !cuentaExistentePorLead.containsKey(prospecto.Id)
                ) {
                    System.debug(
                        'No se puede crear Person Account para Lead ' +
                        prospecto.Id +
                        '. No existe Record Type de Person Account habilitado.'
                    );
                }
            }

            return accountIdPorLead;
        }

        // ---------------------------------------------------------------------
        // 3. Preparar Person Accounts a insertar.
        // ---------------------------------------------------------------------
        List<Account> personAccountsPorInsertar = new List<Account>();

        // Relaciona el índice de la lista con el Lead original.
        Map<Integer, Id> indiceLeadId = new Map<Integer, Id>();

        Integer indice = 0;

        for (Lead prospecto : prospectos) {

            // Omitir Leads ya convertidos.
            if (prospecto.IsConverted) {
                continue;
            }

            // Solo se crean Person Accounts cuando CURP__c está lleno.
            if (String.isBlank(prospecto.CURP__c)) {
                continue;
            }

            // Si ya existe cuenta, no se crea otra.
            if (cuentaExistentePorLead.containsKey(prospecto.Id)) {
                continue;
            }

            Account cuentaPersona = new Account();

            // Asignar Record Type de Person Account.
            cuentaPersona.RecordTypeId = personAccountRecordTypeId;

            // En Person Account, el nombre se maneja con FirstName y LastName.
            cuentaPersona.FirstName = prospecto.FirstName;

            cuentaPersona.LastName = String.isBlank(prospecto.LastName)
                ? 'Sin Apellido'
                : prospecto.LastName;

            // Datos de contacto para Person Account.
            cuentaPersona.PersonEmail = normalizarEmail(prospecto.Email);
            cuentaPersona.PersonMobilePhone = prospecto.Phone;

            // Datos fiscales / identificación.
            cuentaPersona.RFC__c = normalizarTexto(prospecto.RFC__c);
            cuentaPersona.CURP__c = normalizarTexto(prospecto.CURP__c);

            // Dueño de la cuenta igual al dueño del prospecto.
            cuentaPersona.OwnerId = prospecto.OwnerId;

            personAccountsPorInsertar.add(cuentaPersona);
            indiceLeadId.put(indice, prospecto.Id);
            indice++;
        }

        // ---------------------------------------------------------------------
        // 4. Insertar Person Accounts.
        // ---------------------------------------------------------------------
        if (!personAccountsPorInsertar.isEmpty()) {

            Database.SaveResult[] resultados =
                Database.insert(personAccountsPorInsertar, false);

            for (Integer i = 0; i < resultados.size(); i++) {

                Id leadId = indiceLeadId.get(i);

                if (resultados[i].isSuccess()) {

                    accountIdPorLead.put(
                        leadId,
                        resultados[i].getId()
                    );

                } else {

                    // Registrar errores de creación de Person Account.
                    for (Database.Error error : resultados[i].getErrors()) {
                        System.debug(
                            'Error al crear Person Account para Lead ' +
                            leadId +
                            ': ' +
                            error.getMessage()
                        );
                    }
                }
            }
        }

        return accountIdPorLead;
    }

    /*
     * =====================================================================================
     * Busca Account existente para un Lead.
     * =====================================================================================
     *
     * Prioridad:
     * 1. CURP
     * 2. RFC
     * 3. Email
     * 4. Teléfono
     */
    private static Account buscarCuentaExistente(
        Lead prospecto,
        Map<String, Account> cuentaPorCURP,
        Map<String, Account> cuentaPorRFC,
        Map<String, Account> cuentaPorEmail,
        Map<String, Account> cuentaPorTelefono
    ) {

        // ---------------------------------------------------------------------
        // 1. Buscar por CURP.
        // ---------------------------------------------------------------------
        if (!String.isBlank(prospecto.CURP__c)) {
            String curp = normalizarTexto(prospecto.CURP__c);

            if (cuentaPorCURP.containsKey(curp)) {
                return cuentaPorCURP.get(curp);
            }
        }

        // ---------------------------------------------------------------------
        // 2. Buscar por RFC.
        // ---------------------------------------------------------------------
        if (!String.isBlank(prospecto.RFC__c)) {
            String rfc = normalizarTexto(prospecto.RFC__c);

            if (cuentaPorRFC.containsKey(rfc)) {
                return cuentaPorRFC.get(rfc);
            }
        }

        // ---------------------------------------------------------------------
        // 3. Buscar por email.
        // ---------------------------------------------------------------------
        if (!String.isBlank(prospecto.Email)) {
            String email = normalizarEmail(prospecto.Email);

            if (cuentaPorEmail.containsKey(email)) {
                return cuentaPorEmail.get(email);
            }
        }

        // ---------------------------------------------------------------------
        // 4. Buscar por teléfono.
        // ---------------------------------------------------------------------
        if (!String.isBlank(prospecto.Phone)) {
            String telefono = normalizarTelefono(prospecto.Phone);

            if (cuentaPorTelefono.containsKey(telefono)) {
                return cuentaPorTelefono.get(telefono);
            }
        }

        return null;
    }

    /*
     * =====================================================================================
     * Obtiene el Record Type Id de Person Account.
     * =====================================================================================
     *
     * Si Person Accounts no está habilitado, normalmente no existirá RecordType
     * de Account con IsPersonType = true.
     */
    private static Id obtenerPersonAccountRecordTypeId() {

        List<RecordType> recordTypes = [
            SELECT Id,
                   DeveloperName,
                   IsPersonType
            FROM RecordType
            WHERE SObjectType = 'Account'
              AND IsPersonType = true
            LIMIT 1
        ];

        if (recordTypes.isEmpty()) {
            return null;
        }

        return recordTypes[0].Id;
    }

    /*
     * =====================================================================================
     * Actualiza RFC, CURP, teléfono y email en la Account resultante.
     * =====================================================================================
     */
    private static void actualizarDatosFiscalesEnCuenta(
        Map<Id, Id> cuentaPorLeadConvertido
    ) {

        // ---------------------------------------------------------------------
        // 1. Consultar Leads convertidos.
        // ---------------------------------------------------------------------
        List<Lead> leadsConvertidos = [
            SELECT Id,
                   RFC__c,
                   CURP__c,
                   Phone,
                   Email
            FROM Lead
            WHERE Id IN :cuentaPorLeadConvertido.keySet()
        ];

        // ---------------------------------------------------------------------
        // 2. Consultar Accounts resultantes.
        // ---------------------------------------------------------------------
        Set<Id> accountIds = new Set<Id>();
        accountIds.addAll(cuentaPorLeadConvertido.values());

        Map<Id, Account> cuentas = new Map<Id, Account>([
            SELECT Id,
                   IsPersonAccount,
                   RFC__c,
                   CURP__c,
                   Phone,
                   PersonMobilePhone,
                   Email__c,
                   PersonEmail
            FROM Account
            WHERE Id IN :accountIds
        ]);

        // ---------------------------------------------------------------------
        // 3. Completar datos faltantes en Account.
        // ---------------------------------------------------------------------
        List<Account> cuentasPorActualizar = new List<Account>();

        for (Lead leadConvertido : leadsConvertidos) {

            Id accountId = cuentaPorLeadConvertido.get(leadConvertido.Id);

            if (accountId == null || !cuentas.containsKey(accountId)) {
                continue;
            }

            Account cuenta = cuentas.get(accountId);
            Boolean requiereActualizar = false;

            // Actualizar RFC si la Account no lo tiene.
            if (
                String.isBlank(cuenta.RFC__c) &&
                !String.isBlank(leadConvertido.RFC__c)
            ) {
                cuenta.RFC__c = normalizarTexto(leadConvertido.RFC__c);
                requiereActualizar = true;
            }

            // Actualizar CURP si la Account no lo tiene.
            if (
                String.isBlank(cuenta.CURP__c) &&
                !String.isBlank(leadConvertido.CURP__c)
            ) {
                cuenta.CURP__c = normalizarTexto(leadConvertido.CURP__c);
                requiereActualizar = true;
            }

            // Actualizar teléfono según tipo de Account.
            if (!String.isBlank(leadConvertido.Phone)) {

                if (
                    cuenta.IsPersonAccount &&
                    String.isBlank(cuenta.PersonMobilePhone)
                ) {
                    cuenta.PersonMobilePhone = leadConvertido.Phone;
                    requiereActualizar = true;
                }

                if (
                    !cuenta.IsPersonAccount &&
                    String.isBlank(cuenta.Phone)
                ) {
                    cuenta.Phone = leadConvertido.Phone;
                    requiereActualizar = true;
                }
            }

            // Actualizar email según tipo de Account.
            if (!String.isBlank(leadConvertido.Email)) {

                if (
                    cuenta.IsPersonAccount &&
                    String.isBlank(cuenta.PersonEmail)
                ) {
                    cuenta.PersonEmail = normalizarEmail(leadConvertido.Email);
                    requiereActualizar = true;
                }

                if (
                    !cuenta.IsPersonAccount &&
                    String.isBlank(cuenta.Email__c)
                ) {
                    cuenta.Email__c = normalizarEmail(leadConvertido.Email);
                    requiereActualizar = true;
                }
            }

            if (requiereActualizar) {
                cuentasPorActualizar.add(cuenta);
            }
        }

        // ---------------------------------------------------------------------
        // 4. Actualizar Accounts.
        // ---------------------------------------------------------------------
        if (!cuentasPorActualizar.isEmpty()) {
            update cuentasPorActualizar;
        }
    }

    /*
     * =====================================================================================
     * Actualiza Opportunity relacionada al Lead convertido.
     * =====================================================================================
     *
     * Supuesto:
     * - Opportunity tiene un lookup personalizado llamado Prospecto__c hacia Lead.
     */
    private static void actualizarOportunidadesRelacionadas(
        Map<Id, Id> cuentaPorLeadConvertido
    ) {

        // ---------------------------------------------------------------------
        // 1. Consultar Opportunities relacionadas al Lead.
        // ---------------------------------------------------------------------
        List<Opportunity> oportunidades = [
            SELECT Id,
                   Prospecto__c,
                   AccountId
            FROM Opportunity
            WHERE Prospecto__c IN :cuentaPorLeadConvertido.keySet()
        ];

        // ---------------------------------------------------------------------
        // 2. Asignar Account resultante a cada Opportunity.
        // ---------------------------------------------------------------------
        List<Opportunity> oportunidadesPorActualizar = new List<Opportunity>();

        for (Opportunity oportunidad : oportunidades) {

            Id cuentaId = cuentaPorLeadConvertido.get(oportunidad.Prospecto__c);

            if (cuentaId != null && oportunidad.AccountId != cuentaId) {
                oportunidad.AccountId = cuentaId;
                oportunidadesPorActualizar.add(oportunidad);
            }
        }

        // ---------------------------------------------------------------------
        // 3. Guardar cambios en Opportunity.
        // ---------------------------------------------------------------------
        if (!oportunidadesPorActualizar.isEmpty()) {
            update oportunidadesPorActualizar;
        }
    }

    /*
     * =====================================================================================
     * Normaliza RFC, CURP y textos similares.
     * =====================================================================================
     */
    private static String normalizarTexto(String valor) {

        if (String.isBlank(valor)) {
            return null;
        }

        return valor.trim().toUpperCase();
    }

    /*
     * =====================================================================================
     * Normaliza email.
     * =====================================================================================
     */
    private static String normalizarEmail(String valor) {

        if (String.isBlank(valor)) {
            return null;
        }

        return valor.trim().toLowerCase();
    }

    /*
     * =====================================================================================
     * Normaliza teléfono.
     * =====================================================================================
     *
     * Esta versión elimina:
     * - espacios
     * - guiones
     * - paréntesis
     */
    private static String normalizarTelefono(String valor) {

        if (String.isBlank(valor)) {
            return null;
        }

        return valor
            .replace(' ', '')
            .replace('-', '')
            .replace('(', '')
            .replace(')', '')
            .trim();
    }

    /*
     * =====================================================================================
     * Clase de entrada para invocar desde Flow Builder.
     * =====================================================================================
     */
    public class SolicitudConversion {

        @InvocableVariable(
            label='Id del Prospecto'
            description='Id del Lead / Prospecto que se desea convertir.'
            required=true
        )
        public Id leadId;
    }

    /*
     * =====================================================================================
     * Método invocable para Flow Builder.
     * =====================================================================================
     */
    @InvocableMethod(
        label='Convertir Prospecto a Cuenta'
        description='Convierte prospectos a cuentas validando CURP, RFC, teléfono y email.'
    )
    public static void convertirDesdeFlow(List<SolicitudConversion> solicitudes) {

        // ---------------------------------------------------------------------
        // 1. Validar solicitudes recibidas desde Flow.
        // ---------------------------------------------------------------------
        if (solicitudes == null || solicitudes.isEmpty()) {
            return;
        }

        // ---------------------------------------------------------------------
        // 2. Extraer Ids de Leads.
        // ---------------------------------------------------------------------
        List<Id> leadIds = new List<Id>();

        for (SolicitudConversion solicitud : solicitudes) {
            if (solicitud != null && solicitud.leadId != null) {
                leadIds.add(solicitud.leadId);
            }
        }

        // ---------------------------------------------------------------------
        // 3. Ejecutar conversión.
        // ---------------------------------------------------------------------
        convertirProspectosACuenta(leadIds);
    }
}