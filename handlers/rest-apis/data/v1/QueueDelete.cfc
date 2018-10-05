/**
 * @restUri /queue/{queueid}/
 *
 */
component {

	property name="dataApiQueueService" inject="dataApiQueueService";
	property name="dataApiService"      inject="dataApiService";

	public void function delete( required string queueId ) {
		var deleted = dataApiQueueService.removeFromQueue( subscriber=restRequest.getUser(), queueId=arguments.queueId );

		restResponse.setData( { removed=deleted } );
	}

}