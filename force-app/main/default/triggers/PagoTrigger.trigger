trigger PagoTrigger on Pago__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        PagoTriggerHandler.generarPagosParciales(Trigger.new);
    }
}