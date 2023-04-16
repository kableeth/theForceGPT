public with sharing class ChatMessageController {
    @AuraEnabled(cacheable=true)
    public static List<Open_AI_Message__c> getMessages() {
        return [SELECT Id, OwnerId, Owner.Name, Message__c, Sender_Type__c, CreatedDate FROM Open_AI_Message__c ORDER BY CreatedDate DESC LIMIT 10];
    }

    @AuraEnabled
    public static void sendPrompt(String prompt, String recordId) {
        // Create a new Open_AI_Message__c record for the prompt
        Open_AI_Message__c newMessage = new Open_AI_Message__c();
        newMessage.Message__c = prompt;
        newMessage.Sender_Type__c = 'Outbound'; // Change this to 'Inbound' if the user is sending the prompt
        
        // Insert the new message into the database
        insert newMessage;

        // Call the OpenAI Apex class with the prompt
        String context = 'your-context-here'; // Set the context for the conversation
        String response = OpenAI.sendMessage(context, prompt, recordId);

        // Process the response and save it as needed
        // ...
    }
}
