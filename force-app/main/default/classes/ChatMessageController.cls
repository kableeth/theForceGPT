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
        String response = OpenAI.sendMessage(context, prompt, recordId);
        return response;
    }
}
