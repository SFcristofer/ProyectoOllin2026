trigger TechFianzaTrigger on Tech_Fianza__c (before insert) {
    TechFianzaTriggerHandler.heredarDatosDeContrato(Trigger.new);
}