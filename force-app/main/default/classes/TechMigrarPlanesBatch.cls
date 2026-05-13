/**
 * TechMigrarPlanesBatch
 * Copia Plan_de_Pagos__c → Tech_Plan_de_Pago__c.
 * Dedup: si ya existe un Tech_Plan_de_Pago__c con mismo Seguros__c + Fecha_inicio__c, se omite.
 * Tech_Plan_de_Pago__c.Name es auto-número (no escribible).
 *
 * EJECUTAR ANTES de TechMigrarRecibosBatch.
 * Anonymous Apex: Database.executeBatch(new TechMigrarPlanesBatch(), 200);
 */
public class TechMigrarPlanesBatch implements Database.Batchable<SObject>, Database.Stateful {

    public Integer migrados = 0;
    public Integer omitidos = 0;
    public Integer errores  = 0;

    // Map de (SeguroId + '|' + FechaInicio) para detectar duplicados
    private Map<String, Boolean> yaExistenGlobal = new Map<String, Boolean>();

    private static final Map<String, String> ESTADO_MAP = new Map<String, String>{
        'Activo'    => 'Activo',
        'En_mora'   => 'En mora',
        'En mora'   => 'En mora',
        'Pagado'    => 'Activo',
        'Cancelado' => 'Activo',
        'Pausado'   => 'Activo'
    };

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Precarga de planes ya existentes en Tech_ (para dedup global)
        for (Tech_Plan_de_Pago__c tp : [
            SELECT Seguro__c, Fecha_inicio__c FROM Tech_Plan_de_Pago__c
            WHERE Seguro__c != null
        ]) {
            String key = String.valueOf(tp.Seguro__c) + '|' + String.valueOf(tp.Fecha_inicio__c);
            yaExistenGlobal.put(key, true);
        }
        return Database.getQueryLocator([
            SELECT Id, Name, Estado__c, Fecha_inicio__c, Frecuencia__c,
                   Monto__c, Num_recibos__c, Seguro__c
            FROM Plan_de_Pagos__c
            WHERE Seguro__c != null
            ORDER BY CreatedDate ASC
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Plan_de_Pagos__c> scope) {
        List<Tech_Plan_de_Pago__c> toInsert = new List<Tech_Plan_de_Pago__c>();

        for (Plan_de_Pagos__c p : scope) {
            String key = String.valueOf(p.Seguro__c) + '|' + String.valueOf(p.Fecha_inicio__c);
            if (yaExistenGlobal.containsKey(key)) {
                omitidos++;
                continue;
            }
            yaExistenGlobal.put(key, true); // marcar para evitar dupes dentro del mismo batch

            Tech_Plan_de_Pago__c tp = new Tech_Plan_de_Pago__c();
            tp.Estado__c       = ESTADO_MAP.containsKey(p.Estado__c)
                                     ? ESTADO_MAP.get(p.Estado__c)
                                     : 'Activo';
            tp.Fecha_inicio__c = p.Fecha_inicio__c;
            tp.Monto_total__c  = p.Monto__c;
            tp.Num_recibos__c  = p.Num_recibos__c;
            tp.Periodo_Pago__c = p.Frecuencia__c;
            tp.Seguro__c      = p.Seguro__c;
            toInsert.add(tp);
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
        System.debug('TechMigrarPlanesBatch COMPLETADO — migrados: ' + migrados
            + ' | omitidos: ' + omitidos + ' | errores: ' + errores);
    }
}