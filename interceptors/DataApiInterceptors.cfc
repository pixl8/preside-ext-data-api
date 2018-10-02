component extends="coldbox.system.Interceptor" {

	property name="dataApiService" inject="delayedInjector:dataApiService";

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
}