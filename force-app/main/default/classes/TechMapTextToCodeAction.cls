public with sharing class TechMapTextToCodeAction {
    
    public class Request {
        @InvocableVariable(
            label='Texto del Usuario' 
            description='El nombre de la ocupación o valor seleccionado por el usuario en lenguaje natural (ej. "Soy Empleado" o "Estudiante").' 
            required=true
        ) 
        public String userInput;

        @InvocableVariable(
            label='Contexto/Filtro' 
            description='Contexto adicional para el mapeo, como el nombre de la aseguradora, para asegurar que el código devuelto sea el correcto para ese proveedor.'
        ) 
        public String filter;
    }

    public class Response {
        @InvocableVariable(
            label='Código Técnico Resultante' 
            description='El código alfanumérico técnico (ej. 9BJK) que corresponde a la selección del usuario y que es requerido por la API de emisión.'
        ) 
        public String technicalCode;
    }

    @InvocableMethod(
        label='[Ollin] Mapear Texto a Código API' 
        description='Transforma la entrada de texto del usuario en un código técnico válido consultando el catálogo dinámico de la API. Esencial para limpiar los datos antes de la emisión final.'
        category='Ollin Seguros'
    )
    public static List<Response> mapTextToCode(List<Request> requests) {
        List<Response> results = new List<Response>();
        for (Request req : requests) {
            Response res = new Response();
            List<TechCatalogWrapper> catalog = TechInsuranceApiService.fetchCatalogFromApi('occupations', req.filter);
            for (TechCatalogWrapper item : catalog) {
                if (item.label.equalsIgnoreCase(req.userInput)) {
                    res.technicalCode = item.value;
                    break;
                }
            }
            results.add(res);
        }
        return results;
    }
}