/**
 * TechMigrarRecibosBatch
 * Copia Recibo_de_Cobro__c → Tech_Recibo_Pago__c.
 * Dedup: si ya existe un Tech_Recibo_Pago__c con el mismo Numero__c, se omite.
 * Sólo migra recibos con Plan padre. Name y Cliente_Nombre__c son auto/fórmula (no se escriben).
 *
 * EJECUTAR DESPUÉS de TechMigrarPlanesBatch.
 * Anonymous Apex: Database.executeBatch(new TechMigrarRecibosBatch(), 100);
 */
public class TechMigrarRecibosBatch implements Database.Batchable<SObject>, Database.Stateful {

    public Integer migrados = 0;
    public Integer omitidos = 0;
    public Integer sinPlan  = 0;
    public Integer errores  = 0;

    // Precargado en start(): SeguroId|FechaInicio → Tech_Plan_de_Pago__c.Id
    private Map<String, Id> planKeyToTechId = new Map<String, Id>();
    // Numeros ya existentes en Tech_Recibo_Pago__c
    private Set<Decimal> numerosYaMigrados = new Set<Decimal>();

    private static final Map<String, String> ESTADO_MAP = new Map<String, String>{
        'Pendiente'   => 'Por cobrar',
        'Vencido'     => 'Vencido',
        'Parcial'     => 'Parcial',
        'Pagado'      => 'Cobrado',
        'Cancelado'   => 'Anulado',
        'Reembolsado' => 'Anulado'
    };

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Índice de Tech_Plans por SeguroId + FechaInicio
        for (Tech_Plan_de_Pago__c tp : [
            SELECT Id, Seguro__c, Fecha_inicio__c FROM Tech_Plan_de_Pago__c
            WHERE Seguro__c != null
        ]) {
            String key = String.valueOf(tp.Seguro__c) + '|' + String.valueOf(tp.Fecha_inicio__c);
            planKeyToTechId.put(key, tp.Id);
        }
        // Numeros ya migrados
        for (Tech_Recibo_Pago__c tr : [
            SELECT Numero__c FROM Tech_Recibo_Pago__c WHERE Numero__c != null
        ]) {
            numerosYaMigrados.add(tr.Numero__c);
        }
        return Database.getQueryLocator([
            SELECT Id, Numero__c, Estado__c,
                   Fecha_programada__c, Fecha_pago__c,
                   Monto_programado__c, Monto_pagado__c,
                   Metodo_pago__c, Motivo_No_Pago__c,
                   Referencia_pago__c, Intentos_Contacto__c,
                   Poliza_numero__c,
                   Plan_de_Pagos__c, Plan_de_Pagos__r.Seguro__c,
                   Plan_de_Pagos__r.Fecha_inicio__c
            FROM Recibo_de_Cobro__c
            WHERE Plan_de_Pagos__c != null
            ORDER BY CreatedDate ASC
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Recibo_de_Cobro__c> scope) {
        List<Tech_Recibo_Pago__c> toInsert = new List<Tech_Recibo_Pago__c>();

        for (Recibo_de_Cobro__c r : scope) {
            // Dedup por Numero__c
            if (r.Numero__c != null && numerosYaMigrados.contains(r.Numero__c)) {
                omitidos++;
                continue;
            }

            // Buscar Tech_Plan correspondiente
            String planKey = String.valueOf(r.Plan_de_Pagos__r?.Seguro__c)
                             + '|' + String.valueOf(r.Plan_de_Pagos__r?.Fecha_inicio__c);
            Id techPlanId = planKeyToTechId.get(planKey);
            if (techPlanId == null) {
                sinPlan++;
                continue;
            }

            Tech_Recibo_Pago__c tr = new Tech_Recibo_Pago__c();
            tr.Plan_de_Pagos__c    = techPlanId;
            tr.Estado__c           = ESTADO_MAP.containsKey(r.Estado__c)
                                         ? ESTADO_MAP.get(r.Estado__c)
                                         : 'Programado';
            tr.Numero__c           = r.Numero__c;
            tr.Fecha_programada__c = r.Fecha_programada__c;
            tr.Fecha_pago__c       = r.Fecha_pago__c;
            tr.Monto_programado__c = r.Monto_programado__c;
            tr.Monto_cobrado__c    = r.Monto_pagado__c;
            tr.Metodo_pago__c      = r.Metodo_pago__c;
            tr.Motivo_No_Pago__c   = r.Motivo_No_Pago__c;
            tr.Referencia_pago__c  = r.Referencia_pago__c;
            tr.Intentos_Contacto__c = r.Intentos_Contacto__c;
            tr.Poliza_numero__c    = r.Poliza_numero__c;

            if (r.Numero__c != null) numerosYaMigrados.add(r.Numero__c);
            toInsert.add(tr);
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
        System.debug('TechMigrarRecibosBatch COMPLETADO — migrados: ' + migrados
            + ' | omitidos: ' + omitidos + ' | sin plan: ' + sinPlan + ' | errores: ' + errores);
    }
}