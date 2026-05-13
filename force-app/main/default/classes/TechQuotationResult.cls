public class TechQuotationResult {
    @AuraEnabled @InvocableVariable(label='Aseguradora') public String insurerName;
    @AuraEnabled @InvocableVariable(label='Precio') public Decimal price;
    @AuraEnabled @InvocableVariable(label='Estatus') public String status; // 'Success' o 'Timeout'
    @AuraEnabled @InvocableVariable(label='Mensaje') public String message;

    public TechQuotationResult(String insurer, Decimal price, String status, String msg) {
        this.insurerName = insurer;
        this.price = price;
        this.status = status;
        this.message = msg;
    }
}