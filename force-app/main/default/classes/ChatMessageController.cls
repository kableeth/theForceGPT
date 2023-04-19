public with sharing class ChatMessageController {
    @AuraEnabled(cacheable=true)
    public static List<Open_AI_Message__c> getMessages() {
        return [SELECT Id, OwnerId, Owner.Name, Message__c, Sender_Type__c, CreatedDate FROM Open_AI_Message__c ORDER BY CreatedDate DESC LIMIT 10];
    }

     @AuraEnabled(cacheable=true)
    public static String sendPrompt(String prompt, String recordId) {
        // Create a new Open_AI_Message__c record for the prompt
        Open_AI_Message__c newMessage = new Open_AI_Message__c();
        newMessage.Message__c = prompt;
        newMessage.Sender_Type__c = 'Outbound'; // Change this to 'Inbound' if the user is sending the prompt

        // Call the OpenAI Apex class with the prompt
        String context = 'you are a helpful assistant'; // Set the context for the conversation

        /* // Enqueue the callout
        OpenAIQueueableCallout callout = new OpenAIQueueableCallout(context, prompt, recordId);
        System.enqueueJob(callout); */
        String response = OpenAI.sendMessage(context, prompt, recordId);
        
        /* Open_AI_Message__c responseMessage = new Open_AI_Message__c();
        responseMessage.Message__c = response;
        responseMessage.Sender_Type__c = 'Inbound';

        // Insert the response message into the database
        insert responseMessage; */

       /*  Continuation cont = new Continuation(60);
        cont.state = new Map<String, Object>{ 'recordId' => recordId };
        cont = OpenAI.sendMessage(cont, context, prompt, recordId); */
        return response;
    }
    @AuraEnabled
    public static void logMessages(String prompt, String botResponse, String recordId) {
        system.debug('Logging Message');
   
    List<Open_AI_Message__c> messages = new List<Open_AI_Message__c>();
    Open_AI_Message__c inboundMessage = new Open_AI_Message__c();

    inboundMessage.Message__c = botResponse;
    inboundMessage.Sender_Type__c = 'Inbound';
    inboundMessage.RecordId__c = recordId;
    messages.add(inboundMessage);

     Open_AI_Message__c outboundMessage = new Open_AI_Message__c();
    outboundMessage.Message__c = prompt;
    outboundMessage.Sender_Type__c = 'Outbound';
    outboundMessage.RecordId__c = recordId;
    messages.add(outboundMessage);

        try {
            insert messages;
        }
        catch (DmlException e) {
            system.debug('DmlException: ' + e.getMessage());
        }

  }
     /* // Continuation callback method
    @AuraEnabled
    public static void handleResponse(Object state, HttpResponse response) {
        String recordId = (String) ((Map<String, Object>) state).get('recordId');
        String responseBody = response.getBody();

        // Process the response and save it to the database
        // ... your code here ...
    } */
}
