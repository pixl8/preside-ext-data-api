component extends="tests.BaseTest" {

	function run() {
		describe( "Entity access for an API user granted the API but with no data API settings rows", function(){
			it( "should deny every verb on every entity", function(){
				var svc = _getUserConfigService( settingsRows=[], hasCoreApiAccess=true );

				for ( var verb in [ "get", "post", "put", "delete" ] ) {
					expect( svc.hasEntityAccess( userId="user-1", api="/data/v1", entity="contact", verb=verb ) ).toBeFalse( "Expected [#verb#] to be denied" );
				}
			} );

			it( "should not fall back to the core API access grant", function(){
				var restAccessDao = _mockPresideObject( "rest_user_api_access" );
				var svc           = _getUserConfigService( settingsRows=[], restAccessDao=restAccessDao );

				svc.hasEntityAccess( userId="user-1", api="/data/v1", entity="contact", verb="get" );

				expect( restAccessDao.$count( "dataExists" ) ).toBe( 0 );
			} );
		} );

		describe( "Entity access for an API user with a single all-entities settings row", function(){
			it( "should allow only the verbs ticked on that row", function(){
				var svc = _getUserConfigService( settingsRows=[ _settingsRow( objectName="", get=true ) ] );

				expect( svc.hasEntityAccess( userId="user-1", api="/data/v1", entity="contact", verb="get"    ) ).toBeTrue();
				expect( svc.hasEntityAccess( userId="user-1", api="/data/v1", entity="contact", verb="delete" ) ).toBeFalse();
			} );
		} );

		describe( "Entity access for an API user with per-entity settings rows", function(){
			it( "should allow a granted verb on a listed entity", function(){
				var svc = _getUserConfigService(
					  settingsRows = [ _settingsRow( objectName="crm_contact", get=true ), _settingsRow( objectName="crm_organisation", get=true ) ]
					, entityObjects = { contact="crm_contact" }
				);

				expect( svc.hasEntityAccess( userId="user-1", api="/data/v1", entity="contact", verb="get" ) ).toBeTrue();
			} );

			it( "should deny an entity that has no settings row", function(){
				var svc = _getUserConfigService(
					  settingsRows = [ _settingsRow( objectName="crm_contact", get=true ), _settingsRow( objectName="crm_organisation", get=true ) ]
					, entityObjects = { subscription="crm_subscription" }
				);

				expect( svc.hasEntityAccess( userId="user-1", api="/data/v1", entity="subscription", verb="get" ) ).toBeFalse();
			} );
		} );

		describe( "Admin access picker for an API user granted the API but with no data API settings rows", function(){
			it( "should show no permissions ticked", function(){
				var svc = _getUserConfigService( settingsRows=[], hasCoreApiAccess=true );

				expect( svc.getExistingAccessDetailsForFormControl( api="/data/v1", userId="user-1" ) ).toBeEmpty();
			} );
		} );
	}

	private any function _getUserConfigService(
		  required array   settingsRows
		,          boolean hasCoreApiAccess = true
		,          struct  entityObjects    = {}
		,          any     restAccessDao
	) {
		var apiConfigService = getMockBox().createStub();
		var cache            = getMockBox().createStub();
		var settingsDao      = _mockPresideObject( "data_api_user_settings" );
		var entityMap        = arguments.entityObjects;

		apiConfigService.$( "getNamespaceForRoute" ).$results( "" );
		apiConfigService.$( "getEntities" ).$results( {} );
		apiConfigService.$( "getEntityObject" ).$callback( function( entity ) {
			return entityMap[ arguments.entity ] ?: "";
		} );

		cache.$( "get" );
		cache.$( "set" );

		settingsDao.$( "selectData" ).$results( _queryFromRows(
			  "object_name,get_allowed,post_allowed,put_allowed,delete_allowed"
			, "varchar,boolean,boolean,boolean,boolean"
			, arguments.settingsRows
		) );

		if ( IsNull( arguments.restAccessDao ) ) {
			arguments.restAccessDao = _mockPresideObject( "rest_user_api_access" );
			arguments.restAccessDao.$( "dataExists" ).$results( arguments.hasCoreApiAccess );
		}

		var svc = createMock( object=new dataApi.services.DataApiUserConfigurationService(
			  apiConfigService = apiConfigService
			, cache            = cache
		) );

		svc.$( "$getPresideObject" ).$args( "data_api_user_settings" ).$results( settingsDao );
		svc.$( "$getPresideObject" ).$args( "rest_user_api_access"   ).$results( arguments.restAccessDao );

		return svc;
	}

	private struct function _settingsRow(
		  required string  objectName
		,          boolean get    = false
		,          boolean post   = false
		,          boolean put    = false
		,          boolean delete = false
	) {
		return {
			  object_name    = arguments.objectName
			, get_allowed    = arguments.get
			, post_allowed   = arguments.post
			, put_allowed    = arguments.put
			, delete_allowed = arguments.delete
		};
	}
}