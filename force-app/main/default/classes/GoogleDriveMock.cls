@isTest
global class GoogleDriveMock implements HttpCalloutMock {
    private HttpResponse mockResponse;

    // Constructor
    public GoogleDriveMock(HttpResponse mockResponse) {
        this.mockResponse = mockResponse;
    }

    // Respond to HTTP requests
    public HttpResponse respond(HttpRequest req) {
        return mockResponse;
    }
}