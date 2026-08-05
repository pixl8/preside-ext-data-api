component extends="testbox.system.BaseSpec" {

	function run() {
		describe( "dataapi.properties", function(){
			it( "should load without error using the Java properties parser", function(){
				var fixtures = new tests.fixtures.DataApiTestFixtures();
				var bundle   = fixtures.loadI18nProperties();

				expect( StructCount( bundle ) ).toBeGT( 20 );
			} );

			it( "should preserve multiline pagination documentation content", function(){
				var fixtures = new tests.fixtures.DataApiTestFixtures();
				var bundle   = fixtures.loadI18nProperties();

				expect( bundle[ "trait.pagination.intro" ] ).toInclude( "paginationMode" );
				expect( bundle[ "trait.pagination.intro.single" ] ).toInclude( "paginated as described below" );
				expect( bundle[ "trait.pagination.intro.single" ] ).notToInclude( "paginationMode" );
				expect( bundle[ "trait.pagination.full.description" ] ).toInclude( "X-Total-Records" );
				expect( bundle[ "trait.pagination.full.description" ] ).toInclude( "X-Total-Pages" );
				expect( bundle[ "trait.pagination.full.description" ] ).toInclude( "pageSize" );
				expect( Len( bundle[ "trait.pagination.full.description" ] ) ).toBeGT( 200 );
			} );

			it( "should preserve multiline offset pagination documentation content", function(){
				var fixtures = new tests.fixtures.DataApiTestFixtures();
				var bundle   = fixtures.loadI18nProperties();

				expect( bundle[ "trait.pagination.offset.description" ] ).toInclude( "X-Total-Records" );
				expect( bundle[ "trait.pagination.offset.description" ] ).toInclude( "Link" );
				expect( Len( bundle[ "trait.pagination.offset.description" ] ) ).toBeGT( 100 );
			} );

			it( "should preserve multiline cursor pagination documentation content", function(){
				var fixtures = new tests.fixtures.DataApiTestFixtures();
				var bundle   = fixtures.loadI18nProperties();

				expect( bundle[ "trait.pagination.cursor.description" ] ).toInclude( "cursor" );
				expect( bundle[ "trait.pagination.cursor.description" ] ).toInclude( "forward only" );
				expect( Len( bundle[ "trait.pagination.cursor.description" ] ) ).toBeGT( 100 );
			} );

			it( "should clarify that the page parameter is ignored in cursor pagination mode", function(){
				var fixtures = new tests.fixtures.DataApiTestFixtures();
				var bundle   = fixtures.loadI18nProperties();

				expect( bundle[ "operation.get.params.page" ] ).toInclude( "cursor" );
				expect( bundle[ "operation.get.params.page" ] ).toInclude( "Ignored" );
				expect( bundle[ "operation.get.params.page.fixed" ] ).toInclude( "page number" );
				expect( bundle[ "operation.get.params.page.fixed" ] ).notToInclude( "paginationMode" );
				expect( bundle[ "operation.get.params.cursor.fixed" ] ).toInclude( "cursor" );
				expect( bundle[ "operation.get.params.cursor.fixed" ] ).notToInclude( "pagination" );
			} );

			it( "should preserve multiline error handling documentation including the JSON example", function(){
				var fixtures = new tests.fixtures.DataApiTestFixtures();
				var bundle   = fixtures.loadI18nProperties();

				expect( bundle[ "trait.errorhandling.description" ] ).toInclude( "500" );
				expect( bundle[ "trait.errorhandling.description" ] ).toInclude( "errorCode" );
				expect( bundle[ "trait.errorhandling.description" ] ).toInclude( "title" );
				expect( Len( bundle[ "trait.errorhandling.description" ] ) ).toBeGT( 200 );
			} );

			it( "should expose core API metadata keys", function(){
				var fixtures = new tests.fixtures.DataApiTestFixtures();
				var bundle   = fixtures.loadI18nProperties();

				expect( bundle[ "api.title" ] ).toBe( "Preside data API" );
				expect( bundle[ "api.version" ] ).toBe( "1.0.0" );
				expect( Len( bundle[ "api.description" ] ) ).toBeGT( 0 );
			} );
		} );
	}

}
