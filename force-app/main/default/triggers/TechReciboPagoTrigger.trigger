trigger TechReciboPagoTrigger on Tech_Recibo_Pago__c (
    before insert,
    before update,
    after insert,
    after update,
    after delete,
    after undelete
) {

    if (Trigger.isBefore) {
        TechReciboPagoTriggerHandler.beforeSave(
            Trigger.new,
            Trigger.isUpdate ? Trigger.oldMap : null
        );
    }

    if (Trigger.isAfter) {

        if (Trigger.isDelete) {
            TechReciboPagoTriggerHandler.afterChange(
                Trigger.old,
                Trigger.oldMap
            );
        } else {
            TechReciboPagoTriggerHandler.afterChange(
                Trigger.new,
                Trigger.isUpdate ? Trigger.oldMap : null
            );
        }
    }
}