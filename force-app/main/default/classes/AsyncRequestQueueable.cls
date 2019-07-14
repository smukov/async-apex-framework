/**
 * This is the core of the framework. This class will process one request at a time, it will delete successfull requests,
 * and handle errors by updating the "Error_Msg__c" field on the failed ones. 
 */
public without sharing class AsyncRequestQueueable implements Queueable {

    /**
     * Add additional request handlers here. 
     * NOTE: Each handler must implement IAsyncRequestHandler interface.
     */
    private static Map<String, Type> requestHandlers = new Map<String, Type>{
        new SampleJobAsync().getRequestType() => SampleJobAsync.class,
        new SampleOptionsJobAsync().getRequestType() => SampleOptionsJobAsync.class
    };

    public static void startJob(){
        try{
            // this will prevent making 2 queuable jobs from 1 queueable
            if(Limits.getQueueableJobs() == 0) { System.enqueueJob(new AsyncRequestQueueable()); }
        }catch(Exception ex){
            System.debug(ex.getMessage());
            startJobFuture();
        }
    }

    @future static void startJobFuture(){
        System.enqueueJob(new AsyncRequestQueueable());
    }

    public void execute(QueueableContext context){

        // Change this Custom Metadata setting to FALSE in case something goes haywire
        if(!Configuration.getAsyncRequestConfig().Is_Async_Request_Processing_Enabled__c) return;
        
        List<Async_Request__c> requests = new List<Async_Request__c>();
        try{
            requests = [
                SELECT Id, Type__c, Error_Msg__c, Params__c, Options__c
                FROM Async_Request__c
                WHERE Error_Msg__c = null 
                LIMIT 1 FOR UPDATE
            ];
        }catch(System.QueryException ex){
            // It can happen sometimes that a 2nd queueable is started and 
            // it tries to process the same Async_Request__c record.
            // In that case just exit, and the other queueable that has the lock
            // will finish its work and enqueue the next pending request.
            return;
        }

        if(requests.size() == 0) return; // nothing to do, all requests processed

        Async_Request__c request = requests[0];

        if(detectFailedRequests(context))
        {
            // the queueable seems to be failing, and the error is not being catched, so it's probably a governor limit issue
            request.Error_Msg__c = 'Failing due to Governor Limits. Check Apex Jobs in Setup for further details.';
            update request;

        } else {
            
            // all good, process the request
            Savepoint sp = Database.setSavepoint();
            try{
                // check if there's a registered handler for this request type
                if(requestHandlers.containsKey(request.Type__c) == false) throw new AsyncRequestException('No registered handlers for this request type');
                
                // execute the request
                ((IAsyncRequestHandler) requestHandlers.get(request.Type__c).newInstance()).execute(request);
            
                // request successfully processed, it's OK to delete it
                delete request;

            }catch(Exception ex){

                // an error occured. Rollback the changes, and update the request's Error_Msg__c field
                Database.rollback(sp);
                request.Error_Msg__c = ex.getMessage().left(255);
                update request;
            }
        }

        

        // check if there is more pending requests, and if there is, start the next job
        requests = [SELECT Id FROM Async_Request__c WHERE Error_Msg__c = null limit 1];
        if(requests.size() > 0) startJob();
    } 

    /**
     * Detect requests that failed more than once in a row.TerritoryMgmt
     * This can usually happen due to some sort of Governor Limit exception that couldn't be catched.
     *
     * @param  context Current execution context
     * @return         TRUE - multiple failed requests detected
     */
    private Boolean detectFailedRequests(QueueableContext context){

        List<AsyncApexJob> jobs = [
            SELECT Id, Status, ExtendedStatus, CreatedDate, CompletedDate
            FROM AsyncApexJob
            WHERE JobType = 'Queueable' AND ApexClass.Name = 'AsyncRequestQueueable'
            AND Id != :context.getJobId() ORDER BY CreatedDate DESC LIMIT 2
        ];

        if(jobs.size() < 2) return false;
        for(AsyncApexJob job : jobs){
            if(job.Status != 'Failed') return false;
        }
        return true;
    }

    public interface IAsyncRequestHandler {
    
        /**
        * Prepares the Async_Request__c records by splitting the list of Ids into largest possible batch sizes. 
        *
        * NOTE: If you start hitting limits in request, call an overloaded method instead 
        * by providing a smaller batch size as a second parameter.
        *
        * @param  recordsToProcess set of IDs to be processed by Async Request
        * @param  batchSize        how many ID's to process at once
        *
        * @return                  List of Async_Request__c records ready to be inserted and enqueued 
        */
        List<Async_Request__c> prepareAsyncRequests(Set<Id> recordsToProcess);

        /**
        * Prepares the Async_Request__c records by splitting the list of Ids into 
        * batches of provided size
        *
        * @param  recordsToProcess set of IDs to be processed by Async Request
        * @param  batchSize        how many ID's to process at once
        *
        * @return                  List of Async_Request__c records ready to be inserted and enqueued 
        */
        List<Async_Request__c> prepareAsyncRequests(Set<Id> recordsToProcess, Integer batchSize);
 

        /**
        * Unique name of this Async Request
        */
        String getRequestType();

        
        /**
        * Logic to be executed
        */
        void execute(Async_Request__c ar);
    }

    public class AsyncRequestException extends Exception { }
}