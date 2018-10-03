component {

	public void function configure( required struct config ) {
		var conf     = arguments.config;
		var settings = conf.settings ?: {};

		_setupRestApis( settings );
		_setupInterceptors( conf );
	}

// private helpers
	private void function _setupRestApis( required struct settings ) {
		settings.features.apiManager.enabled    = true;
		settings.features.restTokenAuth.enabled = true;

		settings.rest.apis[ "/data/v1" ] = {
			  authProvider = "token"
			, description  = "Generic Preside REST API for external systems to interact with Preside data"
		};
	}

	private void function _setupInterceptors( required struct conf ) {
		conf.interceptors.append( {
			  class      = "app.extensions.preside-ext-data-api.interceptors.DataApiInterceptors"
			, properties = {}
		});
	}
}
