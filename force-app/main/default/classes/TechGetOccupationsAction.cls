public with sharing class TechGetOccupationsAction {
    
    public class Request {
        @InvocableVariable(
            label='Filtro de Catálogo' 
            description='Parámetro opcional para filtrar los resultados del catálogo. Puede ser el nombre de una aseguradora específica o un término de búsqueda para reducir la lista.'
        )
        public String filter;
    }

    public class Response {
        @InvocableVariable(
            label='Lista de Opciones de Ocupación' 
            description='Colección de objetos que contienen etiquetas legibles (ej. Empleado) y sus valores técnicos correspondientes (ej. 9BJG) obtenidos dinámicamente de la API.'
        ) 
        public List<TechCatalogWrapper> options;
    }

    @InvocableMethod(
        label='[Ollin] Obtener Catálogo Dinámico API' 
        description='Consulta la API de OLLIN para traer el catálogo actualizado de ocupaciones o estados civiles. Úsala para presentar opciones válidas al usuario y evitar errores de captura.'
        category='Ollin Seguros'
    )
    public static List<Response> getOccupations(List<Request> requests) {
        List<Response> results = new List<Response>();
        for (Request req : requests) {
            Response res = new Response();
            res.options = TechInsuranceApiService.fetchCatalogFromApi('occupations', req.filter);
            results.add(res);
        }
        return results;
    }
}