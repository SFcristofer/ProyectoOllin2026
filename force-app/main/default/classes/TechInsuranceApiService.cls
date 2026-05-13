public with sharing class TechInsuranceApiService {
    
    /**
     * Motor Genérico de Cotización.
     * CERO HARDCODE: No conoce nombres de aseguradoras. Procesa dinámicamente el JSON de la API.
     */
    public static List<TechQuotationResult> getQuotationsFromApi(String zipCode, String vehicleId) {
        List<TechQuotationResult> results = new List<TechQuotationResult>();
        
        // 1. Configuración de la petición (Genérica)
        HttpRequest req = new HttpRequest();
        // Nota: Se asume que existe una Named Credential 'Ollin_API' configurada en Salesforce
        req.setEndpoint('callout:Ollin_API/v1/quotations'); 
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody('{"zipCode":"' + zipCode + '", "vehicleId":"' + vehicleId + '"}');
        
        // Tiempo de guardia de 25s para evitar el "Read timed out" de 30s del Agente
        req.setTimeout(25000); 

        try {
            Http h = new Http();
            HttpResponse res = h.send(req);
            
            if (res.getStatusCode() == 200) {
                // 2. PARSEO DINÁMICO: Extraemos lo que la API mande (sea HDI, AXA, o cualquiera)
                List<Object> apiData = (List<Object>) JSON.deserializeUntyped(res.getBody());
                
                for (Object obj : apiData) {
                    Map<String, Object> row = (Map<String, Object>) obj;
                    results.add(new TechQuotationResult(
                        (String)row.get('nombre_aseguradora'), // La API proporciona el nombre
                        (Decimal)row.get('precio'),           // La API proporciona el precio
                        'Success',
                        (String)row.get('descripcion_cobertura')
                    ));
                }
            } else {
                results.add(new TechQuotationResult('API_Error', 0, 'Error', 'La API devolvió código: ' + res.getStatusCode()));
            }
        } catch (Exception e) {
            // Si hay Timeout de 25s, entramos aquí y evitamos que el Agente muera con error técnico
            results.add(new TechQuotationResult('Servicio Externo', 0, 'Timeout', 'El servidor de cotizaciones no respondió a tiempo.'));
        }
        
        return results;
    }

    /**
     * Motor Genérico de Catálogos (Ocupaciones, etc.)
     */
    public static List<TechCatalogWrapper> fetchCatalogFromApi(String catalogName, String filter) {
        List<TechCatalogWrapper> options = new List<TechCatalogWrapper>();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Ollin_API/v1/catalogs/' + catalogName + '?filter=' + filter);
        req.setMethod('GET');
        req.setTimeout(15000);

        try {
            Http h = new Http();
            HttpResponse res = h.send(req);
            if (res.getStatusCode() == 200) {
                List<Object> apiData = (List<Object>) JSON.deserializeUntyped(res.getBody());
                for (Object obj : apiData) {
                    Map<String, Object> row = (Map<String, Object>) obj;
                    // Mapeo dinámico de Label y Value según lo que la API entregue
                    options.add(new TechCatalogWrapper((String)row.get('label'), (String)row.get('value')));
                }
            }
        } catch (Exception e) { /* Manejo de error silencioso para el catálogo */ }
        
        return options;
    }
}