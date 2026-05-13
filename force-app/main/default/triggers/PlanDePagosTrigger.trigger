/**
 * Trigger: PlanDePagosTrigger
 * Object: Plan_de_Pagos__c
 *
 * Delega la logica al handler PlanDePagosTriggerHandler.
 * Un solo trigger por objeto (best practice).
 */
trigger PlanDePagosTrigger on Plan_de_Pagos__c (
    before insert, before update, before delete,
    after insert, after update, after delete, after undelete
) {
    PlanDePagosTriggerHandler handler = new PlanDePagosTriggerHandler();

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
        }
    }
}