component extends="coldbox.system.Interceptor" {

	property name="dataApiService"              inject="delayedInjector:dataApiService";
	property name="dataApiQueueService"         inject="delayedInjector:dataApiQueueService";
	property name="dataApiConfigurationService" inject="delayedInjector:dataApiConfigurationService";
	property name="interceptorService"          inject="coldbox:InterceptorService";
	property name="queryCache"                         inject="cachebox:DefaultQueryCache";

	variables._applicationLoaded = false;

// PUBLIC
	public void function configure() {}

	public void function postPresideReload() {
		variables._applicationLoaded = true;
	}

	public void function postReadRestResourceDirectories( event, interceptData ) {
		var apis               = interceptData.apis ?: {};
		var apiSettings        = getSetting( name="rest.apis", defaultValue={} );
		var dataApiNamespace   = "";
		var dataApiDocs        = false;
		var dataApiQueues      = {};
		var base               = [];

		for( var apiRoute in apiSettings ) {
			dataApiNamespace = apiSettings[ apiRoute ].dataApiNamespace ?: "";
			if ( len( dataApiNamespace ) ) {
				dataApiDocs   = isTrue( apiSettings[ apiRoute ].dataApiDocs ?: "" );
				dataApiQueueEnabled = isTrue( apiSettings[ apiRoute ].dataApiQueueEnabled ?: !dataApiDocs );
				dataApiQueues = apiSettings[ apiRoute ].dataApiQueues ?: {};

				dataApiConfigurationService.addDataApiRoute(
					  dataApiRoute        = apiRoute
					, dataApiNamespace    = dataApiNamespace
					, dataApiDocs         = dataApiDocs
					, dataApiQueueEnabled = dataApiQueueEnabled
					, dataApiQueues       = dataApiQueues
				);

				base = duplicate( dataApiDocs ? apis[ "/data/v1/docs" ] : apis[ "/data/v1" ] );

				apis[ apiRoute ] = apis[ apiRoute ] ?: [];
				apis[ apiRoute ].append( base, true );

				apiSettings[ apiRoute ].append( ( dataApiDocs ? apiSettings[ "/data/v1/docs" ] : apiSettings[ "/data/v1" ] ), false )
			}
		}

		dataApiConfigurationService.addDataApiRoute(
			  dataApiRoute        = "/data/v1"
			, dataApiNamespace    = ""
			, dataApiDocs         = false
			, dataApiQueueEnabled = IsTrue( apiSettings[ "/data/v1" ].dataApiQueueEnabled ?: true )
			, dataApiQueues       = apiSettings[ "/data/v1" ].dataApiQueues ?: {}
		);
		dataApiConfigurationService.addDataApiRoute(
			  dataApiRoute        = "/data/v1/docs"
			, dataApiNamespace    = ""
			, dataApiDocs         = true
			, dataApiQueueEnabled = false
			, dataApiQueues       = {}
		);
	}

	public void function afterConfigurationLoad( event, interceptData ) {
		var dataApiInterceptionPoints    = getSetting( name="dataApiInterceptionPoints", defaultValue={} );
		var apiSettings                  = getSetting( name="rest.apis", defaultValue={} );
		var dataApiNamespace             = "";
		var namespacedInterceptionPoints = [];

		for( var api in apiSettings ) {
			dataApiNamespace = apiSettings[ api ].dataApiNamespace ?: "";

			if ( len( dataApiNamespace ) ) {
				for( var dataApiInterceptionPoint in dataApiInterceptionPoints ) {
					namespacedInterceptionPoints.append( dataApiInterceptionPoint & "_" & dataApiNamespace );
				}
			}
		}
		interceptorService.appendInterceptionPoints( namespacedInterceptionPoints );
		interceptorService.registerInterceptors();
	}

	public void function onRestRequest( event, interceptData ) {
		if ( !_applicationLoaded ) return;

		var restRequest  = interceptData.restRequest  ?: "";
		var restResponse = interceptData.restResponse ?: "";

		if ( !IsSimpleValue( restRequest ) ) {
			var api      = restRequest.getApi();
			var resource = restRequest.getResource();

			if ( api == "/data/v1" && resource.count() ) {
				dataApiService.onRestRequest( restRequest, restResponse );
				return;
			}

			var dataApiRoutes = dataApiConfigurationService.getDataApiRoutes();
			for( var apiRoute in dataApiRoutes ) {
				if ( api == apiRoute && reFindNoCase( "^data\.v1", resource.handler ?: "" ) ) {
					event.setValue( "dataApiRoute"    , apiRoute );
					event.setValue( "dataApiHandler"  , apiRoute.changeDelims( ".", "/" ) );
					event.setValue( "dataApiNamespace", dataApiRoutes[ apiRoute ].dataApiNamespace );
					if ( resource.count() ) {
						dataApiService.onRestRequest( restRequest, restResponse );
					}
					return;
				}
			}
		}
	}

	public void function preDeleteObjectData( event, interceptData ) {
		if ( !_applicationLoaded ) return;

		if( isEmptyString( interceptData.id ?: "" ) ){
			interceptData.deletedIds = dataApiQueueService.getDeletedRecordIds( argumentCollection = interceptData );
		}
	}

	public void function postDeleteObjectData( event, interceptData ) {
		if ( !_applicationLoaded ) return;

		var skipDataApiQueue = IsBoolean( interceptData.skipDataApiQueue ?: "" ) && interceptData.skipDataApiQueue;
		var skipSyncQueue    = IsBoolean( interceptData.skipSyncQueue    ?: "" ) && interceptData.skipSyncQueue;

		skipDataApiQueue = skipDataApiQueue || ( skipSyncQueue && dataApiConfigurationService.skipApiQueueWhenSkipSyncQueue( interceptData.objectName ) );

		if( skipDataApiQueue ) return;

		dataApiQueueService.queueDelete( argumentCollection=interceptData );
	}

	public void function preUpdateObjectData( event, interceptData ) {
		if ( !_applicationLoaded ) return;

		if ( dataApiQueueService.queueRequired( argumentCollection=interceptData ) ) {
			interceptData.calculateChangedData = true;
		}
	}

	public void function postUpdateObjectData( event, interceptData ) {
		if ( !_applicationLoaded ) return;

		var skipDataApiQueue = IsBoolean( interceptData.skipDataApiQueue ?: "" ) && interceptData.skipDataApiQueue;
		var skipSyncQueue    = IsBoolean( interceptData.skipSyncQueue    ?: "" ) && interceptData.skipSyncQueue;

		skipDataApiQueue = skipDataApiQueue || ( skipSyncQueue && dataApiConfigurationService.skipApiQueueWhenSkipSyncQueue( interceptData.objectName ) );

		if( skipDataApiQueue ) return;

		dataApiQueueService.queueUpdate( argumentCollection=interceptData );
	}

	public void function postInsertObjectData( event, interceptData ) {
		if ( !_applicationLoaded ) return;

		var skipDataApiQueue = IsBoolean( interceptData.skipDataApiQueue ?: "" ) && interceptData.skipDataApiQueue;
		var skipSyncQueue    = IsBoolean( interceptData.skipSyncQueue    ?: "" ) && interceptData.skipSyncQueue;

		skipDataApiQueue = skipDataApiQueue || ( skipSyncQueue && dataApiConfigurationService.skipApiQueueWhenSkipSyncQueue( interceptData.objectName ) );

		if( skipDataApiQueue ) return;

		dataApiQueueService.queueInsert( argumentCollection=interceptData );
	}



	public void function onCreateSelectDataCacheKey( event, interceptData ) {
		if ( !_applicationLoaded ) return;

		var objectName = interceptData.objectName ?: "";
		event.setValue( name="cacheKey", value=interceptData.cacheKey ?: "", private=true );
		event.setValue( name="getFromCache", value=false, private=true );
		event.setValue( name="#objectName#_useCache", value=true, private=true );

		var cachedResult = queryCache.get( interceptData.cacheKey );
		if ( !IsNull( local.cachedResult ) ) {
			event.setValue( name="getFromCache", value=true, private=true );
		}
	}

}
