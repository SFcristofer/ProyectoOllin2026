public with sharing class TechReciboCobroSelector {
    public static List<Tech_Recibo_Pago__c> getRecentRecibos() {
        return [
            SELECT Id, Name, Estado__c, Monto_programado__c, Monto_cobrado__c,
                   Fecha_programada__c, Fecha_pago__c, Numero__c, Metodo_pago__c,
                   Motivo_No_Pago__c, Referencia_pago__c, Saldo__c,
                   Plan_de_Pagos__c, Plan_de_Pagos__r.Name, CreatedDate
            FROM Tech_Recibo_Pago__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}