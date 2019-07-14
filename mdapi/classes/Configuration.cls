/**
 * Provided Configuration class only handles Async Requests configuration. 
 * However, in reality, this is can be extended to handle 
 * all Custom Metadata driven configs
 */
public class Configuration {
    
    // Use this Developer Name for all default Custom Metadata Types
    private static final String DEFAULT_DEVELOPER_NAME = 'Default';

    /**
     * Get Global Settings for the Org
     */
    private static Async_Request_Settings__mdt asyncRequestConfig;
    public static Async_Request_Settings__mdt getAsyncRequestConfig(){
        if(asyncRequestConfig == null){
             asyncRequestConfig = [
                SELECT Is_Async_Request_Processing_Enabled__c
                FROM Async_Request_Settings__mdt
                WHERE DeveloperName = :DEFAULT_DEVELOPER_NAME
            ];
        }
        return asyncRequestConfig;
    }

    public class ConfigurationException extends Exception { }
}