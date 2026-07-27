component extends="tests.BaseTest" {

	function run() {
		describe( "i18nNamespaced()", function(){
			it( "should return the default translation when no namespace is active", function(){
				var configSvc = _getConfigService();
				var svc       = _getDataApiService( configSvc );
				var bundle    = _fixtures().loadI18nProperties();

				svc.$( "$translateResource" ).$callback( function( uri, defaultValue="", data=[] ) {
					return _fixtures().translateFromBundle( bundle, uri, defaultValue );
				} );

				expect( svc.i18nNamespaced( uri="dataapi:api.title" ) ).toBe( bundle[ "api.title" ] );
			} );

			it( "should prefer a namespaced translation when one exists", function(){
				var configSvc = _getConfigService(
					  namespaceRoutes = { myApi = {} }
					, activeNamespace = "myApi"
				);
				var svc = _getDataApiService( configSvc, "myApi" );

				svc.$( "$translateResource" ).$callback( function( uri, defaultValue="", data=[] ) {
					if ( uri == "dataapi:myApi.api.title" ) {
						return "My custom API title";
					}
					if ( uri == "dataapi:api.title" ) {
						return "Default API title";
					}
					return defaultValue;
				} );

				expect( svc.i18nNamespaced( uri="dataapi:api.title" ) ).toBe( "My custom API title" );
			} );

			it( "should fall back to the default translation when the namespaced key is missing", function(){
				var configSvc = _getConfigService(
					  namespaceRoutes = { myApi = {} }
					, activeNamespace = "myApi"
				);
				var svc = _getDataApiService( configSvc, "myApi" );

				svc.$( "$translateResource" ).$callback( function( uri, defaultValue="", data=[] ) {
					if ( uri == "dataapi:myApi.api.title" ) {
						return "";
					}
					if ( uri == "dataapi:api.title" ) {
						return "Default API title";
					}
					return defaultValue;
				} );

				expect( svc.i18nNamespaced( uri="dataapi:api.title" ) ).toBe( "Default API title" );
			} );
		} );

		describe( "onRestRequest()", function(){
			it( "should allow requests to enabled entities with supported verbs", function(){
				var configSvc    = _getConfigService();
				var svc          = _getDataApiService( configSvc );
				var state        = {};
				var restRequest  = _mockRestRequest( { uri="/entity/contact/", verb="get" }, state );
				var restResponse = _mockRestResponse( state );

				svc.onRestRequest( restRequest, restResponse );

				expect( state.finished ?: 0 ).toBe( 0 );
			} );

			it( "should finish with 404 for unknown entities", function(){
				var configSvc    = _getConfigService();
				var svc          = _getDataApiService( configSvc, "", {}, { entity="unknown" } );
				var state        = {};
				var restRequest  = _mockRestRequest( { uri="/entity/unknown/", verb="get" }, state );
				var restResponse = _mockRestResponse( state );

				svc.onRestRequest( restRequest, restResponse );

				expect( state.status ?: 0 ).toBe( 1 );
				expect( state.finished ?: 0 ).toBe( 1 );
			} );

			it( "should return 405 for unsupported verbs", function(){
				var configSvc    = _getConfigService();
				var svc          = _getDataApiService( configSvc, "", {}, { entity="readonly_contact" } );
				var state        = {};
				var restRequest  = _mockRestRequest( { uri="/entity/readonly_contact/", verb="post" }, state );
				var restResponse = _mockRestResponse( state );

				svc.onRestRequest( restRequest, restResponse );

				expect( state.error ?: 0 ).toBe( 1 );
				expect( state.finished ?: 0 ).toBe( 1 );
			} );

			it( "should ignore documentation and queue routes", function(){
				var configSvc    = _getConfigService();
				var svc          = _getDataApiService( configSvc );
				var state        = {};
				var restRequest  = _mockRestRequest( { uri="/docs/spec/" }, state );
				var restResponse = _mockRestResponse( state );

				svc.onRestRequest( restRequest, restResponse );

				expect( state.status ?: 0 ).toBe( 0 );
				expect( state.finished ?: 0 ).toBe( 0 );
			} );
		} );

		describe( "getPaginatedRecords()", function(){
			it( "should return total counts for full pagination mode", function(){
				var configSvc = _getConfigService();
				var svc       = _getDataApiService( configSvc );
				var dao       = _sequentialSelectDataMock( [
					  [ { id=CreateUUID(), label="One", datemodified=Now(), datecreated=Now(), is_active=true, status="" } ]
					, 5
				] );

				svc.$( "$getPresideObject" ).$args( "test_contact" ).$results( dao );

				var result = svc.getPaginatedRecords(
					  entity   = "contact"
					, page     = 1
					, pageSize = 2
					, fields   = []
					, filters  = {}
				);

				expect( result.totalCount ).toBe( 5 );
				expect( result.totalPages ).toBe( 3 );
				expect( result.nextPage ).toBe( 2 );
				expect( ArrayLen( result.records ) ).toBe( 1 );
			} );

			it( "should omit total counts for offset pagination mode", function(){
				var configSvc = _getConfigService();
				var svc       = _getDataApiService( configSvc );
				var dao       = _mockPresideObject( "offset_contact" );
				var records   = [
					  { id=CreateUUID(), label="One" }
					, { id=CreateUUID(), label="Two" }
					, { id=CreateUUID(), label="Three" }
				];

				dao.$( "selectData" ).$results( records );
				svc.$( "$getPresideObject" ).$args( "offset_contact" ).$results( dao );

				var result = svc.getPaginatedRecords(
					  entity   = "offset_contact"
					, page     = 1
					, pageSize = 2
					, fields   = []
					, filters  = {}
				);

				expect( result ).notToHaveKey( "totalCount" );
				expect( result ).notToHaveKey( "totalPages" );
				expect( ArrayLen( result.records ) ).toBe( 2 );
				expect( result.nextPage ).toBe( 2 );
			} );

			it( "should honour a requested pagination mode override", function(){
				var configSvc = _getConfigService();
				var svc       = _getDataApiService( configSvc );
				var dao       = _sequentialSelectDataMock( [
					  [ { id=CreateUUID(), label="One", datemodified=Now(), datecreated=Now(), is_active=true, status="" } ]
					, 5
				] );

				svc.$( "$getPresideObject" ).$args( "test_contact" ).$results( dao );

				var result = svc.getPaginatedRecords(
					  entity         = "contact"
					, page           = 1
					, pageSize       = 2
					, fields         = []
					, filters        = {}
					, paginationMode = "full"
				);

				expect( result.totalCount ).toBe( 5 );
				expect( result.totalPages ).toBe( 3 );

				dao = _mockPresideObject( "test_contact" );
				dao.$( "selectData" ).$results( [
					  { id=CreateUUID(), label="One" }
					, { id=CreateUUID(), label="Two" }
					, { id=CreateUUID(), label="Three" }
				] );
				svc.$( "$getPresideObject" ).$args( "test_contact" ).$results( dao );

				result = svc.getPaginatedRecords(
					  entity         = "contact"
					, page           = 1
					, pageSize       = 2
					, fields         = []
					, filters        = {}
					, paginationMode = "offset"
				);

				expect( result ).notToHaveKey( "totalCount" );
				expect( result ).notToHaveKey( "totalPages" );
				expect( ArrayLen( result.records ) ).toBe( 2 );
			} );
		} );

		describe( "getCursorRecords()", function(){
			it( "should return records and a next cursor when more data is available", function(){
				var configSvc = _getConfigService();
				var svc       = _getDataApiService( configSvc );
				var dao       = _mockPresideObject( "cursor_contact" );
				var records   = [
					  { id="1", label="One", datemodified=Now(), __cursor_sort_value=Now() }
					, { id="2", label="Two", datemodified=Now(), __cursor_sort_value=Now() }
					, { id="3", label="Three", datemodified=Now(), __cursor_sort_value=Now() }
				];

				dao.$( "selectData" ).$results( records );
				svc.$( "$getPresideObject" ).$args( "cursor_contact" ).$results( dao );

				var result = svc.getCursorRecords(
					  entity   = "cursor_contact"
					, pageSize = 2
					, fields   = []
					, filters  = {}
				);

				expect( ArrayLen( result.records ) ).toBe( 2 );
				expect( Len( result.nextCursor ) ).toBeGT( 0 );
			} );

			it( "should reject invalid cursors", function(){
				var configSvc = _getConfigService();
				var svc       = _getDataApiService( configSvc );
				var dao       = _mockPresideObject( "cursor_contact" );

				dao.$( "selectData" ).$results( [] );
				svc.$( "$getPresideObject" ).$args( "cursor_contact" ).$results( dao );

				expect( function(){
					svc.getCursorRecords(
						  entity   = "cursor_contact"
						, pageSize = 10
						, fields   = []
						, cursor   = "not-a-valid-cursor"
						, filters  = {}
					);
				} ).toThrow( type="dataApiCursor.invalid" );
			} );
		} );

		describe( "validateUpsertData()", function(){
			it( "should skip validation when configured to do so", function(){
				var configSvc = _getConfigService();
				var svc       = _getDataApiService( configSvc );

				var result = svc.validateUpsertData(
					  entity = "contact"
					, data   = { name="Test" }
				);

				expect( result ).toBe( [] );
			} );

			it( "should validate arrays of records", function(){
				var configSvc = _getConfigService();
				var svc       = _getDataApiService( configSvc );

				var result = svc.validateUpsertData(
					  entity = "contact"
					, data   = [ { name="One" }, { name="Two" } ]
				);

				expect( result.validated ).toBeTrue();
				expect( ArrayLen( result.validationResults ) ).toBe( 2 );
			} );
		} );

		describe( "createRecord() and updateSingleRecord()", function(){
			it( "should return the created record by default", function(){
				var configSvc = _getConfigService();
				var svc       = _getDataApiService( configSvc );
				var dao       = _mockPresideObject( "test_contact" );
				var newId     = CreateUUID();

				dao.$( "insertData" ).$results( newId );
				dao.$( "selectData" ).$results( [ { id=newId, label="Created", datemodified=Now(), datecreated=Now(), is_active=true, status="" } ] );
				svc.$( "$getPresideObject" ).$args( "test_contact" ).$results( dao );

				var result = svc.createRecord( entity="contact", record={ name="Created" } );

				expect( result.id ).toBe( newId );
				expect( result.name ).toBe( "Created" );
			} );

			it( "should honour empty response type configuration on update", function(){
				var configSvc = _getConfigService();
				var svc       = _getDataApiService( configSvc );
				var dao       = _mockPresideObject( "test_contact" );

				dao.$( "updateData" ).$results( 1 );
				svc.$( "$getPresideObject" ).$args( "test_contact" ).$results( dao );

				svc.$( "$announceInterception" ).$callback( function( point, data ) {
					if ( point == "preDataApiUpdateData" ) {
						data.responseType = "empty";
					}
				} );

				var result = svc.updateSingleRecord(
					  entity         = "contact"
					, data           = { name="Updated" }
					, recordId       = CreateUUID()
					, returnResponse = true
				);

				expect( result ).toBe( "" );
			} );
		} );

		describe( "date filter resolution", function(){
			it( "should resolve relative date expressions in min and max filters", function(){
				var configSvc    = _getConfigService();
				var svc          = _getDataApiService( configSvc );
				var capturedArgs = [];
				var dao          = _mockPresideObject( "test_contact" );

				dao.$( "selectData" ).$callback( function() {
					ArrayAppend( capturedArgs, Duplicate( arguments ) );
					if ( ArrayLen( capturedArgs ) == 1 ) {
						return [ { id=CreateUUID(), label="One", datemodified=Now(), datecreated=Now(), is_active=true, status="" } ];
					}
					return 1;
				} );
				svc.$( "$getPresideObject" ).$args( "test_contact" ).$results( dao );

				svc.getPaginatedRecords(
					  entity   = "contact"
					, page     = 1
					, pageSize = 10
					, fields   = []
					, filters  = { "datemodified.min"="now-7d", "datemodified.max"="now" }
				);

				expect( ArrayLen( capturedArgs ) ).toBeGT( 0 );
				expect( ArrayLen( capturedArgs[ 1 ].extraFilters ?: [] ) ).toBe( 2 );

				var minValue = capturedArgs[ 1 ].extraFilters[ 1 ].filterParams.datemodified__min.value;
				var maxValue = capturedArgs[ 1 ].extraFilters[ 2 ].filterParams.datemodified__max.value;

				expect( minValue ).notToBe( "now-7d" );
				expect( maxValue ).notToBe( "now" );
				expect( IsDate( minValue ) ).toBeTrue();
				expect( IsDate( maxValue ) ).toBeTrue();
				expect( Abs( DateDiff( "s", ParseDateTime( minValue ), DateAdd( "d", -7, Now() ) ) ) ).toBeLTE( 2 );
				expect( Abs( DateDiff( "s", ParseDateTime( maxValue ), Now() ) ) ).toBeLTE( 2 );
			} );

			it( "should leave absolute date filter values unchanged", function(){
				var configSvc    = _getConfigService();
				var svc          = _getDataApiService( configSvc );
				var capturedArgs = [];
				var dao          = _mockPresideObject( "test_contact" );

				dao.$( "selectData" ).$callback( function() {
					ArrayAppend( capturedArgs, Duplicate( arguments ) );
					if ( ArrayLen( capturedArgs ) == 1 ) {
						return [ { id=CreateUUID(), label="One", datemodified=Now(), datecreated=Now(), is_active=true, status="" } ];
					}
					return 1;
				} );
				svc.$( "$getPresideObject" ).$args( "test_contact" ).$results( dao );

				svc.getPaginatedRecords(
					  entity   = "contact"
					, page     = 1
					, pageSize = 10
					, fields   = []
					, filters  = { "datemodified.min"="2024-01-01" }
				);

				expect( ArrayLen( capturedArgs ) ).toBeGT( 0 );
				expect( capturedArgs[ 1 ].extraFilters[ 1 ].filterParams.datemodified__min.value ).toBe( "2024-01-01" );
			} );

			it( "should throw for invalid relative date expressions", function(){
				var configSvc = _getConfigService();
				var svc       = _getDataApiService( configSvc );
				var dao       = _mockPresideObject( "test_contact" );

				svc.$( "$getPresideObject" ).$args( "test_contact" ).$results( dao );

				expect( function(){
					svc.getPaginatedRecords(
						  entity   = "contact"
						, page     = 1
						, pageSize = 10
						, fields   = []
						, filters  = { "datemodified.min"="now-7x" }
					);
				} ).toThrow( type="dataApi.relativeDate.invalid" );
			} );
		} );
	}

}
