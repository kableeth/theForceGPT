public class OpenAIQueueableCallout implements Queueable, Database.AllowsCallouts {
    private String context;
    private String prompt;
    private String recordId;

    public OpenAIQueueableCallout(String context, String prompt, String recordId) {
        this.context = context;
        this.prompt = prompt;
        this.recordId = recordId;
    }

    public void execute(QueueableContext context) {
        String response = OpenAI.sendMessage(this.context, this.prompt, this.recordId);
        
        Open_AI_Message__c responseMessage = new Open_AI_Message__c();
        responseMessage.Message__c = response;
        responseMessage.Sender_Type__c = 'Inbound';

        // Insert the response message into the database
        insert responseMessage;
    }
}
