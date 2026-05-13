trigger TechContractTrigger on Contract (
    after insert,
    after update
) {

    Set<Id> contratosFirmados = new Set<Id>();

    for (Contract contrato : Trigger.new) {

        Boolean estaFirmado =
            contrato.Status == TechFianzaContratoService.ESTATUS_CONTRATO_FIRMADO;

        if (!estaFirmado) {
            continue;
        }

        Boolean debeProcesarse = false;

        if (Trigger.isInsert) {
            debeProcesarse = true;
        }

        if (Trigger.isUpdate) {

            Contract anterior = Trigger.oldMap.get(contrato.Id);

            debeProcesarse =
                anterior != null &&
                anterior.Status != TechFianzaContratoService.ESTATUS_CONTRATO_FIRMADO;
        }

        if (debeProcesarse) {
            contratosFirmados.add(contrato.Id);
        }
    }

    if (!contratosFirmados.isEmpty()) {
        TechFianzaContratoService.procesarContratosFirmados(contratosFirmados);
    }
}