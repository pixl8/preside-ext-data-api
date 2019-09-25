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
			var notFound = arguments.queueName == "default" || !dataApiConfigurationService.queueExists( queueName=arguments.queueName );

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

	public void function delete( string queueId="", string queueName="" ) {
		var queueIds = [];
		if ( !Len( Trim( arguments.queueName ) ) ) {
			if ( !Len( Trim( arguments.queueId ) ) ) {
				arguments.queueid = "default";
			}
			if ( dataApiConfigurationService.queueExists( arguments.queueId ) ) {
				arguments.queueName = arguments.queueId;

				var body = event.getHttpContent();

				try {
					queueIds = DeserializeJson( body );
				} catch( any e ) {
					logError( e );
					restResponse.setError(
						  errorCode = 400
						, title     = "Bad request"
						, message   = "Could not parse JSON body.."
					);
					return;
				}
			}
		}

		if ( !Len( Trim( arguments.queueName ) ) ) {
			queueIds = [ arguments.queueId ];
		}

		var deleted = dataApiQueueService.removeFromQueue( subscriber=restRequest.getUser(), queueIds=queueIds, queueName=arguments.queueName );

		restResponse.setData( { removed=deleted } );
	}

}