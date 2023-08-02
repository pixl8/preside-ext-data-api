component {

	public void function configure( required struct config ) {
		var conf     = arguments.config;
		var settings = conf.settings ?: {};

		_setupFeatures( settings );
		_setupRestApis( settings );
		_setupEnums( settings );
		_setupInterceptors( conf );
	}

// private helpers
	private void function _setupFeatures( settings ) {
		settings.features.apiManager.enabled    = true;
		settings.features.restTokenAuth.enabled = true;

		settings.features.dataApiQueue = settings.features.dataApiQueue ?: { enabled=true };

		settings.features.dataApiFormulaFieldsForAtomic = settings.features.dataApiFormulaFieldsForAtomic ?: { enabled=true };
	}

	private void function _setupRestApis( required struct settings ) {
		settings.rest.apis[ "/data/v1" ] = {
			  authProvider = "dataApi"
			, description  = "Generic Preside REST API for external systems to interact with Preside data"
			, configHandler = "dataApiManager"
			, dataApiQueues = { default={ pageSize=1, name="", atomicChanges=false } }
		};
		settings.rest.apis[ "/data/v1/docs" ] = {
			  description     = "Documentation for REST APIs (no authentication required)"
			, hideFromManager = true
		};
	}

	private void function _setupEnums( required struct settings ) {
		settings.enum.dataApiQueueOperation = [ "insert", "update", "delete" ];
	}

	private void function _setupInterceptors( required struct conf ) {
		conf.interceptors.append( {
			  class      = "app.extensions.preside-ext-data-api.interceptors.DataApiInterceptors"
			, properties = {}
		});

		conf.settings.dataApiInterceptionPoints = [
			  "onOpenApiSpecGeneration"
			, "preDataApiInsertData"
			, "postDataApiInsertData"
			, "preDataApiUpdateData"
			, "postDataApiUpdateData"
			, "preDataApiDeleteData"
			, "postDataApiDeleteData"
			, "preDataApiSelectData"
			, "postDataApiSelectData"
			, "preValidateUpsertData"
		];
		conf.interceptorSettings.customInterceptionPoints.append( conf.settings.dataApiInterceptionPoints, true );
	}
}
