/**
 * @restUri /queue/
 *
 */
component {

	property name="dataApiQueueService" inject="dataApiQueueService";
	property name="dataApiService"      inject="dataApiService";

	public void function get() {
		var record = dataApiQueueService.getNextQueuedItem( subscriber=restRequest.getUser() );

		if ( record.count() ) {
			var queueSize = dataApiQueueService.getQueueCount( subscriber=restRequest.getUser() );
			restResponse.setHeader( "X-Total-Records", queueSize+1 );

			if ( queueSize ) {
				var handler  = event.getValue( name="dataApiHandler", defaultValue="data.v1" );
				var nextLink = event.buildLink( linkto="api.#handler#.queue" );
				restResponse.setHeader( "Link", "<#nextLink#>; rel=""next""" );
			}
		} else {
			restResponse.setHeader( "X-Total-Records", 0 );
		}

		restResponse.setData( record );
	}

}