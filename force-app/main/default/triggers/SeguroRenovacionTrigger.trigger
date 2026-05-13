/**
 * SeguroRenovacionTrigger — al entrar Estatus__c = 'Por renovar', delega
 * en SeguroRenovacionHandler para crear Oportunidad de renovación y demás
 * acciones automáticas.
 *
 * @author Ollin Protección — 2026-04-19 (v6)
 */
trigger SeguroRenovacionTrigger on Seguro__c (after update) {
    SeguroRenovacionHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
}