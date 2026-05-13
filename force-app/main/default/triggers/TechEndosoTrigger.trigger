trigger TechEndosoTrigger on Tech_Endoso__c (
    before insert,
    before update,
    after insert,
    after update
) {

    if (Trigger.isBefore) {
        TechEndosoTriggerHandler.beforeSave(Trigger.new);
    }

    if (Trigger.isAfter) {
        TechEndosoTriggerHandler.afterSave(
            Trigger.new,
            Trigger.oldMap,
            Trigger.isInsert
        );
    }
}