/**
 * Sample job that does something dumb and demonstrates the use of Options field. 
 * It sets the Account.Description to the value provided in Options field.
 */
public without sharing class SampleOptionsJobAsync extends BaseAsyncHandler {

    public override String getRequestType(){
        return 'Sample Options Job';
    } 
    
    public override void execute(Async_Request__c ar)
    {
        List<Id> accountIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(accountIds.size() == 0) return;

        Options opt = (Options) JSON.deserialize(ar.Options__c, Options.class);

        // Do something with Accounts

        List<Account> accountsToUpdate = [
            SELECT Id, Description
            FROM Account
            WHERE Id IN :accountIds
        ];

        for(Account acc : accountsToUpdate){
            acc.Description = opt.Description;
        }

        update accountsToUpdate;
    }

    public class Options {
        public String Description {get; set;}

        public Options(String description){
            this.Description = description;
        }
    }
}