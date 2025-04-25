public class ContactTriggerHandler {
    public void handleBeforeInsert(List<Contact> newContacts) {
        for (Contact con : newContacts) {
            if (String.isBlank(con.DummyJSON_Id__c)) {
                Integer randomInt = Math.round(Math.random() * 100);
                con.DummyJSON_Id__c = String.valueOf(randomInt);
            }
        }
    }

    public void handleAfterInsert(List<Contact> newContacts) {
        for (Contact con : newContacts) {
            if (!String.isBlank(con.DummyJSON_Id__c)) {
                try {
                    Integer dummyId = Integer.valueOf(con.DummyJSON_Id__c);
                    if (dummyId <= 100) {
                        DummyJSONCallout.getDummyJSONUserFromId(con.Id);
                        
                    }
                } catch (Exception e) {
                    System.debug('Error parsing DummyJSON_Id__c in after insert: ' + e.getMessage());
                }
            }
        }
    }


    public void handleAfterUpdate(List<Contact> newContacts, Map<Id, Contact> oldMap) {
        for (Contact con : newContacts) {
            Contact oldCon = oldMap.get(con.Id);
            if (!String.isBlank(con.DummyJSON_Id__c)) {
                try {
                    Integer dummyId = Integer.valueOf(con.DummyJSON_Id__c);
                    if (dummyId > 100 && con.DummyJSON_Id__c != oldCon.DummyJSON_Id__c) {
                        DummyJSONCallout.postCreateDummyJSONUser(con.Id);
                    }
                } catch (Exception e) {
                    System.debug('Error parsing DummyJSON_Id__c in after update: ' + e.getMessage());
                }
            }
        }
    }
     //@future(callout=true) 
    public static void callGetDummyJSONUserFromId(List<Contact> contacts) { 
        for (Contact con : contacts) {
            if(con.DummyJSON_Id__c == null){
                con.DummyJSON_Id__c = '1';
            }
            DummyJSONCallout.getDummyJSONUserFromId('1');
            
        }
    } 

    @future(callout=true) 
    public static void callPostCreateDummyJSONUser(Set<String> contactIds) { 
        for (String contactId : contactIds) { 
            DummyJSONCallout.postCreateDummyJSONUser('1'); 
        } 
    } 
}