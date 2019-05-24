component extends="coldbox.system.Interceptor" {

	property name="dataApiService"      inject="delayedInjector:dataApiService";
	property name="dataApiQueueService" inject="delayedInjector:dataApiQueueService";

	variables._applicationLoaded = false;

// PUBLIC
	public void function configure() {}

	public void function postPresideReload() {
		variables._applicationLoaded = true;
	}

	public void function onRestRequest( event, interceptData ) {
		if ( !_applicationLoaded ) return;

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
		if ( !_applicationLoaded ) return;
		dataApiQueueService.queueDelete( argumentCollection=interceptData );
	}

	public void function postUpdateObjectData( event, interceptData ) {
		if ( !_applicationLoaded ) return;
		dataApiQueueService.queueUpdate( argumentCollection=interceptData );
	}

	public void function postInsertObjectData( event, interceptData ) {
		if ( !_applicationLoaded ) return;
		dataApiQueueService.queueInsert( argumentCollection=interceptData );
	}
}