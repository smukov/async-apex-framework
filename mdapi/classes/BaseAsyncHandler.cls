public abstract class BaseAsyncHandler implements AsyncRequestQueueable.IAsyncRequestHandler {
	
    // Cannot put more IDs in a Long Text Area
	public static final Integer MAX_NUMBER_OF_SINGLE_ID = 8190;
    public static final String PARAMETERS_SPLITTER = ';';

    /**
    * Prepares the Async_Request__c records by splitting the list of Ids into largest possible batch sizes. 
    *
    * NOTE: If you start hitting limits in request, call the overloaded method instead 
    * by providing a smaller batch size as a second parameter.
    *
    * @param  recordsToProcess set of IDs to be processed by Async Request
    * @param  batchSize        how many ID's to process at once
    *
    * @return                  List of Async_Request__c records ready to be inserted and enqueued 
    */
	public List<Async_Request__c> prepareAsyncRequests(Set<Id> recordsToProcess){
		return prepareAsyncRequests(recordsToProcess, MAX_NUMBER_OF_SINGLE_ID);
	} 

    /**
    * Prepares the Async_Request__c records by splitting the list of Ids into 
    * batches of provided size
    *
    * @param  recordsToProcess set of IDs to be processed by Async Request
    * @param  batchSize        how many ID's to process at once
    *
    * @return                  List of Async_Request__c records ready to be inserted and enqueued 
    */
	public List<Async_Request__c> prepareAsyncRequests(Set<Id> recordsToProcess, Integer batchSize){
		if(batchSize > MAX_NUMBER_OF_SINGLE_ID) throw new AsyncRequestQueueable.AsyncRequestException('Batch size cannot be larger than ' + MAX_NUMBER_OF_SINGLE_ID + ' Ids');
        return createAsyncRequests(convertToAsyncRequestParams(recordsToProcess), batchSize);
	}

    /**
    * Splits the provided asyncRequestParams into batches, and returns a list of Async_Request__c records
    *
    * @param  asyncRequestParams Set of record IDs to be processed
    * @param  batchSize          Batch size for each job
    *
    * @return                    return list of Async_Request__c records that can be inserted into database (enqueued)
    */
    private List<Async_Request__c> createAsyncRequests(Set<String> asyncRequestParams, Integer batchSize)
    {
        List<Async_Request__c> asyncRequests = new List<Async_Request__c>();
		Integer count = 0;
		String params = '';

		for(String arParam : asyncRequestParams){
			count++;
			params += arParam + PARAMETERS_SPLITTER;
			if(count >= batchSize)
			{
				asyncRequests.add(new Async_Request__c(
					Type__c = getRequestType(), 
					Params__c = params));

				count = 0;
				params = '';
			}
		}

		// the last batch
		if(String.isNotBlank(params)){
			asyncRequests.add(new Async_Request__c(
				Type__c = getRequestType(), 
				Params__c = params));
		}
		
		return asyncRequests;
    }

    /**
    * Converts and compreses a set of IDs to a set of Async Request Params
    *
    * @param  idsToProcess IDs to be converted
    *
    * @return              return compressed IDs
    */
    private Set<String> convertToAsyncRequestParams(Set<Id> idsToProcess){
        Set<String> retVal = new Set<String>();

        for(Id pId : idsToProcess){
            if(pId == null) throw new AsyncRequestQueueable.AsyncRequestException('At least one of the provided IDs is NULL');
            retVal.add(
                String.valueOf(pId).substring(0, 15) // compressing the IDs
            );
        }

        return retVal;
    }

	public abstract String getRequestType();
	public abstract void execute(Async_Request__c ar);
}
