/**
 * This trigger should never be changed, nor any other trigger logic should be added to 
 * Async_Request__c object. This trigger's sole purpose is to spin up the Async Request
 * processing when a new Async_Request__c record is created or edited.
 */
trigger AsyncRequestTrigger on Async_Request__c (after insert, after update) {
    
    if(Trigger.isInsert)
    {
        AsyncRequestQueueable.startJob();
    }
    else if(Trigger.isUpdate)
    {
        Boolean foundOne = false;

        // don't start Async Request if the record has an error message
        for(Async_Request__c ar : Trigger.new){
            if(String.isBlank(ar.Error_Msg__c)){
                foundOne = true;
                break;
            }
        }

        if(foundOne) AsyncRequestQueueable.startJob();
    }
}
