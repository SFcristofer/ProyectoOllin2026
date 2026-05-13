public with sharing class TechAutoQuotationAction {
    
    public class Request {
        @InvocableVariable(
            label='Código Postal' 
            description='El código postal de 5 dígitos de la zona donde circula el vehículo. Esencial para calcular el riesgo por zona geográfica.' 
            required=true
        ) 
        public String zipCode;

        @InvocableVariable(
            label='ID de Versión de Vehículo' 
            description='El identificador único (UUID) de la versión técnica del vehículo obtenida previamente del catálogo. Define el valor comercial del auto.' 
            required=true
        ) 
        public String vehicleVersionId;

        @InvocableVariable(
            label='Género' 
            description='Género del conductor principal. Valores esperados: M (Masculino), F (Femenino) u Otro. Influye en la tarificación estadística.' 
            required=true
        ) 
        public String gender;

        @InvocableVariable(
            label='Fecha de Nacimiento' 
            description='Fecha de nacimiento del conductor en formato AAAA-MM-DD. Se usa para calcular la edad y determinar el rango de riesgo.' 
            required=true
        ) 
        public String birthDate;
    }

    public class Response {
        @InvocableVariable(
            label='Resultados de Cotización' 
            description='Una lista de objetos que contiene el nombre de la aseguradora, el precio calculado, el estatus de la respuesta y detalles de la cobertura.'
        ) 
        public List<TechQuotationResult> results;

        @InvocableVariable(
            label='Mensaje de Estatus' 
            description='Texto descriptivo que indica si la cotización fue exitosa, si hubo timeouts parciales o si ocurrió algún error general en la API.'
        ) 
        public String statusMessage;
    }

    @InvocableMethod(
        label='[Ollin] Generar Cotización Dinámica API' 
        description='Esta acción invoca la API externa de OLLIN para obtener precios de múltiples aseguradoras en tiempo real. Utiliza lógica de resiliencia para devolver resultados incluso si una aseguradora es lenta. Es el paso central del flujo de seguros.'
        category='Ollin Seguros'
    )
    public static List<Response> getQuotation(List<Request> requests) {
        List<Response> output = new List<Response>();
        for (Request req : requests) {
            Response res = new Response();
            res.results = TechInsuranceApiService.getQuotationsFromApi(req.zipCode, req.vehicleVersionId);
            res.statusMessage = 'Proceso de cotización finalizado. Se procesaron los datos para el CP ' + req.zipCode;
            output.add(res);
        }
        return output;
    }
}