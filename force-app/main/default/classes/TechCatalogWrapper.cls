public class TechCatalogWrapper {
    @AuraEnabled 
    @InvocableVariable(label='Etiqueta' description='Nombre legible para el usuario (ej. Empleado)')
    public String label;

    @AuraEnabled 
    @InvocableVariable(label='Valor Técnico' description='Código requerido por la API (ej. 9BJG)')
    public String value;

    public TechCatalogWrapper(String label, String value) {
        this.label = label;
        this.value = value;
    }
}