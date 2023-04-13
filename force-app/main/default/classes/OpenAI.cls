public with sharing class OpenAI {
  public static String sendMessage(String context, String prompt, String recordId) {
    // Define the OpenAI API endpoint URL and API key
    String endpointUrl = 'https://api.openai.com/v1/chat/completions';

    // Retrieve the custom setting by its name for api key
    openaikey__c setting = openaikey__c.getInstance();
    Map<String, Object> requestBody = new Map<String, Object>();
    List<Object> messages = new List<Object>();
    String apiKey;
    // Check if the custom setting exists
    if (setting != null) {
      // Get the value of the secret_key__c field
      apiKey = setting.secret_key__c;
    }
    else {
      throw new CalloutException('Error: Missing API Key');
    }
    //get record info from the page that the user is viewing
    system.debug('Getting record info');
    String record = getRecordInfo(recordId);

    //set LLM system prompt message
    Map<String, Object> message1 = new Map<String, Object>();
    message1.put('role', 'system');
    message1.put('content', context);
    messages.add(message1);

    //set user prompt as input
    Map<String, Object> message2 = new Map<String, Object>();
    message2.put('role', 'user');
    message2.put('content', prompt + '' + record);
    messages.add(message2);

    //set required variables
    requestBody.put('model', 'gpt-3.5-turbo');
    requestBody.put('messages', messages);
    requestBody.put('temperature', 1);
    requestBody.put('top_p', 1);
    requestBody.put('n', 1);
    requestBody.put('stream', false);
    requestBody.put('max_tokens', 250);
    requestBody.put('presence_penalty', 0);
    requestBody.put('frequency_penalty', 0);

    String requestBodyJSON = JSON.serialize(requestBody);

    // Make a call to the OpenAI API using the HttpRequest class
    HttpRequest request = new HttpRequest();
    request.setEndpoint(endpointUrl);
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json');
    request.setHeader('Authorization', 'Bearer ' + apiKey);
    request.setBody(requestBodyJSON);

    Http http = new Http();
    HTTPResponse response;
    
    try {
      response = http.send(request);
    }
    catch (Exception e) {
    // Display the error message
    throw new CalloutException('Error calling OpenAI API: ' + e.getMessage());
    }

    // Parse the response from the OpenAI API and get the response
    String jsonResponse = response.getBody();

    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
      jsonResponse
    );
    //check for error
    if (responseMap.containsKey('error')) {
      Map<String, Object> errorMap = (Map<String, Object>) responseMap.get('error');
      String errorMessage = (String) errorMap.get('message');
      String errorCode = (String) errorMap.get('code');
      throw new CalloutException('Error from OpenAI API: ' + errorMessage + ' (Code: ' + errorCode + ')');
    } 
    List<Object> choicesList = (List<Object>) responseMap.get('choices');
    Map<String, Object> choiceMap = (Map<String, Object>) choicesList[0];
    Map<String, Object> messageMap = (Map<String, Object>) choiceMap.get(
      'message'
    );
    String content = (String) messageMap.get('content');

    return content;
  }
  //draft follow up email
  public static String draftFollowUpEmail(Id recordId) {
    User user;
    user = [SELECT Signature FROM User WHERE Signature != NULL];
    String signature = user.Signature;
    List<Sales_Email_Example__c> salesEmailExamples = new List<Sales_Email_Example__c>();

    salesEmailExamples = [SELECT Body__c FROM Sales_Email_Example__c];

    String emailExamples = JSON.serialize(salesEmailExamples);

    String message = sendMessage(
      'you are a helpful assistant creating a follow up email using the following record and following email examples as a style and data ' +
        emailExamples +
        ' and your signature is ' +
        signature,
      'draft a follow up email using the following record',
      recordId
    );
    return message;
  }
  public static String getRecordInfo(Id recordId) {
    // Get the describe result for the object
    String responseJSON;
    Schema.DescribeSObjectResult describeResult = recordId.getSObjectType().getDescribe();
    String objectName = describeResult.getName();
    String queryStr = createQueryStr(recordId);
    
    
    if (objectName == 'Account') {
      Account acc = new Account();
      acc = Database.query(queryStr);
      responseJSON = JSON.serialize(acc);
    } else {
      Contact c = new contact();
      c = Database.query(queryStr);
      system.debug(c);
      responseJSON = JSON.serialize(c);
    }
    system.debug(responseJSON);
    return responseJSON;
  }
  private static String createQueryStr(Id recordId) {
    String queryStr = 'SELECT ';
    //get object & field info
    Schema.DescribeSObjectResult describeResult = recordId.getSObjectType().getDescribe();
    String objectName = describeResult.getName();
    Map<String, SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
    system.debug('objectName: ' + objectName);

    //vars
    List<OpenAI_Chat_Settings_Special_Fields__mdt> fieldsSpecial = new List<OpenAI_Chat_Settings_Special_Fields__mdt>();
    Map<String, String> fieldNamesReplaced = new Map<String, String>();
    List<String> fieldNamesIgnore = new List<String>();
    
    //get field api names to prevent data leak and errors with api names that are different when using going through lookup relationship e.g.
    fieldsSpecial= [SELECT Field_API_Name__c, Action__c, Replaced_Field_API_Name__c FROM OpenAI_Chat_Settings_Special_Fields__mdt];
    system.debug('Special Fields:' + fieldsSpecial);

    //get new field api names from custom meta data
    for(OpenAI_Chat_Settings_Special_Fields__mdt mdt :fieldsSpecial) {
      if(mdt.Action__c == 'Replace') {
        fieldNamesReplaced.put(mdt.Field_API_Name__c, mdt.Replaced_Field_API_Name__c);
      }
      else if (mdt.Action__c == 'Ignore') {
        fieldNamesIgnore.add(mdt.Field_API_Name__c);
      }
    }
    system.debug('fieldNamesReplaced:' + fieldNamesReplaced);
    system.debug('fieldNamesIgnore:' + fieldNamesIgnore);

    //Create SOQL query by looping through object fields
    for (String fieldName : fieldMap.keySet()) {

      //get the field type to determine how if it's a reference field 
      SObjectField field = fieldMap.get(fieldName);
      Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

      //Check if field api name is on the list of names to ignore, continue if so
      if(fieldNamesIgnore.contains(fieldName)) {
        continue;
      }
      //add field api name of special fields that require a different name when querying
      else if(fieldNamesReplaced.containsKey(fieldName)) {
        queryStr += fieldName + ', ';
        fieldName = fieldNamesReplaced.get(fieldName);
      } 
      //Add Name from referenced fields
      else if ( fieldDescribe.getType() == Schema.DisplayType.REFERENCE && !fieldNamesIgnore.contains(fieldName)) {
        if (fieldName.endsWith('__c')) {
          queryStr += fieldName + ', ';
          fieldName = fieldName.replace('__c', '__r');
          queryStr += fieldName + '.Name, ';
        } else {
          queryStr += fieldName + ', ' + fieldName + '.Name, ';
        }
      } else {
        // if just a regular field, go ahead and add to query string
        queryStr += fieldName + ', ';
      }
    system.debug('queryStr: ' + queryStr);
    }
    //create query string
    queryStr = queryStr.substring(0, queryStr.length() - 2);
    queryStr +=
      ', (SELECT Id, Subject, Status, ActivityDate, Owner.Name FROM Tasks ORDER BY ActivityDate DESC LIMIT 10) FROM ' +
      objectName +
      ' WHERE Id = :recordId';
    system.debug('queryStr = ' + queryStr);

    return queryStr;
  }

  // Create a wrapper class for invocable variables
  public class FlowInput {
    @InvocableVariable(label='Prompt' required=true)
    public String prompt;

    @InvocableVariable(label='Record ID' required=true)
    public String recordId;

    @InvocableVariable(label='Context' required=true)
    public String context;
  }

  // Create a wrapper class for invocable method response
  public class FlowResponse {
    @InvocableVariable(label='Response')
    public String response;
  }

  // Create an invocable method that accepts a list of FlowInput objects and returns a list of FlowResponse objects
  @InvocableMethod(
    label='Send Message to OpenAI API'
    description='Sends a message to the OpenAI API using GPT-3.5 Turbo and returns the response.'
  )
  public static List<FlowResponse> sendOpenAIRequest(
    List<FlowInput> flowInputs
  ) {
    List<FlowResponse> flowResponses = new List<FlowResponse>();
    for (FlowInput flowInput : flowInputs) {
      FlowResponse flowResponse = new FlowResponse();
      flowResponse.response = sendMessage(
        flowInput.context,
        flowInput.prompt,
        flowInput.recordId
      );
      flowResponses.add(flowResponse);
    }
    return flowResponses;
  }
}
