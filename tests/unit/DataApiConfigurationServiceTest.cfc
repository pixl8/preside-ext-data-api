component extends="tests.BaseTest" {

	function run() {
		describe( "getDefaultConfigForApiNamespace()", function(){
			it( "should return namespace default config values for the default API", function(){
				var svc = _getConfigService( defaults={ paginationMode="offset", allowIdInsert=true } );

				expect( svc.getDefaultConfigForApiNamespace( "paginationMode" ) ).toBe( "offset" );
				expect( svc.getDefaultConfigForApiNamespace( "allowIdInsert" ) ).toBe( true );
				expect( svc.getDefaultConfigForApiNamespace( "responseTypeOnInsert" ) ).toBe( "record" );
			} );

			it( "should return namespace default config values for a custom namespace", function(){
				var svc = _getConfigService(
					  namespaceRoutes = {
						  myApi = {
							  defaults = {
								  paginationMode         = "cursor"
								, responseTypeOnInsert = "idonly"
								, allowIdInsert        = true
							  }
						  }
					  }
					, activeNamespace = "myApi"
				);

				expect( svc.getDefaultConfigForApiNamespace( "paginationMode", "myApi" ) ).toBe( "cursor" );
				expect( svc.getDefaultConfigForApiNamespace( "responseTypeOnInsert", "myApi" ) ).toBe( "idonly" );
				expect( svc.getDefaultConfigForApiNamespace( "allowIdInsert", "myApi" ) ).toBe( true );
			} );

			it( "should fall back to the supplied default when the key is not configured", function(){
				var svc = _getConfigService();

				expect( svc.getDefaultConfigForApiNamespace( "unknownKey", "", "fallback" ) ).toBe( "fallback" );
			} );

			it( "should apply namespace defaults when building entity configuration", function(){
				var svc = _getConfigService(
					  namespaceRoutes = {
						  myApi = { defaults={ paginationMode="offset", allowIdInsert=true } }
					  }
					, activeNamespace = "myApi"
				);

				var entities = svc.getEntities( "myApi" );

				expect( entities.ns_contact.paginationMode ).toBe( "offset" );
				expect( entities.ns_contact.allowIdInsert ).toBe( true );
			} );
		} );

		describe( "entity discovery and access control", function(){
			it( "should include enabled entities and exclude disabled and versioned objects", function(){
				var svc = _getConfigService();
				var entities = svc.getEntities();

				expect( entities.keyExists( "contact" ) ).toBeTrue();
				expect( entities.keyExists( "cursor_contact" ) ).toBeTrue();
				expect( entities.keyExists( "offset_contact" ) ).toBeTrue();
				expect( entities.keyExists( "readonly_contact" ) ).toBeTrue();
				expect( entities.keyExists( "disabled_object" ) ).toBeFalse();
				expect( entities.keyExists( "vrsn_test" ) ).toBeFalse();
			} );

			it( "should report whether an entity is enabled", function(){
				var svc = _getConfigService();

				expect( svc.entityIsEnabled( "contact" ) ).toBeTrue();
				expect( svc.entityIsEnabled( "missing_entity" ) ).toBeFalse();
			} );

			it( "should respect verb restrictions per entity", function(){
				var svc = _getConfigService();

				expect( svc.entityVerbIsSupported( "contact", "get" ) ).toBeTrue();
				expect( svc.entityVerbIsSupported( "contact", "post" ) ).toBeTrue();
				expect( svc.entityVerbIsSupported( "readonly_contact", "get" ) ).toBeTrue();
				expect( svc.entityVerbIsSupported( "readonly_contact", "post" ) ).toBeFalse();
			} );

			it( "should resolve object and entity names in both directions", function(){
				var svc = _getConfigService();

				expect( svc.getEntityObject( "contact" ) ).toBe( "test_contact" );
				expect( svc.getObjectEntity( "test_contact" ) ).toBe( "contact" );
			} );
		} );

		describe( "pagination configuration", function(){
			it( "should resolve pagination mode per entity", function(){
				var svc = _getConfigService();

				expect( svc.getEntityPaginationMode( "contact" ) ).toBe( "full" );
				expect( svc.getEntityPaginationMode( "offset_contact" ) ).toBe( "offset" );
				expect( svc.getEntityPaginationMode( "cursor_contact" ) ).toBe( "cursor" );
			} );

			it( "should allow all pagination modes by default", function(){
				var svc = _getConfigService();

				expect( svc.getNamespaceAllowedPaginationModes() ).toBe( [ "full", "offset", "cursor" ] );
				expect( svc.getEntityAllowedPaginationModes( "contact" ) ).toBe( [ "full", "offset", "cursor" ] );
				expect( svc.getPaginationModesInUse() ).toBe( [ "full", "offset", "cursor" ] );
			} );

			it( "should restrict allowed pagination modes when configured for a namespace", function(){
				var svc = _getConfigService(
					  defaults = {
						  paginationMode         = "offset"
						, allowedPaginationModes = [ "offset", "cursor" ]
					  }
				);

				expect( svc.getNamespaceAllowedPaginationModes() ).toBe( [ "offset", "cursor" ] );
				expect( svc.getPaginationModesInUse() ).toBe( [ "offset", "cursor" ] );
			} );

			it( "should further restrict allowed pagination modes per entity", function(){
				var svc = _getConfigService();

				expect( svc.getEntityAllowedPaginationModes( "restricted_contact" ) ).toBe( [ "cursor" ] );
			} );

			it( "should resolve the requested pagination mode for an entity", function(){
				var svc = _getConfigService();

				expect( svc.resolvePaginationMode( "contact" ) ).toBe( "full" );
				expect( svc.resolvePaginationMode( "contact", "cursor" ) ).toBe( "cursor" );
				expect( svc.resolvePaginationMode( "cursor_contact" ) ).toBe( "cursor" );
				expect( svc.resolvePaginationMode( "cursor_contact", "offset" ) ).toBe( "offset" );
			} );

			it( "should use configured namespace defaults when the client does not specify a mode", function(){
				var svc = _getConfigService( defaults={ paginationMode="offset" } );

				expect( svc.resolvePaginationMode( "contact" ) ).toBe( "offset" );
			} );

			it( "should reject invalid or disallowed pagination modes", function(){
				var svc = _getConfigService();

				expect( function(){
					svc.resolvePaginationMode( "contact", "invalid" );
				} ).toThrow( type="dataApiPaginationMode.invalid" );

				expect( function(){
					svc.resolvePaginationMode( "restricted_contact", "full" );
				} ).toThrow( type="dataApiPaginationMode.notAllowed" );
			} );

			it( "should identify cursor pagination and total record counting behaviour", function(){
				var svc = _getConfigService();

				expect( svc.entityUsesCursorPagination( "cursor_contact" ) ).toBeTrue();
				expect( svc.entityUsesCursorPagination( "contact" ) ).toBeFalse();
				expect( svc.entityCountsTotalRecords( "contact" ) ).toBeTrue();
				expect( svc.entityCountsTotalRecords( "offset_contact" ) ).toBeFalse();
				expect( svc.paginationModeUsesCursor( "cursor" ) ).toBeTrue();
				expect( svc.paginationModeCountsTotalRecords( "full" ) ).toBeTrue();
				expect( svc.paginationModeCountsTotalRecords( "offset" ) ).toBeFalse();
			} );

			it( "should list pagination modes in use for a namespace", function(){
				var svc = _getConfigService();
				var modes = svc.getPaginationModesInUse();

				expect( ArrayFindNoCase( modes, "full" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( modes, "offset" ) ).toBeGT( 0 );
				expect( ArrayFindNoCase( modes, "cursor" ) ).toBeGT( 0 );
			} );

			it( "should validate pagination modes", function(){
				var svc = _getConfigService();

				expect( svc.isValidPaginationMode( "full" ) ).toBeTrue();
				expect( svc.isValidPaginationMode( "offset" ) ).toBeTrue();
				expect( svc.isValidPaginationMode( "cursor" ) ).toBeTrue();
				expect( svc.isValidPaginationMode( "invalid" ) ).toBeFalse();
			} );
		} );

		describe( "response type configuration", function(){
			it( "should validate and resolve response types", function(){
				var svc = _getConfigService();

				expect( svc.isValidResponseType( "record" ) ).toBeTrue();
				expect( svc.isValidResponseType( "idonly" ) ).toBeTrue();
				expect( svc.isValidResponseType( "empty" ) ).toBeTrue();
				expect( svc.validateResponseType( "invalid" ) ).toBe( "record" );
			} );

			it( "should expose response type helpers per entity", function(){
				var svc = _getConfigService();

				expect( svc.entityUseRecordResponseOnInsert( "contact" ) ).toBeTrue();
				expect( svc.entityUseIdOnlyResponseOnInsert( "contact" ) ).toBeFalse();
				expect( svc.entityUseEmptyResponseOnInsert( "contact" ) ).toBeFalse();
			} );
		} );

		describe( "field configuration", function(){
			it( "should return select fields with aliases when requested", function(){
				var svc = _getConfigService();
				var fields = svc.getSelectFields( "contact" );
				var aliases = svc.getSelectFields( "contact", true );

				expect( fields.find( "label" ) ).toBeGT( 0 );
				expect( aliases.find( "name" ) ).toBeGT( 0 );
			} );

			it( "should resolve property names and aliases", function(){
				var svc = _getConfigService();

				expect( svc.getPropertyNameFromFieldAlias( "contact", "name" ) ).toBe( "label" );
				expect( svc.getAliasForPropertyName( "test_contact", "label" ) ).toBe( "name" );
			} );

			it( "should resolve filter fields for an entity", function(){
				var svc = _getConfigService();

				expect( svc.getFilterFields( "contact" ) ).toBeArray();
			} );

			it( "should resolve field settings including aliases and renderers", function(){
				var svc = _getConfigService();
				var settings = svc.getFieldSettings( "contact" );

				expect( settings.label.alias ).toBe( "name" );
				expect( settings.is_active.renderer ).toBe( "nullableboolean" );
			} );
		} );

		describe( "queue configuration", function(){
			it( "should resolve queue settings for objects and named queues", function(){
				var svc = _getConfigService();
				var queue = svc.getQueue( "default" );

				expect( queue.pageSize ).toBe( 1 );
				expect( queue.atomicChanges ).toBeFalse();
				expect( queue.returnTotalRecords ).toBeTrue();
			} );

			it( "should list queue-enabled objects", function(){
				var svc = _getConfigService();
				var objects = svc.listQueueEnabledObjects();

				expect( ArrayFindNoCase( objects, "test_contact" ) ).toBeGT( 0 );
			} );

			it( "should report queue availability", function(){
				var svc = _getConfigService();

				expect( svc.isQueueEnabled() ).toBeTrue();
				expect( svc.isObjectQueueEnabled( "test_contact" ) ).toBeTrue();
				expect( svc.queueExists( "default" ) ).toBeTrue();
			} );
		} );

		describe( "namespace routes", function(){
			it( "should register and resolve data API routes", function(){
				var svc = _getConfigService(
					  namespaceRoutes = { myApi = { defaults={ paginationMode="cursor" } } }
				);

				expect( svc.getNamespaceForRoute( "/data/v1" ) ).toBe( "" );
				expect( svc.getNamespaceForRoute( "/myApi/v1" ) ).toBe( "myApi" );
				expect( svc.getNamespaces() ).toInclude( "myApi" );
			} );

			it( "should only expose namespace-scoped entities for that namespace", function(){
				var svc = _getConfigService(
					  namespaceRoutes = { myApi = {} }
					, activeNamespace = "myApi"
				);
				var entities = svc.getEntities( "myApi" );

				expect( entities.keyExists( "ns_contact" ) ).toBeTrue();
				expect( entities.keyExists( "contact" ) ).toBeFalse();
			} );
		} );
	}

}
