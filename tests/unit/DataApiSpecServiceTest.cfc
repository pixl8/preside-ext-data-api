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
				expect( paginationTag.description ).toInclude( "X-Total-Records" );
				expect( paginationTag.description ).toInclude( "cursor" );
				expect( paginationTag.description ).toInclude( "pageSize" );
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
