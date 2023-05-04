@isTest
public class ChatMessageController_Test {

    public class OpenAIMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"choices": [{"message": {"content": "Test response"}}]}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testGetMessages() {
        // Prepare test data
        List<Open_AI_Message__c> messages = new List<Open_AI_Message__c>();
        for (Integer i = 0; i < 5; i++) {
            messages.add(new Open_AI_Message__c(
                Message__c = 'Test message ' + i,
                Sender_Type__c = (Math.mod(i, 2) == 0) ? 'Inbound' : 'Outbound'
            ));
        }
        insert messages;

        // Test getMessages method
        Test.startTest();
        List<Open_AI_Message__c> result = ChatMessageController.getMessages();
        Test.stopTest();

        // Verify the results
        System.assertEquals(5, result.size(), 'The number of messages returned should be 5');
    }

    @isTest
    static void testSendPrompt() {
        // Set the mock callout
        Test.setMock(HttpCalloutMock.class, new OpenAIMock());
        Contact contact = new Contact(FirstName = 'Test Lead 1', LastName = 'Test Lead 2');
        insert contact;

        // Test sendPrompt method
        Test.startTest();
        String response = ChatMessageController.sendPrompt('Test prompt', contact.Id);
        Test.stopTest();

        // Verify the results
        System.assertEquals('Test response', response, 'The response should be "Test response"');
    }
}
