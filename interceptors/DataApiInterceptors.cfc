component extends="coldbox.system.Interceptor" {

	property name="dataApiService"      inject="delayedInjector:dataApiService";
	property name="dataApiQueueService" inject="delayedInjector:dataApiQueueService";

// PUBLIC
	public void function configure() {}

	public void function onRestRequest( event, interceptData ) {
		var restRequest  = interceptData.restRequest  ?: "";
		var restResponse = interceptData.restResponse ?: "";

		if ( !IsSimpleValue( restRequest ) ) {
			var api = restRequest.getApi();
			var resource = restRequest.getResource();


			if ( api == "/data/v1" && resource.count() ) {
				dataApiService.onRestRequest( restRequest, restResponse );
			}
		}
	}

	public void function postDeleteObjectData( event, interceptData ) {
		dataApiQueueService.queueDelete( argumentCollection=interceptData );
	}

	public void function postUpdateObjectData( event, interceptData ) {
		dataApiQueueService.queueUpdate( argumentCollection=interceptData );
	}

	public void function postInsertObjectData( event, interceptData ) {
		dataApiQueueService.queueInsert( argumentCollection=interceptData );
	}
}