/**
 * Sample job that does something dumb. 
 * It sets the Account.Description to current execution time.
 */
public without sharing class SampleJobAsync extends BaseAsyncHandler {

    public override String getRequestType(){
        return 'Sample Job';
    } 
    
    public override void execute(Async_Request__c ar)
    {
        List<String> accountIds = ar.Params__c.split(PARAMETERS_SPLITTER);

        if(accountIds.size() == 0) return;

        // Do something with Accounts

        List<Account> accountsToUpdate = [
            SELECT Id, Description
            FROM Account
            WHERE Id IN :accountIds
        ];

        String now = String.valueOf(DateTime.now());
        for(Account acc : accountsToUpdate){
            acc.Description = 'Updated: ' + now;
        }

        update accountsToUpdate;
    }
}
