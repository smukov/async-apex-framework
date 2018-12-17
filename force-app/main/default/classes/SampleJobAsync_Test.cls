@isTest
private class SampleJobAsync_Test {
    
    @isTest static void should_update_all_accounts(){
        // Arrange

        List<Account> newAccounts = new List<Account>();
        for(Integer i = 0; i < 200; i++){
            newAccounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert newAccounts;

        // Act

        Test.startTest();
        Set<Id> accIds = new Map<Id, Account>(newAccounts).keySet();
        insert new SampleJobAsync().prepareAsyncRequests(accIds);
        Test.stopTest();

        // Assert 

        List<Account> updatedAccounts = [
            SELECT Id, Description
            FROM Account
        ];

        System.assertEquals(200, updatedAccounts.size(), 'Expected 200 accounts in the system');
        
        for(Account acc : updatedAccounts){
            System.assert(acc.Description.startsWith('Updated: '), 'Expected all accounts descriptions to be updated with "Updated: xxx" string');
        }
    }
}
