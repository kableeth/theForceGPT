public class OpenAI {
  public static String sendMessage(
    String context,
    String prompt,
    String recordId
  ) {
    // Define the OpenAI API endpoint URL and API key
    String endpointUrl = 'https://api.openai.com/v1/chat/completions';

    // Retrieve the custom setting by its name for api key
    openaikey__c setting = openaikey__c.getInstance();
    String apiKey;
    // Check if the custom setting exists
    if (setting != null) {
      // Get the value of the secret_key__c field
      apiKey = setting.secret_key__c;
    }
    //get record info
    String record = getRecordInfo(recordId);
    Map<String, Object> requestBody = new Map<String, Object>();
    List<Object> messages = new List<Object>();

    Map<String, Object> message1 = new Map<String, Object>();
    message1.put('role', 'system');
    message1.put('content', context);
    messages.add(message1);

    Map<String, Object> message2 = new Map<String, Object>();
    message2.put('role', 'user');
    message2.put('content', prompt + '' + record);
    messages.add(message2);

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
    system.debug('requestBody');
    system.debug(requestBodyJSON);
    request.setBody(requestBodyJSON);

    Http http = new Http();
    HTTPResponse response = http.send(request);

    // Parse the response from the OpenAI API and extract the generated text
    String jsonResponse = response.getBody();
    System.debug(jsonResponse);

    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
      jsonResponse
    );
    List<Object> choicesList = (List<Object>) responseMap.get('choices');
    Map<String, Object> choiceMap = (Map<String, Object>) choicesList[0];
    Map<String, Object> messageMap = (Map<String, Object>) choiceMap.get(
      'message'
    );
    String content = (String) messageMap.get('content');
    System.debug(content);

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
    Schema.DescribeSObjectResult describeResult = recordId.getSObjectType()
      .getDescribe();
    List<String> fieldsIgnore = new List<String>();
    List<String> fieldsSpecial = new List<String>();

    fieldsSpecial.add('accountid');
    fieldsSpecial.add('ownerid');
    fieldsSpecial.add('lastmodifiedbyid');
    fieldsSpecial.add('createdbyid');
    fieldsSpecial.add('parentid');

    fieldsIgnore.add('masterrecordid');
    fieldsIgnore.add('reportstoid');
    fieldsIgnore.add('individualid');
    fieldsIgnore.add('rh2__describe__c');
    fieldsIgnore.add('recordtypeid');
    // Get the object name
    String objectName = describeResult.getName();
    String queryStr = 'SELECT ';

    Map<String, SObjectField> fieldMap = Schema.getGlobalDescribe()
      .get(objectName)
      .getDescribe()
      .fields.getMap();

    for (String fieldName : fieldMap.keySet()) {
      SObjectField field = fieldMap.get(fieldName);
      Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
      system.debug(fieldName);
      system.debug(fieldDescribe.getType());

      //don't add fields that are in the ignore
      if (fieldsSpecial.contains(fieldName)) {
        if (fieldName == 'accountid') {
          // This is a reference field, so we want to get the Name field as well
          queryStr += fieldName + ', ';
          fieldName = 'account';
          queryStr += fieldName + '.Name, ';
        }
        if (fieldName == 'ownerid') {
          queryStr += fieldName + ', ';
          fieldName = 'owner';
          queryStr += fieldName + '.Name, ';
        }
        if (fieldName == 'createdbyid') {
          queryStr += fieldName + ', ';
          fieldName = 'createdby';
          queryStr += fieldName + '.Name, ';
        }
        if (fieldName == 'lastmodifiedbyid') {
          queryStr += fieldName + ', ';
          fieldName = 'lastmodifiedby';
          queryStr += fieldName + '.Name, ';
        }
        if (fieldName == 'parentId') {
          queryStr += fieldName + ', ';
          fieldName = 'parent';
          queryStr += fieldName + '.Name, ';
        }
      } else if (
        fieldDescribe.getType() == Schema.DisplayType.REFERENCE &&
        !fieldsIgnore.contains(fieldName)
      ) {
        if (fieldName.endsWith('__c')) {
          queryStr += fieldName + ', ';
          fieldName = fieldName.replace('__c', '__r');
          queryStr += fieldName + '.Name, ';
        } else {
          queryStr += fieldName + ', ' + fieldName + '.Name, ';
        }
      } else {
        // Not a reference field, just add the field name
        queryStr += fieldName + ', ';
      }
      system.debug(queryStr);
    }

    queryStr = queryStr.substring(0, queryStr.length() - 2);
    queryStr +=
      ', (SELECT Id, Subject, Status, ActivityDate, Owner.Name FROM Tasks ORDER BY ActivityDate DESC LIMIT 10) FROM ' +
      objectName +
      ' WHERE Id = :recordId';

    String responseJSON;
    if (objectName == 'Account') {
      Account acc = new Account();
      acc = Database.query(queryStr);
      responseJSON = JSON.serialize(acc);
    } else {
      Contact c = new contact();
      c = Database.query(queryStr);
      responseJSON = JSON.serialize(c);
    }
    system.debug(responseJSON);
    return responseJSON;
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
