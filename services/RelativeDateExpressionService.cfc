/**
 * Parses Grafana-compatible relative date expressions such as now, now-7d and now/d.
 *
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public boolean function isRelativeExpression( required string value ) {
		return ReFindNoCase( "^now($|[+\-/])", Trim( arguments.value ) ) > 0;
	}

	/**
	 * @roundDirection.hint floor (for equality / min) or ceil (for max)
	 * @referenceDate.hint  optional fixed point in time for deterministic parsing / tests
	 */
	public date function parse(
		  required string expression
		,          string roundDirection = "floor"
		,          date   referenceDate  = Now()
	) {
		var expr = Trim( arguments.expression );

		if ( !isRelativeExpression( expr ) ) {
			_throwInvalid( arguments.expression );
		}

		var rest   = Mid( expr, 4 );
		var result = arguments.referenceDate;

		if ( Len( rest ) && Left( rest, 1 ) != "/" ) {
			var offsetMatch = ReFind( "^([+-])(\d+)([smhdwMy])", rest, 1, true );

			if ( !offsetMatch.len[ 1 ] ) {
				_throwInvalid( arguments.expression );
			}

			var sign   = Mid( rest, offsetMatch.pos[ 2 ], offsetMatch.len[ 2 ] );
			var amount = Val( Mid( rest, offsetMatch.pos[ 3 ], offsetMatch.len[ 3 ] ) );
			var unit   = Mid( rest, offsetMatch.pos[ 4 ], offsetMatch.len[ 4 ] );

			if ( !_isValidUnit( unit ) ) {
				_throwInvalid( arguments.expression );
			}

			result = DateAdd( _toDateAddPart( unit ), sign == "-" ? -amount : amount, result );
			rest   = Mid( rest, offsetMatch.pos[ 1 ] + offsetMatch.len[ 1 ] );
		}

		if ( Len( rest ) ) {
			var roundMatch = ReFind( "^/([smhdwMy])$", rest, 1, true );

			if ( !roundMatch.len[ 1 ] ) {
				_throwInvalid( arguments.expression );
			}

			var roundUnit = Mid( rest, roundMatch.pos[ 2 ], roundMatch.len[ 2 ] );

			if ( !_isValidUnit( roundUnit ) ) {
				_throwInvalid( arguments.expression );
			}

			result = _roundToUnit(
				  dt        = result
				, unit      = roundUnit
				, direction = arguments.roundDirection == "ceil" ? "ceil" : "floor"
			);
		}

		return result;
	}

// PRIVATE HELPERS
	private void function _throwInvalid( required string expression ) {
		throw(
			  type    = "dataApi.relativeDate.invalid"
			, message = "Invalid relative date expression: [#arguments.expression#]"
		);
	}

	private boolean function _isValidUnit( required string unit ) {
		return ListFind( "s,m,h,d,w,M,y", arguments.unit ) > 0;
	}

	private string function _toDateAddPart( required string unit ) {
		if ( !Compare( arguments.unit, "M" ) ) {
			return "m";
		}

		switch( arguments.unit ) {
			case "s": return "s";
			case "m": return "n";
			case "h": return "h";
			case "d": return "d";
			case "w": return "ww";
			case "y": return "yyyy";
		}

		_throwInvalid( arguments.unit );
	}

	private date function _roundToUnit(
		  required date   dt
		, required string unit
		, required string direction
	) {
		var floored = _floorToUnit( arguments.dt, arguments.unit );

		if ( arguments.direction == "ceil" ) {
			return DateAdd( "s", -1, DateAdd( _toDateAddPart( arguments.unit ), 1, floored ) );
		}

		return floored;
	}

	private date function _floorToUnit( required date dt, required string unit ) {
		if ( !Compare( arguments.unit, "M" ) ) {
			return CreateDateTime( Year( arguments.dt ), Month( arguments.dt ), 1, 0, 0, 0 );
		}

		switch( arguments.unit ) {
			case "s":
				return CreateDateTime(
					  Year( arguments.dt )
					, Month( arguments.dt )
					, Day( arguments.dt )
					, Hour( arguments.dt )
					, Minute( arguments.dt )
					, Second( arguments.dt )
				);
			case "m":
				return CreateDateTime(
					  Year( arguments.dt )
					, Month( arguments.dt )
					, Day( arguments.dt )
					, Hour( arguments.dt )
					, Minute( arguments.dt )
					, 0
				);
			case "h":
				return CreateDateTime(
					  Year( arguments.dt )
					, Month( arguments.dt )
					, Day( arguments.dt )
					, Hour( arguments.dt )
					, 0
					, 0
				);
			case "d":
				return CreateDateTime(
					  Year( arguments.dt )
					, Month( arguments.dt )
					, Day( arguments.dt )
					, 0
					, 0
					, 0
				);
			case "w":
				return _floorToStartOfWeek( arguments.dt );
			case "y":
				return CreateDateTime( Year( arguments.dt ), 1, 1, 0, 0, 0 );
		}

		_throwInvalid( arguments.unit );
	}

	private date function _floorToStartOfWeek( required date dt ) {
		var dayOfWeek      = DayOfWeek( arguments.dt );
		var daysFromMonday = dayOfWeek == 1 ? 6 : dayOfWeek - 2;
		var monday         = DateAdd( "d", -daysFromMonday, arguments.dt );

		return CreateDateTime( Year( monday ), Month( monday ), Day( monday ), 0, 0, 0 );
	}

}
