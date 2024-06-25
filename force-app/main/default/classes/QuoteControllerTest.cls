@isTest
private class QuoteControllerTest {
    
    @isTest
    static void testGetQuoteDataAndStatusUpdate() {
        // Create test data
        Account acc = new Account(Name = 'Test');
        insert acc;
        
        Product2 prod = new Product2(Name = 'Test', ProductCode = 'ASC101', isActive = true, Family = 'Carpenter');
        insert prod;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 50.0, IsActive = true);
        insert standardPrice;
        
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Opportunity Processing', CloseDate = System.Today() + 2, AccountId = acc.Id, Date_Of_Service__c = System.Today() + 2, Pricebook2Id = pricebookId);
        insert opp;
        
        OpportunityLineItem oli = new OpportunityLineItem(ServiceDate = opp.Date_Of_Service__c, OpportunityId = opp.Id, Product2Id = prod.Id, Quantity = 1, UnitPrice = standardPrice.UnitPrice);
        Insert oli;
        
        // Setup test data
        Quote quote = new Quote(Name = 'Test Quote', Status = 'In Review', Tax = 10.0, ShippingHandling = 5.0, OpportunityId = opp.Id, Pricebook2Id = pricebookId);
        insert quote;
        
        QuoteLineItem qli = new QuoteLineItem(QuoteId = quote.Id, Discount = 1.0, UnitPrice = 50.0, Product2Id = prod.Id, Quantity = 1, PricebookEntryId = standardPrice.Id);
        insert qli;

        Test.startTest();
        // Call the method under test
        QuoteController.QuoteData quoteData = QuoteController.getQuoteData(quote.Id);
        QuoteController.updateQuoteStatus(quote.Id, 'Accepted');
        Test.stopTest();

        // Verify the returned QuoteData
        System.assertNotEquals(null, quoteData, 'QuoteData should not be null');
        System.assertEquals(quote.Name, quoteData.name, 'Quote name should match');
        System.assertEquals(quote.Status, quoteData.status, 'Quote status should match');
        System.assertEquals(quote.Tax, quoteData.tax, 'Quote tax should match');
        System.assertEquals(quote.ShippingHandling, quoteData.shippingHandlingCharges, 'Quote shipping handling charges should match');
        System.assertEquals(qli.Discount, quoteData.discount, 'Quote discount should match');
        System.assertEquals(1, quoteData.quoteLineItems.size(), 'Quote line items count should match');

        // Verify the status update
        Quote updatedQuote = [SELECT Status FROM Quote WHERE Id = :quote.Id];
        System.assertEquals('Accepted', updatedQuote.Status, 'Quote status should be updated to Accepted');
    }
}