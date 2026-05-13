trigger TechConvenioTrigger on Tech_Convenio_Modificatorio__c (after insert, after update) {
    TechConvenioTriggerHandler.actualizarContrato(Trigger.new, Trigger.oldMap);
}