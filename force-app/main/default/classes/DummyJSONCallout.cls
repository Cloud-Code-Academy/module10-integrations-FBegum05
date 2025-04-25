/*
 * DummyJSONCallout Class Description:
 * 
 * This class, DummyJSONCallout, facilitates HTTP callouts to an external system (presumably 'DummyJsonUser' in this context) 
 * to either fetch or send user information based on a given identifier. The class supports both GET (to fetch data) 
 * and POST (to send data) operations.
 * 
 * Overview of HTTP Callouts:
 * 
 * HTTP callouts are a way for Salesforce to communicate with external systems using HTTP protocols. Through HTTP callouts, 
 * you can invoke external web services, collect data from them, or send data for further processing. Apex provides 
 * classes that enable you to both send and receive HTTP data. The primary classes for this are `HttpRequest`, which 
 * represents the request you're sending, and `HttpResponse`, which represents the response you receive.
 * 
 * Best Practices:
 * 1. Handle Exceptions: Always handle exceptions that might be thrown, to ensure your code doesn't break unexpectedly.
 * 2. Named Credentials: Use Named Credentials to store endpoint URLs and authentication details securely.
 * 3. Test Callouts: Use mock classes and interfaces to test HTTP callouts without making actual callouts.
 * 
 * For more detailed information on HTTP callouts in Apex, refer to the official Salesforce documentation: 
 * https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_restful_http_httprequest.htm
 */

