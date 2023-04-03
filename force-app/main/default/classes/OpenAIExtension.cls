public with sharing class OpenAIExtension {
    
     // Create a wrapper class for invocable variables
     public class FlowInput {
        
        @InvocableVariable(label='Record ID' required=true)
        public String recordId;

    }

    // Create a wrapper class for invocable method response
    public class FlowResponse {
        @InvocableVariable(label='Response')
        public String response;
    }
    
    @InvocableMethod(label='Draft f/U Email with Open AI' description='drafts a follow up email on the record with Open AI')
    public static List<FlowResponse> draftFollowUpEmail(List<FlowInput> flowInputs) {
        List<FlowResponse> flowResponses = new List<FlowResponse>();
        for (FlowInput flowInput : flowInputs) {
            FlowResponse flowResponse = new FlowResponse();
            flowResponse.response = OpenAI.draftFollowUpEmail(flowInput.recordId);
            flowResponses.add(flowResponse);
        }
        return flowResponses;
    }
}