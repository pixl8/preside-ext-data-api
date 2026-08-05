component extends="tests.BaseTest" {

	function run() {
		describe( "getSpec()", function(){
			it( "should build a valid OpenAPI document with general metadata", function(){
				var bundle    = _fixtures().loadI18nProperties();
				var configSvc = _getConfigService();
				var apiSvc    = _getDataApiService( configSvc, "", bundle );
				var svc       = _getSpecService( configSvc, apiSvc, "", bundle );
				var spec      = svc.getSpec();

				expect( spec.openapi ).toBe( "3.0.1" );
				expect( spec.info.title ).toBe( bundle[ "api.title" ] );
				expect( spec.info.version ).toBe( bundle[ "api.version" ] );
				expect( ArrayLen( spec.servers ) ).toBe( 1 );
				expect( spec.servers[ 1 ].url ).toInclude( "https://example.com/api/data/v1" );
				expect( spec.components.securitySchemes.keyExists( "Basic" ) ).toBeTrue();
			} );

			it( "should include pagination and error handling trait tags", function(){
				var bundle    = _fixtures().loadI18nProperties();
				var configSvc = _getConfigService();
				var apiSvc    = _getDataApiService( configSvc, "", bundle );
				var svc       = _getSpecService( configSvc, apiSvc, "", bundle );
				var spec      = svc.getSpec();
				var traitTags = [];

				for ( var tag in spec.tags ) {
					if ( tag.keyExists( "x-traitTag" ) && tag[ "x-traitTag" ] ) {
						traitTags.append( tag.name );
					}
				}

				expect( traitTags ).toInclude( bundle[ "trait.pagination.title" ] );
				expect( traitTags ).toInclude( bundle[ "trait.errorhandling.title" ] );
			} );

			it( "should include pagination mode documentation for all modes in use", function(){
				var bundle    = _fixtures().loadI18nProperties();
				var configSvc = _getConfigService();
				var apiSvc    = _getDataApiService( configSvc, "", bundle );
				var svc       = _getSpecService( configSvc, apiSvc, "", bundle );
				var spec      = svc.getSpec();
				var paginationTag = {};

				for ( var tag in spec.tags ) {
					if ( tag.name == bundle[ "trait.pagination.title" ] ) {
						paginationTag = tag;
						break;
					}
				}

				expect( paginationTag.description ).toInclude( bundle[ "trait.pagination.intro" ] );
				expect( paginationTag.description ).toInclude( "paginationMode" );
				expect( paginationTag.description ).toInclude( "X-Total-Records" );
				expect( paginationTag.description ).toInclude( "cursor" );
				expect( paginationTag.description ).toInclude( "pageSize" );
			} );

			it( "should document fixed pagination without mode selection when only one mode is configured", function(){
				var bundle    = _fixtures().loadI18nProperties();
				var configSvc = _getConfigService(
					  defaults = { allowedPaginationModes=[ "offset" ], paginationMode="offset" }
				);
				var apiSvc    = _getDataApiService( configSvc, "", bundle );
				var svc       = _getSpecService( configSvc, apiSvc, "", bundle );
				var spec      = svc.getSpec();
				var paginationTag = {};
				var params        = spec.paths[ "/entity/contact/" ].get.parameters;
				var paramNames    = params.map( function( param ){ return param.name; } );
				var responseHeaders = spec.paths[ "/entity/contact/" ].get.responses[ "200" ].headers;

				for ( var tag in spec.tags ) {
					if ( tag.name == bundle[ "trait.pagination.title" ] ) {
						paginationTag = tag;
						break;
					}
				}

				expect( paginationTag.description ).toInclude( bundle[ "trait.pagination.intro.single" ] );
				expect( paginationTag.description ).notToInclude( "paginationMode" );
				expect( paginationTag.description ).toInclude( bundle[ "trait.pagination.offset.description" ] );
				expect( paginationTag.description ).notToInclude( bundle[ "trait.pagination.full.description" ] );
				expect( paginationTag.description ).notToInclude( bundle[ "trait.pagination.cursor.description" ] );

				expect( paramNames ).notToInclude( "paginationMode" );
				expect( paramNames ).toInclude( "page" );
				expect( paramNames ).toInclude( "pageSize" );
				expect( paramNames ).notToInclude( "cursor" );

				expect( responseHeaders.keyExists( "Link" ) ).toBeTrue();
				expect( responseHeaders.keyExists( "X-Total-Records" ) ).toBeFalse();
				expect( responseHeaders.keyExists( "X-Total-Pages" ) ).toBeFalse();
			} );

			it( "should omit paginationMode and page params for cursor-only entities", function(){
				var bundle    = _fixtures().loadI18nProperties();
				var configSvc = _getConfigService();
				var apiSvc    = _getDataApiService( configSvc, "", bundle );
				var svc       = _getSpecService( configSvc, apiSvc, "", bundle );
				var spec      = svc.getSpec();
				var params    = spec.paths[ "/entity/restricted_contact/" ].get.parameters;
				var paramNames = params.map( function( param ){ return param.name; } );
				var responseHeaders = spec.paths[ "/entity/restricted_contact/" ].get.responses[ "200" ].headers;

				expect( paramNames ).notToInclude( "paginationMode" );
				expect( paramNames ).notToInclude( "page" );
				expect( paramNames ).toInclude( "cursor" );
				expect( paramNames ).toInclude( "pageSize" );

				expect( responseHeaders.keyExists( "Link" ) ).toBeTrue();
				expect( responseHeaders.keyExists( "X-Total-Records" ) ).toBeFalse();
			} );

			it( "should expose paginationMode and page/cursor params on paginated GET endpoints", function(){
				var bundle    = _fixtures().loadI18nProperties();
				var configSvc = _getConfigService();
				var apiSvc    = _getDataApiService( configSvc, "", bundle );
				var svc       = _getSpecService( configSvc, apiSvc, "", bundle );
				var spec      = svc.getSpec();
				var params    = spec.paths[ "/entity/contact/" ].get.parameters;
				var paramNames = params.map( function( param ){ return param.name; } );

				expect( paramNames ).toInclude( "paginationMode" );
				expect( paramNames ).toInclude( "page" );
				expect( paramNames ).toInclude( "cursor" );
				expect( paramNames ).toInclude( "pageSize" );

				var paginationParam = {};
				for ( var param in params ) {
					if ( param.name == "paginationMode" ) {
						paginationParam = param;
						break;
					}
				}

				expect( paginationParam.schema.enum ).toInclude( "full" );
				expect( paginationParam.schema.enum ).toInclude( "offset" );
				expect( paginationParam.schema.enum ).toInclude( "cursor" );
				expect( paginationParam.schema.default ).toBe( "full" );
			} );

			it( "should restrict paginationMode options in docs when allowed modes are configured", function(){
				var bundle    = _fixtures().loadI18nProperties();
				var configSvc = _getConfigService(
					  defaults = { allowedPaginationModes=[ "offset", "cursor" ], paginationMode="offset" }
				);
				var apiSvc    = _getDataApiService( configSvc, "", bundle );
				var svc       = _getSpecService( configSvc, apiSvc, "", bundle );
				var spec      = svc.getSpec();
				var params    = spec.paths[ "/entity/contact/" ].get.parameters;
				var paginationParam = {};

				for ( var param in params ) {
					if ( param.name == "paginationMode" ) {
						paginationParam = param;
						break;
					}
				}

				expect( paginationParam.schema.enum ).toBe( [ "offset", "cursor" ] );
				expect( paginationParam.schema.default ).toBe( "offset" );
			} );

			it( "should include common pagination headers and validation schema components", function(){
				var bundle    = _fixtures().loadI18nProperties();
				var configSvc = _getConfigService();
				var apiSvc    = _getDataApiService( configSvc, "", bundle );
				var svc       = _getSpecService( configSvc, apiSvc, "", bundle );
				var spec      = svc.getSpec();

				expect( spec.components.headers.keyExists( "XTotalRecords" ) ).toBeTrue();
				expect( spec.components.headers.keyExists( "XTotalPages" ) ).toBeTrue();
				expect( spec.components.headers.keyExists( "Link" ) ).toBeTrue();
				expect( spec.components.schemas.keyExists( "validationMessage" ) ).toBeTrue();
			} );

			it( "should include entity paths for enabled entities", function(){
				var bundle    = _fixtures().loadI18nProperties();
				var configSvc = _getConfigService();
				var apiSvc    = _getDataApiService( configSvc, "", bundle );
				var svc       = _getSpecService( configSvc, apiSvc, "", bundle );
				var spec      = svc.getSpec();

				expect( spec.paths.keyExists( "/entity/contact/" ) ).toBeTrue();
				expect( spec.paths.keyExists( "/entity/contact/{recordId}/" ) ).toBeTrue();
				expect( spec.paths[ "/entity/contact/" ].keyExists( "get" ) ).toBeTrue();
				expect( spec.paths[ "/entity/contact/" ].keyExists( "post" ) ).toBeTrue();
				expect( spec.paths[ "/entity/contact/" ].keyExists( "put" ) ).toBeTrue();
				expect( spec.paths[ "/entity/readonly_contact/" ].keyExists( "post" ) ).toBeFalse();
			} );

			it( "should include queue paths when the queue feature is enabled", function(){
				var bundle    = _fixtures().loadI18nProperties();
				var configSvc = _getConfigService();
				var apiSvc    = _getDataApiService( configSvc, "", bundle );
				var svc       = _getSpecService( configSvc, apiSvc, "", bundle );
				var spec      = svc.getSpec();

				expect( spec.paths.keyExists( "/queue/" ) ).toBeTrue();
				expect( spec.components.schemas.keyExists( "QueueItem" ) ).toBeTrue();
			} );
		} );
	}

}