public with sharing class DummyJSONCallout {

	/* 
	 * Question 1
     * Fetches user information from an external system https://dummyjson.com/user/{id} ('DummyJsonUser') based on the provided dummy user ID. 
     * If the callout is successful and returns an HTTP status of 200, the method will update a contact based on the DummyJSON_Id__c with the data returned from the external system.
	 * Use the createContactFromJson method to parse the JSON response and create a Salesforce Contact object.
     * Documentation: https://dummyjson.com/docs/users
	 * This callout method should work in triggers
	 * 
     * @param dummyUserId The ID of the user in the external system to fetch data for.
     */
 
@future(callout=true)
public static void getDummyJSONUserFromId(String userId) {
    Http http = new Http();
    HttpRequest req = new HttpRequest();
    req.setEndpoint('https://dummyjson.com/users/' + userId);
    req.setMethod('GET');
    HttpResponse res = http.send(req);

    if (res.getStatusCode() == 200) {
        Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        
        // Find existing Contact by DummyJSON_Id__c
        List<Contact> contactsToUpdate = [SELECT Id FROM Contact WHERE DummyJSON_Id__c = :userId LIMIT 1];
        if (!contactsToUpdate.isEmpty()) {
            Contact existing = contactsToUpdate[0];
            Contact dataFromAPI = createContactFromJson(jsonData);
            
            // Now update the existing contact with values from the API
            existing.Email = dataFromAPI.Email;
            existing.Phone = dataFromAPI.Phone;
            existing.Birthdate = dataFromAPI.Birthdate;
            existing.MailingStreet = dataFromAPI.MailingStreet;
            existing.MailingCity = dataFromAPI.MailingCity;
            existing.MailingPostalCode = dataFromAPI.MailingPostalCode;
            existing.MailingState = dataFromAPI.MailingState;
            existing.MailingCountry = dataFromAPI.MailingCountry;

            update existing;
        }
    }
}


	/* 
	 * Question 2
     * Transforms a JSON response from the external system https://dummyjson.com/users into a Salesforce Contact object.
     * The method parses the JSON string to extract user details and map them to a Salesforce Contact object.
     * The contact fields populated from the JSON include Email, Phone, Birthdate, and various address-related fields.
     * The method is primarily designed to work in conjunction with callouts that fetch user details from the external system. 
	 * 
	 * Fields from JSON used to populate Salesforce Contact
	 * Fields: Email, Phone, Birthdate, MailingStreet, MailingCity, MailingPostalCode, MailingState, MailingCountry
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String jsonResponse The JSON string from the external system that contains user details.
     * @return Contact The Salesforce Contact object populated with details from the JSON string.
     */
	 
    @TestVisible
    public static Contact createContactFromJson(Map<String, Object> jsonData) {
        Contact contact = new Contact();

        contact.FirstName = (String) jsonData.get('firstName');
        contact.LastName = (String) jsonData.get('lastName');
        contact.Email = (String) jsonData.get('email');
        contact.Phone = (String) jsonData.get('phone');
        contact.DummyJSON_Id__c = String.valueOf(jsonData.get('id'));
System.debug('Deserialized JSON: ' + jsonData);

        if (jsonData.containsKey('birthDate')) {
            contact.Birthdate = Date.valueOf((String) jsonData.get('birthDate'));
        }

        if (jsonData.containsKey('address')) {
            Map<String, Object> address = (Map<String, Object>) jsonData.get('address');
            contact.MailingStreet = (String) address.get('address');
            contact.MailingCity = (String) address.get('city');
            contact.MailingPostalCode = (String) address.get('postalCode');
            contact.MailingState = (String) address.get('state');
            contact.MailingCountry = (String) address.get('country');
        }

        return contact;
    }
	/* 
	 * Question 3
     * Sends Contact information to an external system https://dummyjson.com/users/add ('DummyJsonUser') to create or update a user based on the provided Salesforce Contact ID.
     * The method prepares a JSON payload with the contact's information and sends it to the 'DummyJsonUser' add endpoint.
     * If the callout is successful (HTTP status code between 200 and 299), the method updates the contact's 'DummyJSON_Last_Updated__c' field in Salesforce to the current time.
	 * Salesforce Contact should be used to generate the JSON payload
	 * Fields: Id, FirstName, LastName, Email, Phone
	 * This callout method should work in triggers
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param contactId The Salesforce Contact ID used to generate the JSON payload for the external system.
     */
	
	 
public static void postCreateDummyJSONUser(String contactId) {
        Contact contact = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE Id = :contactId LIMIT 1];
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://dummyjson.com/users/add'); // Replace with Named Credential if needed
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(generateDummyJsonUserPayload(contactId));

        try {
            HttpResponse response = http.send(req);
            if (response.getStatusCode() >= 200 && response.getStatusCode() <= 299) {
                contact.DummyJSON_Last_Updated__c = DateTime.now();
                update contact;
            } else {
                System.debug('POST failed: ' + response.getStatus() + ' ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Error during POST callout: ' + e.getMessage());
        }
    }


	/*
	 * Question 4
     * Generates a JSON payload based on a Salesforce Contact's fields to be sent to an external system https://dummyjson.com/users/add for user creation or update.
     * The method queries a contact from Salesforce based on the provided contactId and maps its fields into a JSON payload.
     * The fields from Salesforce Contact that are transformed into the JSON payload include Id, FirstName, LastName, Email, and Phone.
     * The generated JSON payload can be sent to the external system for various operations like creating or updating a user.
	 * 
	 * Fields from Salesforce Contact used to generate JSON payload:
	 * Fields: Id => salesforceId, FirstName => firstName, LastName => lastName, Email => email, Phone => phone
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String contactId The Salesforce Contact ID used to fetch the contact's fields and generate the JSON payload.
     * @return String The JSON string payload that represents the Contact's details.
     */
	 
public static String generateDummyJsonUserPayload(Id contactId) {
    Contact cont = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE Id = :contactId LIMIT 1];
    
    Map<String, Object> payload = new Map<String, Object>();
    payload.put('salesforceId', cont.Id);
    payload.put('firstName', cont.FirstName);
    payload.put('lastName', cont.LastName);
    payload.put('email', cont.Email);
    payload.put('phone', cont.Phone);

    return JSON.serialize(payload);
}

}