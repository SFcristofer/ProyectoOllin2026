public with sharing class TechPlanPagoSelector {
    public static List<Tech_Plan_de_Pago__c> getRecentPlanes() {
        return [
            SELECT Id, Name, Estado__c, Monto_total__c, Num_recibos__c,
                   Periodo_Pago__c, Fecha_inicio__c, Metodo_Pago__c,
                   Domiciliacion_activa__c, CreatedDate,
                   Fianzas__c, Fianzas__r.Name,
                   Seguro__c, Seguro__r.Name
            FROM Tech_Plan_de_Pago__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}