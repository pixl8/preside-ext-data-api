/**
 * @restUri /queue/,/queue/{queueid}/,/queue/{queuename}/{queueid}/
 *
 */
component {

	property name="dataApiQueueService" inject="dataApiQueueService";
	property name="dataApiService"      inject="dataApiService";
	property name="dataApiConfigurationService" inject="dataApiConfigurationService";

	public void function get( string queueId="", string queueName=arguments.queueId ) {
		// hack to cater for one set of URIs for both DELETE and GET
		if ( arguments.queueName != arguments.queueid ) {
			restResponse.setStatus( 404, "The queue, [#arguments.queueId#], does not exist in this API." );
			restResponse.noData();
			restRequest.finish();
			return;
		}


		if ( Len( Trim( arguments.queueName ) ) ) {
			var notFound = arguments.queueName == "default"; // should be accessed as just `/queue/`, not `/queue/default/`
			if ( !notFound ) {
				try {
					dataApiConfigurationService.getQueue( queueName=arguments.queueName, throwOnMissing=true );
				} catch( "dataapi.queue.not.found" e ) {
					notFound = true;
				}
			}

			if ( notFound ) {
				restResponse.setStatus( 404, "The queue, [#arguments.queueName#], does not exist in this API." );
				restResponse.noData();
				restRequest.finish();
				return;
			}
		}

		var result = dataApiQueueService.getNextQueuedItems(
			  subscriber = restRequest.getUser()
			, queueName  = arguments.queueName
		);

		restResponse.setHeader( "X-Total-Records", result.queueSize );
		restResponse.setData( result.data );
	}

	public void function delete( required string queueId, string queueName="" ) {
		var deleted = dataApiQueueService.removeFromQueue( subscriber=restRequest.getUser(), queueId=arguments.queueId, queueName=arguments.queueName );

		restResponse.setData( { removed=deleted } );
	}

}