/**
 * Dispara automatizaciones del Modulo de Gestion sobre Seguro__c.
 * Delega toda la logica al handler para mantener el trigger liviano.
 */
trigger SeguroAutomationTrigger on Seguro__c (after insert, after update) {
    if (Trigger.isAfter && Trigger.isInsert) {
        SeguroAutomationHandler.handleAfterInsert(Trigger.new);
    } else if (Trigger.isAfter && Trigger.isUpdate) {
        SeguroAutomationHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}