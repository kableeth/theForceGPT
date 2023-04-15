public with sharing class ChatMessageController {
    @AuraEnabled(cacheable=true)
    public static List<Open_AI_Message__c> getMessages() {
        return [SELECT Id, OwnerId, Owner.Name, Message__c, Sender_Type__c, CreatedDate FROM Open_AI_Message__c ORDER BY CreatedDate DESC];
    }
}
