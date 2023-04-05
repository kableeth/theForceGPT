@isTest
public class OpenAI_Test {
    @isTest(SeeAllData=True)
     static void testSendMessage() {
        // Create test data
       List<Account> accounts = TestDataFactory.createTestAccounts(1, 'Customer');

        // Call the method being tested
        String response = OpenAI.sendMessage('test', 'test', accounts[0].Id);

        // Check that the response is not null
        System.assertNotEquals(null, response);
    }
}