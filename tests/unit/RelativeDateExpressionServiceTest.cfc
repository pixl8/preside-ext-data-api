component extends="tests.BaseTest" {

	function run() {
		describe( "isRelativeExpression()", function(){
			it( "should recognise Grafana-style relative expressions", function(){
				var svc = _getService();

				expect( svc.isRelativeExpression( "now" ) ).toBeTrue();
				expect( svc.isRelativeExpression( "Now-7d" ) ).toBeTrue();
				expect( svc.isRelativeExpression( "now+1h" ) ).toBeTrue();
				expect( svc.isRelativeExpression( "now/d" ) ).toBeTrue();
				expect( svc.isRelativeExpression( "now-1d/d" ) ).toBeTrue();
			} );

			it( "should reject absolute dates and unrelated values", function(){
				var svc = _getService();

				expect( svc.isRelativeExpression( "2024-01-01" ) ).toBeFalse();
				expect( svc.isRelativeExpression( "nowhere" ) ).toBeFalse();
				expect( svc.isRelativeExpression( "" ) ).toBeFalse();
			} );
		} );

		describe( "parse()", function(){
			it( "should return the reference date for now", function(){
				var svc      = _getService();
				var refDate  = CreateDateTime( 2024, 6, 15, 14, 30, 45 );
				var resolved = svc.parse( expression="now", referenceDate=refDate );

				expect( DateCompare( resolved, refDate ) ).toBe( 0 );
			} );

			it( "should apply day hour and month offsets", function(){
				var svc     = _getService();
				var refDate = CreateDateTime( 2024, 6, 15, 14, 30, 45 );

				expect( DateCompare( svc.parse( expression="now-7d", referenceDate=refDate ), CreateDateTime( 2024, 6, 8, 14, 30, 45 ) ) ).toBe( 0 );
				expect( DateCompare( svc.parse( expression="now-1h", referenceDate=refDate ), CreateDateTime( 2024, 6, 15, 13, 30, 45 ) ) ).toBe( 0 );
				expect( DateCompare( svc.parse( expression="now+1M", referenceDate=refDate ), CreateDateTime( 2024, 7, 15, 14, 30, 45 ) ) ).toBe( 0 );
				expect( DateCompare( svc.parse( expression="now-30m", referenceDate=refDate ), CreateDateTime( 2024, 6, 15, 14, 0, 45 ) ) ).toBe( 0 );
			} );

			it( "should be case-insensitive for the now token", function(){
				var svc     = _getService();
				var refDate = CreateDateTime( 2024, 6, 15, 14, 30, 45 );

				expect( DateCompare( svc.parse( expression="Now-7d", referenceDate=refDate ), CreateDateTime( 2024, 6, 8, 14, 30, 45 ) ) ).toBe( 0 );
				expect( DateCompare( svc.parse( expression="NOW-7d", referenceDate=refDate ), CreateDateTime( 2024, 6, 8, 14, 30, 45 ) ) ).toBe( 0 );
			} );

			it( "should floor to the start of a unit", function(){
				var svc     = _getService();
				var refDate = CreateDateTime( 2024, 6, 15, 14, 30, 45 );

				expect( DateCompare( svc.parse( expression="now/d", roundDirection="floor", referenceDate=refDate ), CreateDateTime( 2024, 6, 15, 0, 0, 0 ) ) ).toBe( 0 );
				expect( DateCompare( svc.parse( expression="now/h", roundDirection="floor", referenceDate=refDate ), CreateDateTime( 2024, 6, 15, 14, 0, 0 ) ) ).toBe( 0 );
				expect( DateCompare( svc.parse( expression="now/M", roundDirection="floor", referenceDate=refDate ), CreateDateTime( 2024, 6, 1, 0, 0, 0 ) ) ).toBe( 0 );
			} );

			it( "should ceil to the end of a unit for max bounds", function(){
				var svc     = _getService();
				var refDate = CreateDateTime( 2024, 6, 15, 14, 30, 45 );

				expect( DateCompare( svc.parse( expression="now/d", roundDirection="ceil", referenceDate=refDate ), CreateDateTime( 2024, 6, 15, 23, 59, 59 ) ) ).toBe( 0 );
				expect( DateCompare( svc.parse( expression="now/h", roundDirection="ceil", referenceDate=refDate ), CreateDateTime( 2024, 6, 15, 14, 59, 59 ) ) ).toBe( 0 );
			} );

			it( "should apply offset then floor", function(){
				var svc     = _getService();
				var refDate = CreateDateTime( 2024, 6, 15, 14, 30, 45 );

				expect( DateCompare( svc.parse( expression="now-1d/d", roundDirection="floor", referenceDate=refDate ), CreateDateTime( 2024, 6, 14, 0, 0, 0 ) ) ).toBe( 0 );
			} );

			it( "should floor weeks to Monday", function(){
				var svc     = _getService();
				var saturday = CreateDateTime( 2024, 6, 15, 14, 30, 45 );

				expect( DateCompare( svc.parse( expression="now/w", roundDirection="floor", referenceDate=saturday ), CreateDateTime( 2024, 6, 10, 0, 0, 0 ) ) ).toBe( 0 );
			} );

			it( "should throw for malformed relative expressions", function(){
				var svc = _getService();

				expect( function(){
					svc.parse( expression="now-7x" );
				} ).toThrow( type="dataApi.relativeDate.invalid" );

				expect( function(){
					svc.parse( expression="now/q" );
				} ).toThrow( type="dataApi.relativeDate.invalid" );

				expect( function(){
					svc.parse( expression="now-7d/extra" );
				} ).toThrow( type="dataApi.relativeDate.invalid" );
			} );
		} );
	}

	private any function _getService() {
		return new dataApi.services.RelativeDateExpressionService();
	}

}
