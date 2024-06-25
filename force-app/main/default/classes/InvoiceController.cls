/*********************************************************
Apex Class Name    : InvoiceController
Test Class Name    : TestInvoiceController
@description       : This is controller class for InvoicePDFGeneration Visualforce Pages
**********************************************************/

public with sharing class InvoiceController {
    public Invoice__c invoice { get; private set; } 
    public List<Invoice_Line_Item__c> lineItems { get; private set; } 
    public String recordId { get; set; }
    
    public Decimal totalTaxAmount { get; private set; }
    public Decimal totalNetAmount { get; private set; }
    
    /**
     * Constructor to initialize the controller with the standard controller.
     * Fetches and populates invoice details and line items based on the provided invoice ID.
     * Calculates total tax amount and total net amount for the invoice.
     * @param stdController The standard controller instance for Invoice__c object.
     */
    public InvoiceController(ApexPages.StandardController stdController) {
        Id invoiceId = stdController.getId();
        if(invoiceId != null ){
            List<Invoice__c> invoices = [SELECT Id, Name, Status__c, Account__r.BillingStreet, Account__r.BillingCity, Account__r.BillingState, Account__r.BillingPostalCode, 
                                         Account__r.BillingCountry, Account__r.ShippingStreet, Account__r.ShippingCity, Account__r.ShippingState, 
                                         Account__r.ShippingPostalCode, Account__r.ShippingCountry, Account__r.Phone, Posted_Date__c,Contact__r.Name, Invoice_Created_Date__c,
                                         (SELECT Id, Quantity__c, Net_Amount__c, Line_Item_Total__c, Tax_Amount__c, Item__c, Unit_Price__c, Discount__c FROM Invoice_Line_Items__r) 
                                         FROM Invoice__c WHERE Id = :invoiceId  LIMIT 1];
            if(!invoices.isEmpty()){
                invoice = invoices[0];
                lineItems = invoice.Invoice_Line_Items__r;
                
                // Calculate total tax amount and total net amount
                totalTaxAmount = 0;
                totalNetAmount = 0;
                for(Invoice_Line_Item__c item : lineItems) {
                    if(item.Unit_Price__c == null) {
                        item.Unit_Price__c = 0;  
                    }
                    if(item.Discount__c == null){
                        item.Discount__c = 0;  
                    }
                    totalNetAmount += item.Net_Amount__c;
                }
            }
        }
    }
}