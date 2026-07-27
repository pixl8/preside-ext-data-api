component extends="testbox.system.BaseSpec" {

	private any function _fixtures() {
		if ( !StructKeyExists( variables, "_testFixtures" ) ) {
			variables._testFixtures = new tests.fixtures.DataApiTestFixtures();
		}

		return variables._testFixtures;
	}

	private struct function _defaultApiDefaults() {
		return {
			  allowIdInsert          = false
			, skipValidationOnInsert = false
			, skipValidationOnUpdate = false
			, responseTypeOnInsert   = "record"
			, responseTypeOnUpdate   = "record"
			, paginationMode         = "full"
		};
	}

	private void function _registerDefaultRoutes( required any configService, struct defaults={} ) {
		var apiDefaults = _defaultApiDefaults();
		StructAppend( apiDefaults, arguments.defaults, true );

		configService.addDataApiRoute(
			  dataApiRoute        = "/data/v1"
			, dataApiNamespace    = ""
			, dataApiDocs         = false
			, dataApiQueueEnabled = true
			, dataApiQueues       = { default={ pageSize=1, atomicChanges=false } }
			, dataApiDefaults     = apiDefaults
		);
		configService.addDataApiRoute(
			  dataApiRoute        = "/data/v1/docs"
			, dataApiNamespace    = ""
			, dataApiDocs         = true
			, dataApiQueueEnabled = false
			, dataApiQueues       = {}
		);
	}

	private void function _registerNamespaceRoute(
		  required any    configService
		, required string namespace
		,          struct defaults={}
		,          struct queues={ default={ pageSize=10, atomicChanges=true } }
	) {
		var apiDefaults = _defaultApiDefaults();
		StructAppend( apiDefaults, arguments.defaults, true );

		configService.addDataApiRoute(
			  dataApiRoute        = "/#arguments.namespace#/v1"
			, dataApiNamespace    = arguments.namespace
			, dataApiDocs         = false
			, dataApiQueueEnabled = true
			, dataApiQueues       = arguments.queues
			, dataApiDefaults     = apiDefaults
		);
	}

	private any function _mockRequestContext( string namespace="", struct extraValues={} ) {
		var rc             = getMockBox().createStub();
		var localNamespace = arguments.namespace;
		var localExtra     = arguments.extraValues;

		rc.$( "getValue" ).$callback( function( name, defaultValue="" ) {
			if ( arguments.name == "dataApiNamespace" ) {
				return localNamespace;
			}
			if ( localExtra.keyExists( arguments.name ) ) {
				return localExtra[ arguments.name ];
			}
			return arguments.defaultValue;
		} );
		rc.$( "getSite" ).$results( { domain="example.com", protocol="https" } );
		rc.$( "getServerName" ).$results( "example.com" );
		rc.$( "getProtocol" ).$results( "https" );
		rc.$( "getRestRequestUser" ).$results( "" );
		rc.$( "buildLink" ).$callback( function( linkto="", queryString="" ) {
			return "https://example.com/api/#arguments.linkto#?#arguments.queryString#";
		} );

		return rc;
	}

	private any function _mockPresideObjectService() {
		var poService = getMockBox().createStub();
		var objects   = _fixtures().getObjectFixtures();

		poService.$( "listObjects" ).$results( StructKeyArray( objects ) );
		poService.$( "getObjectAttribute" ).$callback( function( objectName, attribute, defaultValue="" ) {
			var obj = {};

			if ( objects.keyExists( arguments.objectName ) ) {
				obj = objects[ arguments.objectName ];
			}

			if ( structKeyExists( obj, "attributes" ) && obj.attributes.keyExists( arguments.attribute ) ) {
				return obj.attributes[ arguments.attribute ];
			}

			return arguments.defaultValue;
		} );
		poService.$( "getObjectProperties" ).$callback( function( objectName ) {
			var obj = {};

			if ( objects.keyExists( arguments.objectName ) ) {
				obj = objects[ arguments.objectName ];
			}

			if ( structKeyExists( obj, "properties" ) ) {
				return obj.properties;
			}

			return {};
		} );
		poService.$( "getObjectPropertyAttribute" ).$callback( function( objectName, propertyName, attribute ) {
			var obj   = {};
			var props = {};
			var value = "";

			if ( objects.keyExists( arguments.objectName ) ) {
				obj = objects[ arguments.objectName ];
			}
			if ( structKeyExists( obj, "properties" ) ) {
				props = obj.properties;
			}
			if ( structKeyExists( props, arguments.propertyName ) && structKeyExists( props[ arguments.propertyName ], arguments.attribute ) ) {
				value = props[ arguments.propertyName ][ arguments.attribute ];
			}

			return value;
		} );
		poService.$( "getIdField" ).$results( "id" );
		poService.$( "getDateModifiedField" ).$results( "datemodified" );
		poService.$( "getDateCreatedField" ).$results( "datecreated" );
		poService.$( "getDbAdapterForObject" ).$results( _mockDbAdapter() );
		poService.$( "getResourceBundleUriRoot" ).$results( "preside-objects:" );
		poService.$( "clearRelatedCaches" );

		return poService;
	}

	private any function _mockDbAdapter() {
		var dbAdapter = getMockBox().createStub();

		dbAdapter.$( "escapeEntity" ).$callback( function( entity ) {
			return arguments.entity;
		} );
		dbAdapter.$( "sqlDataTypeToCfSqlDatatype" ).$callback( function( dbtype ) {
			if ( ReFindNoCase( "^date", arguments.dbtype ) ) {
				return "cf_sql_timestamp";
			}
			return "cf_sql_varchar";
		} );

		return dbAdapter;
	}

	private query function _queryFromRows( required string columns, required string types, required array rows ) {
		var q = QueryNew( arguments.columns, arguments.types );

		for ( var row in arguments.rows ) {
			QueryAddRow( q, row );
		}

		return q;
	}

	private any function _mockPresideObject( string objectName="" ) {
		var dao = getMockBox().createStub();

		dao.$( "selectData" ).$results( [] );
		dao.$( "insertData" ).$results( CreateUUID() );
		dao.$( "updateData" ).$results( 1 );
		dao.$( "deleteData" ).$results( 1 );
		dao.$( "dataExists" ).$results( true );
		dao.$( "getIdField" ).$results( "id" );

		return dao;
	}

	private any function _wirePresideStubs(
		  required any service
		,          string namespace=""
		,          struct requestValues={}
		,          struct i18nBundle={}
	) {
		var rc           = _mockRequestContext( namespace, requestValues );
		var localI18n    = arguments.i18nBundle;
		var testFixtures = _fixtures();

		service.$( "$getRequestContext" ).$results( rc );
		service.$( "$getPresideObjectService" ).$results( _mockPresideObjectService() );
		service.$( "$getPresideObject" ).$callback( function( objectName ) {
			return _mockPresideObject( arguments.objectName );
		} );
		service.$( "$isFeatureEnabled" ).$callback( function( feature ) {
			if ( arguments.feature == "dataApiQueue" ) {
				return true;
			}
			if ( ListFindNoCase( "dataApiUseNullForNumerics,dataApiUseNullForStrings", arguments.feature ) ) {
				return true;
			}
			if ( arguments.feature == "dataApiFormulaFieldsForAtomic" ) {
				return false;
			}
			return false;
		} );
		service.$( "$translateResource" ).$callback( function( uri, defaultValue="", data=[] ) {
			if ( !StructIsEmpty( localI18n ) ) {
				return testFixtures.translateFromBundle( localI18n, arguments.uri, arguments.defaultValue );
			}
			if ( Len( arguments.defaultValue ) ) {
				return arguments.defaultValue;
			}
			return arguments.uri;
		} );
		service.$( "$getColdbox" ).$results( _mockColdbox() );
		service.$( "$getValidationEngine" ).$results( _mockValidationEngine() );
		service.$( "$getContentRendererService" ).$results( _mockContentRendererService() );
		service.$( "$renderContent" ).$results( "" );
		service.$( "$announceInterception" );
		service.$( "$raiseError" ).$callback( function( e ) {
			throw( e );
		} );

		return service;
	}

	private any function _mockColdbox() {
		var coldbox = getMockBox().createStub();

		coldbox.$( "getSetting" ).$results( "" );

		return coldbox;
	}

	private any function _mockRestRequest( struct config={}, struct state={} ) {
		var req = getMockBox().createStub();

		req.$( "getUri" ).$results( structKeyExists( config, "uri" ) ? config.uri : "/entity/contact/" );
		req.$( "getVerb" ).$results( structKeyExists( config, "verb" ) ? config.verb : "get" );
		req.$( "finish" ).$callback( function(){
			state.finished = ( state.finished ?: 0 ) + 1;
		} );

		return req;
	}

	private any function _mockRestResponse( struct state={} ) {
		var res = getMockBox().createStub();

		res.$( "setStatus" ).$callback( function(){
			state.status = ( state.status ?: 0 ) + 1;
		} );
		res.$( "setError" ).$callback( function(){
			state.error = ( state.error ?: 0 ) + 1;
		} );
		res.$( "setData" );
		res.$( "setHeader" );
		res.$( "noData" );

		return res;
	}

	private any function _sequentialSelectDataMock( required array results ) {
		var dao       = _mockPresideObject();
		var callCount = 0;
		var responses = arguments.results;

		dao.$( "selectData" ).$callback( function() {
			callCount++;
			return responses[ callCount ];
		} );

		return dao;
	}

	private any function _mockValidationEngine() {
		var engine = getMockBox().createStub();

		engine.$( "rulesetExists" ).$results( false );
		engine.$( "newRuleset" );
		engine.$( "validate" ).$callback( function() {
			var result = getMockBox().createStub();
			result.$( "validated" ).$results( true );
			result.$( "getMessages" ).$results( {} );
			return result;
		} );

		return engine;
	}

	private any function _mockContentRendererService() {
		var svc = getMockBox().createStub();

		svc.$( "rendererExists" ).$results( false );
		svc.$( "getRendererForField" ).$results( "string" );

		return svc;
	}

	private any function _getConfigService(
		  struct defaults={}
		, struct namespaceRoutes={}
		, string activeNamespace=""
	) {
		var presideFieldRuleGenerator = getMockBox().createStub();
		presideFieldRuleGenerator.$( "getRulesForField" ).$results( [] );

		var svc = createMock( object=new dataApi.services.DataApiConfigurationService(
			presideFieldRuleGenerator = presideFieldRuleGenerator
		) );

		_registerDefaultRoutes( svc, arguments.defaults );

		for ( var namespace in arguments.namespaceRoutes ) {
			var routeConfig = arguments.namespaceRoutes[ namespace ];
			var routeDefaults = structKeyExists( routeConfig, "defaults" ) ? routeConfig.defaults : {};
			var routeQueues   = structKeyExists( routeConfig, "queues" ) ? routeConfig.queues : { default={ pageSize=10, atomicChanges=true } };

			_registerNamespaceRoute(
				  configService = svc
				, namespace     = namespace
				, defaults      = routeDefaults
				, queues        = routeQueues
			);
		}

		return _wirePresideStubs( svc, activeNamespace );
	}

	private any function _getDataApiService(
		  required any configService
		, string namespace=""
		, struct i18nBundle={}
		, struct restTokens={ entity="contact" }
	) {
		var presideRestService = getMockBox().createStub();
		presideRestService.$( "extractTokensFromUri" ).$results( arguments.restTokens );

		var svc = createMock( object=new dataApi.services.DataApiService(
			  presideRestService            = presideRestService
			, configService                 = configService
			, relativeDateExpressionService = new dataApi.services.RelativeDateExpressionService()
		) );

		return _wirePresideStubs( svc, namespace, {}, i18nBundle );
	}

	private any function _getSpecService(
		  required any configService
		, required any dataApiService
		,          string namespace=""
		,          struct i18nBundle={}
	) {
		var presideRestConfigWrapper = getMockBox().createStub();
		presideRestConfigWrapper.$( "getSetting" ).$callback( function( key, defaultValue="", route="" ) {
			if ( arguments.key == "authProvider" ) {
				return "dataApi";
			}
			return arguments.defaultValue;
		} );

		var svc = createMock( object=new dataApi.services.DataApiSpecService(
			  configService            = configService
			, dataApiService           = dataApiService
			, presideRestConfigWrapper = presideRestConfigWrapper
		) );

		return _wirePresideStubs(
			  svc
			, namespace
			, { dataApiRoute="/data/v1", dataApiNamespace=namespace }
			, i18nBundle
		);
	}

	private any function _getQueueService( required any configService, required any dataApiService, string namespace="" ) {
		var svc = createMock( object=new dataApi.services.DataApiQueueService(
			  configService  = configService
			, dataApiService = dataApiService
		) );

		return _wirePresideStubs( svc, namespace );
	}

}
