trigger PagoParcialTrigger on Pago_Parcial__c (before update, after insert, after update, after delete, after undelete) {

    if (Trigger.isBefore && Trigger.isUpdate) {
        PagoParcialTriggerHandler.actualizarEstado(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isAfter) {
        List<Pago_Parcial__c> parciales = Trigger.isDelete ? Trigger.old : Trigger.new;
        PagoParcialTriggerHandler.recalcularSaldo(parciales);
    }
}