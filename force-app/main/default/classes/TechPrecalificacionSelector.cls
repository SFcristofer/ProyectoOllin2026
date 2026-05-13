public with sharing class TechPrecalificacionSelector {
    public static List<Precalificacion__c> getByContratista(Id contratistaId) {
        return [
            SELECT Id, Name, CreatedDate,
                   Estado__c, Estado_autom_tico__c,
                   Fecha_Estados_Financieros__c,
                   Capital_Contable__c,
                   Capacidad_de_Afianzamiento__c,
                   Capacidad_Afianzamiento_Calc__c,
                   Linea_Afianzamiento_Calc__c,
                   Resultado_Afianzamiento_Calc__c,
                   Score_ICP__c,
                   Importe_Total_Contrato__c,
                   Total_a_Afianzar__c,
                   Ventas_Netas__c,
                   Apalancamiento__c,
                   Liquidez__c,
                   Capital_de_Trabajo__c,
                   Activo_total__c,
                   Pasivo_Total__c,
                   Contratista__c, Contratista__r.Name,
                   Comentarios__c
            FROM Precalificacion__c
            WHERE Contratista__c = :contratistaId
            ORDER BY CreatedDate DESC
        ];
    }

    public static List<Precalificacion__c> getByProspecto(Id prospectoId) {
        return [
            SELECT Id, Name, CreatedDate,
                   Estado__c, Estado_autom_tico__c,
                   Fecha_Estados_Financieros__c,
                   Capital_Contable__c,
                   Capacidad_de_Afianzamiento__c,
                   Capacidad_Afianzamiento_Calc__c,
                   Linea_Afianzamiento_Calc__c,
                   Resultado_Afianzamiento_Calc__c,
                   Score_ICP__c,
                   Importe_Total_Contrato__c,
                   Total_a_Afianzar__c,
                   Ventas_Netas__c,
                   Apalancamiento__c,
                   Liquidez__c,
                   Capital_de_Trabajo__c,
                   Activo_total__c,
                   Pasivo_Total__c,
                   Contratista__c, Contratista__r.Name,
                   Prospecto__c
            FROM Precalificacion__c
            WHERE Prospecto__c = :prospectoId
            ORDER BY CreatedDate DESC
        ];
    }

    public static List<Precalificacion__c> getRecent() {
        return [
            SELECT Id, Name, CreatedDate,
                   Estado__c, Estado_autom_tico__c,
                   Fecha_Estados_Financieros__c,
                   Capital_Contable__c,
                   Capacidad_de_Afianzamiento__c,
                   Capacidad_Afianzamiento_Calc__c,
                   Linea_Afianzamiento_Calc__c,
                   Resultado_Afianzamiento_Calc__c,
                   Score_ICP__c,
                   Importe_Total_Contrato__c,
                   Total_a_Afianzar__c,
                   Ventas_Netas__c,
                   Apalancamiento__c,
                   Liquidez__c,
                   Capital_de_Trabajo__c,
                   Activo_total__c,
                   Pasivo_Total__c,
                   Comentarios__c,
                   Contratista__c, Contratista__r.Name
            FROM Precalificacion__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}