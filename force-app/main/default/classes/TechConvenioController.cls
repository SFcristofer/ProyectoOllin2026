public with sharing class TechConvenioController {
    @AuraEnabled
    public static List<TechConvenioWrapper> getConveniosByContrato(String contratoId) {
        List<TechConvenioWrapper> wrappers = new List<TechConvenioWrapper>();
        for (Tech_Convenio_Modificatorio__c c : [
            SELECT Id, Name, Numero_Convenio__c,
                   Contract__c, Contract__r.ContractNumber,
                   Tipo_de_Modificacion__c, Fecha_del_Convenio__c,
                   Nuevo_Valor_Contrato__c, Diferencia_Monto__c,
                   Nueva_Fecha_Fin__c, Descripcion__c, Motivo__c
            FROM Tech_Convenio_Modificatorio__c
            WHERE Contract__c = :contratoId
            ORDER BY Fecha_del_Convenio__c DESC
            LIMIT 100
        ]) {
            wrappers.add(new TechConvenioWrapper(c));
        }
        return wrappers;
    }

    @AuraEnabled(cacheable=true)
    public static List<TechConvenioWrapper> getConveniosList() {
        List<TechConvenioWrapper> wrappers = new List<TechConvenioWrapper>();
        for (Tech_Convenio_Modificatorio__c c : TechConvenioSelector.getRecentConvenios()) {
            wrappers.add(new TechConvenioWrapper(c));
        }
        return wrappers;
    }

    @AuraEnabled
    public static String saveConvenio(Tech_Convenio_Modificatorio__c convenio) {
        try {
            upsert convenio;
            return convenio.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar convenio: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String crearConvenioConEndosos(Map<String,Object> convenioData, List<Map<String,Object>> endososData) {
        Savepoint sp = Database.setSavepoint();
        try {
            Tech_Convenio_Modificatorio__c cv = new Tech_Convenio_Modificatorio__c();
            if (convenioData.containsKey('contratoId'))    cv.Contract__c              = (Id)convenioData.get('contratoId');
            if (convenioData.containsKey('tipo'))          cv.Tipo_de_Modificacion__c  = String.valueOf(convenioData.get('tipo'));
            if (convenioData.containsKey('descripcion'))   cv.Descripcion__c           = String.valueOf(convenioData.get('descripcion'));
            if (convenioData.containsKey('nuevoValor') && convenioData.get('nuevoValor') != null)
                cv.Nuevo_Valor_Contrato__c = Decimal.valueOf(String.valueOf(convenioData.get('nuevoValor')));
            if (convenioData.containsKey('nuevaFechaFin') && convenioData.get('nuevaFechaFin') != null)
                cv.Nueva_Fecha_Fin__c = Date.valueOf(String.valueOf(convenioData.get('nuevaFechaFin')));
            if (convenioData.containsKey('fecha') && convenioData.get('fecha') != null)
                cv.Fecha_del_Convenio__c = Date.valueOf(String.valueOf(convenioData.get('fecha')));
            insert cv;

            if (endososData != null && !endososData.isEmpty()) {
                List<Tech_Endoso__c> endosos = new List<Tech_Endoso__c>();
                for (Map<String,Object> ed : endososData) {
                    Tech_Endoso__c e = new Tech_Endoso__c();
                    e.Convenio__c = cv.Id;
                    if (ed.containsKey('fianzaId'))    e.Fianza__c              = (Id)ed.get('fianzaId');
                    if (ed.containsKey('tipoEndoso'))  e.Tipo_endoso__c         = String.valueOf(ed.get('tipoEndoso'));
                    if (ed.containsKey('nuevoMonto') && ed.get('nuevoMonto') != null)
                        e.Nuevo_Monto_Afianzado__c = Decimal.valueOf(String.valueOf(ed.get('nuevoMonto')));
                    if (ed.containsKey('nuevaPrima') && ed.get('nuevaPrima') != null)
                        e.Nueva_prima__c = Decimal.valueOf(String.valueOf(ed.get('nuevaPrima')));
                    if (ed.containsKey('nuevaFechaVencimiento') && ed.get('nuevaFechaVencimiento') != null)
                        e.Fin_Vigencia__c = Date.valueOf(String.valueOf(ed.get('nuevaFechaVencimiento')));
                    e.Estado__c = 'Borrador';
                    endosos.add(e);
                }
                insert endosos;
            }

            if (convenioData.containsKey('nuevoValor') && convenioData.get('nuevoValor') != null
                && convenioData.containsKey('contratoId')) {
                Contract c = new Contract(
                    Id = (Id)convenioData.get('contratoId'),
                    Valor_Contrato_Vigente__c = Decimal.valueOf(String.valueOf(convenioData.get('nuevoValor')))
                );
                if (convenioData.containsKey('nuevaFechaFin') && convenioData.get('nuevaFechaFin') != null)
                    c.Fin_Contrato_Vigente__c = Date.valueOf(String.valueOf(convenioData.get('nuevaFechaFin')));
                update c;
            }

            return cv.Id;
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Error al crear convenio con endosos: ' + e.getMessage());
        }
    }
}