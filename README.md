# Salesforce Async Apex framework

My implementation of Dan Appleman's Asynchronous Apex framework. Here's the [link](https://www.salesforce.com/video/192729/) to the original presentation.

<a href="https://githubsfdeploy.herokuapp.com">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

## How to test the sample job:

Assing the **Manage Async Requests** Permission Sett to your user and execute the following snippet: 

```
// NOTE: this will update all your Accounts' Description field to "Updated: {execution time}"
Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id FROM Account]);
insert new SampleJobAsync().prepareAsyncRequests(accounts.keySet());
```

> NOTE: Due to the fact that Anonymous Apex enforces FLS, you need to have **Manage Async Requests** Permission Set assigned before executing the snippet above. You **don't** have to assign it to other users in order to use this framework.

## How to add new Async Job types / Handlers

Follow the below steps and use `SampleJobAsync` implementation as a helpful reference:

1. Create a new class that extends the `BaseAsyncHandler`
2. Implement `getRequestType()` method (NOTE: it should return a string that is unique accross all handlers)
3. Implement `execute(..)` method
4. Register the new handler by adding it to `requestHandlers` map in `AsyncRequestQueueable` class

Then, to enqueu it, call:

```
insert new YOUR_NEW_ASYNC_JOB_CLASS().prepareAsyncRequests(SOME_SET_OF_IDS);
```

## Monitoring Async Requests

All pending and failed requests can be seen in **Async Requests** tab. In order to see this tab in Salesforce users have to be added to **Manage Async Requests** Permission Set.

## Requeue failed requests

In order to requeue failed requests, you have to find it in **Async Requests** tab and clear the `Error Msg` field.

## Disabling all Async Requests

If something goes haywire and you need to switch off the processing of all requests, go to `Setup > Custom Metadata Types`, then click **Manage Records** next to `Async Request Settings`, edit the `Default` record, clear the `Is Async Request Processing Enabled` checkbox and save it.

## For more info

See inline documentation.
