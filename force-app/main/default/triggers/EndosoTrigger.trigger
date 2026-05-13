trigger EndosoTrigger on Endoso__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        EndosoTriggerHandler.onEstadoCambiado(Trigger.new, Trigger.oldMap);
    }
}