public without sharing class QuoteController {
	
    /**
     * @description : This method fetches values from the Quote object and assigns them to variables.
     * @param : quoteId The ID of the Quote record to fetch.
     * @returns : quoteDetails An instance of QuoteData containing fetched quote details.
     */
    @AuraEnabled(cacheable=true)
    public static QuoteData getQuoteData(Id quoteId) {
        try {
            System.debug('Fetching quote data for Id: ' + quoteId);
            Quote quoteRecord = [
                SELECT Id, Name, Status, Tax, ShippingHandling, Discount, Subtotal, GrandTotal, TotalPrice, 
                    (SELECT Id, Product_Name__c, Discount, TotalPrice, UnitPrice, Subtotal FROM QuoteLineItems) 
                FROM Quote  
                WHERE Id = :quoteId 
                LIMIT 1
            ];

            if (quoteRecord != null) {
                QuoteData quoteDetails = new QuoteData();
                quoteDetails.name = quoteRecord.Name;
                quoteDetails.status = quoteRecord.Status;
                quoteDetails.tax = quoteRecord.Tax;
                quoteDetails.total = quoteRecord.TotalPrice;
                quoteDetails.discount = quoteRecord.Discount;
                quoteDetails.subtotal = quoteRecord.Subtotal;
                quoteDetails.grandTotal = quoteRecord.GrandTotal;
                quoteDetails.shippingHandlingCharges = quoteRecord.ShippingHandling;
                quoteDetails.quoteLineItems = quoteRecord.QuoteLineItems;

                System.debug('Quote data fetched: ' + quoteDetails);
                return quoteDetails;
            } else {
                throw new AuraHandledException('No quote record found with the given ID: ' + quoteId);
            }
        } catch (Exception e) {
            System.debug('Error fetching quote data: ' + e.getMessage());
            throw new AuraHandledException('Error fetching quote data: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateQuoteStatus(Id quoteId, String newStatus) {
        try {
            System.debug('Updating quote status for Id: ' + quoteId + ' to ' + newStatus);
            Quote quoteToUpdate = [SELECT Id, Status FROM Quote WHERE Id = :quoteId LIMIT 1];
            quoteToUpdate.Status = newStatus;
            update quoteToUpdate;
            System.debug('Quote status updated to: ' + newStatus);
        } catch (Exception e) {
            System.debug('Error updating quote status: ' + e.getMessage());
            throw new AuraHandledException('Error updating quote status: ' + e.getMessage());
        }
    }

    public class QuoteData {
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String status { get; set; }
        @AuraEnabled
        public Decimal tax { get; set; }
        @AuraEnabled
        public Decimal total { get; set; }
        @AuraEnabled
        public Decimal discount { get; set; }
        @AuraEnabled
        public Decimal subtotal { get; set; }
        @AuraEnabled
        public Decimal grandTotal { get; set; }
        @AuraEnabled
        public Decimal shippingHandlingCharges { get; set; }
        @AuraEnabled
        public List<QuoteLineItem> quoteLineItems { get; set; }
    }
}