@isTest
public class OpenAI_Test {
  @isTest(SeeAllData=true)
  static void testSendMessage() {
    // Create test data
    List<Account> accounts = TestDataFactory.createTestAccounts(1, 'Customer');

    // Set up mock implementation
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new MyHttpCalloutMock());

    // Call the method being tested
    String response = OpenAI.sendMessage('test', 'test', accounts[0].Id);

    // Check that the response is not null
    System.assertNotEquals(null, response);
    Test.stopTest();
  }

  @isTest
  static void testDraftFollowUpEmail() {
    List<Account> accounts = TestDataFactory.createTestAccounts(1, 'Customer');

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new MyHttpCalloutMock());
    // Call the method under test
    List<OpenAIExtension.FlowInput> flowInputs = new List<OpenAIExtension.FlowInput>();
    OpenAIExtension.FlowInput flowInput = new OpenAIExtension.FlowInput();
    flowInput.recordId = accounts[0].Id;
    flowInputs.add(flowInput);
    List<OpenAIExtension.FlowResponse> flowResponses = OpenAIExtension.draftFollowUpEmail(
      flowInputs
    );

    // Verify the result
    System.assertEquals(1, flowResponses.size());
    System.assertNotEquals(null, flowResponses[0].response);
    Test.stopTest();
  }

  // Mock implementation of HTTP callout
  private class MyHttpCalloutMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      // Create mock response
      HTTPResponse res = new HTTPResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setStatusCode(200);

      // Create mock response body
      Map<String, Object> responseBody = new Map<String, Object>();
      res.setBody(
        '{"id": "chatcmpl-7217xqZ7VtxNIju58zfvPXvzl5iUM",' +
          '"object": "chat.completion","created": 1680715345,' +
          '"model": "gpt-3.5-turbo-0301",' +
          '"usage": {"prompt_tokens": 46, "completion_tokens": 20,' +
          '"total_tokens": 66},"choices": [{"message": {"role": "assistant",' +
          '"content": "The 2020 World Series was played at Globe Life Field in' +
          ' Arlington, Texas, United States."},"finish_reason": "stop","index": 0}]}'
      );

      return res;
    }
  }
}
