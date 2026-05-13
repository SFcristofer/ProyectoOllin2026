/**
 * Trigger: ReciboDeCobroTrigger
 * Object: Recibo_de_Cobro__c
 *
 * Delega la logica al handler ReciboDeCobroTriggerHandler.
 */
trigger ReciboDeCobroTrigger on Recibo_de_Cobro__c (
    before insert, before update, before delete,
    after insert, after update, after delete, after undelete
) {
    ReciboDeCobroTriggerHandler handler = new ReciboDeCobroTriggerHandler();

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.onBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    } else { // after
        if (Trigger.isInsert) {
            handler.onAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            handler.onAfterDelete(Trigger.old);
        } else if (Trigger.isUndelete) {
            handler.onAfterUndelete(Trigger.new);
        }
    }
}