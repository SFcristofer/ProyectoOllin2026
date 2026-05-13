/**
 * TechMigrarSegurosBatch
 * Copia registros de Seguro__c → Tech_Seguro__c.
 * Dedup: si ya existe un Tech_Seguro__c con el mismo Numero_poliza__c, se omite.
 *
 * Ejecutar en Anonymous Apex:
 *   Database.executeBatch(new TechMigrarSegurosBatch(), 200);
 */
public class TechMigrarSegurosBatch implements Database.Batchable<SObject>, Database.Stateful {

    public Integer migrados  = 0;
    public Integer omitidos  = 0;
    public Integer errores   = 0;

    private static final Map<String, String> ESTATUS_MAP = new Map<String, String>{
        'Vigente'        => 'Vigente',
        'Por renovar'    => 'Por renovar',
        'En renovación'  => 'Por renovar',
        'Renovada'       => 'Renovada',
        'No renovada'    => 'Vencida',
        'Cancelada'      => 'Cancelada'
    };

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Numero_poliza__c, Cliente__c, Estatus__c,
                   Inicio_del_seguro__c, Fin_del_seguro__c, Frecuencia_de_pago__c,
                   Prima_neta__c, Prima_total__c, Ramo__c,
                   Oportunidad__c, Producto__c, Promotoria__c,
                   Tipo_originador__c, Vendedor__c, Descripcion__c
            FROM Seguro__c
            ORDER BY CreatedDate ASC
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Seguro__c> scope) {
        // Índice de seguros ya existentes en Tech_ por Numero_poliza__c
        Set<String> polizasScope = new Set<String>();
        for (Seguro__c s : scope) {
            if (s.Numero_poliza__c != null) polizasScope.add(s.Numero_poliza__c);
        }
        Map<String, Id> yaExisten = new Map<String, Id>();
        for (Tech_Seguro__c ts : [
            SELECT Id, Numero_poliza__c FROM Tech_Seguro__c
            WHERE Numero_poliza__c IN :polizasScope
        ]) {
            yaExisten.put(ts.Numero_poliza__c, ts.Id);
        }

        List<Tech_Seguro__c> toInsert = new List<Tech_Seguro__c>();
        for (Seguro__c s : scope) {
            if (s.Numero_poliza__c != null && yaExisten.containsKey(s.Numero_poliza__c)) {
                omitidos++;
                continue;
            }
            Tech_Seguro__c ts = new Tech_Seguro__c();
            ts.Name                = s.Name;
            ts.Numero_poliza__c    = s.Numero_poliza__c;
            ts.Cliente__c          = s.Cliente__c;
            ts.Estatus__c          = ESTATUS_MAP.containsKey(s.Estatus__c)
                                        ? ESTATUS_MAP.get(s.Estatus__c)
                                        : 'Vigente';
            ts.Inicio_del_seguro__c = s.Inicio_del_seguro__c;
            ts.Fin_del_seguro__c   = s.Fin_del_seguro__c;
            ts.Frecuencia_de_pago__c = s.Frecuencia_de_pago__c;
            ts.Prima_neta__c       = s.Prima_neta__c;
            ts.Ramo__c             = s.Ramo__c;
            ts.Oportunidad__c      = s.Oportunidad__c;
            ts.Producto__c         = s.Producto__c;
            ts.Promotoria__c       = s.Promotoria__c;
            ts.Tipo_originador__c  = s.Tipo_originador__c;
            ts.Vendedor__c         = s.Vendedor__c;
            ts.Descripcion__c      = s.Descripcion__c;
            toInsert.add(ts);
        }

        if (!toInsert.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(toInsert, false);
            for (Database.SaveResult r : results) {
                if (r.isSuccess()) migrados++;
                else errores++;
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('TechMigrarSegurosBatch COMPLETADO — migrados: ' + migrados
            + ' | omitidos: ' + omitidos + ' | errores: ' + errores);
    }
}