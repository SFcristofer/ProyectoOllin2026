public with sharing class TechConvenioSelector {
    public static List<Tech_Convenio_Modificatorio__c> getRecentConvenios() {
        return [
            SELECT Id, Name,
                   Numero_Convenio__c,
                   Contract__c, Contract__r.ContractNumber,
                   Tipo_de_Modificacion__c,
                   Fecha_del_Convenio__c,
                   Nuevo_Valor_Contrato__c,
                   Diferencia_Monto__c,
                   Nueva_Fecha_Fin__c,
                   Nueva_Fecha_Fin_Contrato__c,
                   Motivo__c,
                   Descripcion__c,
                   CreatedDate
            FROM Tech_Convenio_Modificatorio__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}