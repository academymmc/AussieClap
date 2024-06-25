@isTest
public class InvoiceControllerTest {
    
    // Method to create test data
    @isTest
    private static void createTestData() {
        Account acc = new Account(
            Name = 'My Test Account',
            BillingStreet = '123 Test St',
            BillingCity = 'Test City',
            BillingState = 'Test State',
            BillingPostalCode = '12345',
            BillingCountry = 'Test Country',
            ShippingStreet = '123 Test St',
            ShippingCity = 'Test City',
            ShippingState = 'Test State',
            ShippingPostalCode = '12345',
            ShippingCountry = 'Test Country',
            Phone = '123-456-7890'
        );
        insert acc;

        Contact contact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'test@123test.com',
            AccountId = acc.Id
        );
        insert contact;

        Invoice__c inv = new Invoice__c(
            Status__c = 'UnPosted',
            Account__c = acc.Id,
            Contact__c = contact.Id,
            Posted_Date__c = Date.today()
        );
        insert inv;

        List<Invoice_Line_Item__c> lineItems = new List<Invoice_Line_Item__c>();
        for (Integer i = 0; i < 3; i++) {
            Invoice_Line_Item__c item = new Invoice_Line_Item__c(
                Invoice__c = inv.Id,
                Quantity__c = 1,
                Net_Amount__c = 100,
                Line_Item_Total__c = 120,
                Tax_Amount__c = 20,
                Item__c = 'Test Item ' + i,
                Unit_Price__c = 100,
                Discount__c = 0
            );
            lineItems.add(item);
        }
        insert lineItems;
    }

    // Test method for generateAndStorePDF
    @isTest
    public static void testGenerateAndStorePDF() {
        createTestData();

        // Fetch the Invoice Id
        Invoice__c invoice = [SELECT Id FROM Invoice__c LIMIT 1];
        Id invoiceId = invoice.Id;

        Test.startTest();

        // Mock the HTTP response from Google Drive
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"kind":"drive#file", "id": "1xT5xx6IQZJ_jsazA9noy_Y9SE979Zjql", "name": "INV-0001.pdf", "mimeType": "application/pdf"}');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new GoogleDriveMock(mockResponse));

        // Call the method
        String response = GoogleDriveService.generateAndStorePDF(invoiceId);

        Test.stopTest();

        // Verify the Invoice Pdf_URL__c field is updated
        Invoice__c updatedInvoice = [SELECT Pdf_Link__c FROM Invoice__c WHERE Id = :invoiceId];
        System.assertEquals('https://drive.google.com/file/d/1xT5xx6IQZJ_jsazA9noy_Y9SE979Zjql/view?usp=drive_link', updatedInvoice.Pdf_Link__c);
        System.assert(response.contains('"id": "1xT5xx6IQZJ_jsazA9noy_Y9SE979Zjql"'), 'Response body does not contain expected id');
    }
}