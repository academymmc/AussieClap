/*********************************************************
 * Apex Class Name    : GoogleDriveService
 * @description       : Service class for generating and storing PDFs in Google Drive.
 **********************************************************/

public with sharing class GoogleDriveService {
    
    /**
     * @description : Generates and stores a PDF for the specified Invoice record in Google Drive.
     * @param : invoiceId The ID of the Invoice record for which PDF needs to be generated.
     * @return : The response body from the HTTP callout to Google Drive.
     */
    @AuraEnabled
    public static String generateAndStorePDF(Id invoiceId) {
        Invoice__c invoice = fetchInvoice(invoiceId);
        Blob pdfBlob = generatePDF(invoiceId);
        String requestBody = prepareRequestBody(invoice, pdfBlob);
        HttpResponse response = sendHttpRequest(requestBody);
        String fileUrl = parseResponseAndGetFileUrl(response);
        updateInvoiceWithFileUrl(invoice, fileUrl);
        return response.getBody();
    }

    /**
     * Fetches the Invoice record details based on the provided Invoice ID.
     * @param : invoiceId The ID of the Invoice record to fetch.
     * @return : The Invoice__c record corresponding to the given ID.
     */
    private static Invoice__c fetchInvoice(Id invoiceId) {
        return [SELECT Id, Name, PDF_Link__c, Status__c, Posted_Date__c 
                FROM Invoice__c 
                WHERE Id = :invoiceId 
                LIMIT 1];
    }

    /**
     * Generates a PDF Blob for the specified Invoice ID using a Visualforce page.
     * @param invoiceId The ID of the Invoice record for which PDF needs to be generated.
     * @return Blob containing the generated PDF content.
     * @throws AuraHandledException if there is an error generating the PDF.
     */
    private static Blob generatePDF(Id invoiceId) {
        PageReference pdfPage = Page.InvoicePdf;
        pdfPage.getParameters().put('id', invoiceId);
        if (Test.isRunningTest()) {
            return Blob.valueOf('Unit Test PDF Content');
        } else {
            try {
                return pdfPage.getContentAsPDF();
            } catch (VisualforceException e) {
                throw new AuraHandledException('Error generating PDF: ' + e.getMessage());
            }
        }
    }

    /**
     * Prepares the request body for uploading the PDF to Google Drive.
     * @param : invoice The Invoice__c record for which PDF is being uploaded.
     * @param : pdfBlob Blob containing the PDF content.
     * @return : String representing the prepared request body.
     */
    private static String prepareRequestBody(Invoice__c invoice, Blob pdfBlob) {
        String folderId = System.label.Drive_Folder_Id;
        String fileName = invoice.Name + '.pdf'; 
        Map<String, Object> metadataMap = new Map<String, Object>();
        metadataMap.put('name', fileName);
        metadataMap.put('parents', new List<String>{folderId});
        String metadata = JSON.serialize(metadataMap);

        String boundary = '-------314159265358979323846';
        String delimiter = '\r\n--' + boundary + '\r\n';
        String closeDelim = '\r\n--' + boundary + '--';
        String contentType = 'application/pdf';

        return delimiter +
            'Content-Type: application/json\r\n\r\n' +
            metadata + '\r\n' +
            delimiter +
            'Content-Type: ' + contentType + '\r\n' +
            'Content-Transfer-Encoding: base64\r\n\r\n' +
            EncodingUtil.base64Encode(pdfBlob) +
            closeDelim;
    }

    /**
     * Sends the HTTP request to Google Drive API to upload the PDF.
     * @param : requestBody The prepared request body containing PDF metadata and content.
     * @return : HttpResponse object containing the response from Google Drive API.
     */
    private static HttpResponse sendHttpRequest(String requestBody) {
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer');
        req.setHeader('Content-Type', 'multipart/related; boundary="-------314159265358979323846"');
        req.setMethod('POST');
        req.setEndpoint('callout:GoogleDrive');
        req.setHeader('Content-Length', String.valueOf(requestBody.length()));
        req.setBody(requestBody);

        Http http = new Http();
        return http.send(req);
    }

    /**
     * Parses the response from Google Drive API and retrieves the file URL.
     * @param : response HttpResponse object containing the response from Google Drive API.
     * @return : String representing the URL of the uploaded file in Google Drive.
     */
    private static String parseResponseAndGetFileUrl(HttpResponse response) {
        System.debug(response.getBody());
        GoogleDriveResponse driveResponse = (GoogleDriveResponse) JSON.deserialize(response.getBody(), GoogleDriveResponse.class);
        return 'https://drive.google.com/file/d/' + driveResponse.id + '/view?usp=drive_link';
    }

    /**
     * Updates the Invoice record with the URL of the stored PDF file.
     * @param : invoice The Invoice__c record to update.
     * @param : fileUrl The URL of the stored PDF file in Google Drive.
     */
    private static void updateInvoiceWithFileUrl(Invoice__c invoice, String fileUrl) {
        invoice.PDF_Link__c = fileUrl;
        invoice.Status__c = 'Posted';
        invoice.Posted_Date__c = System.today();
        update invoice;
    }

    /**
     * Inner class representing the response structure from Google Drive API.
     */
    private class GoogleDriveResponse {
        public String id {get; set;}
    }
}