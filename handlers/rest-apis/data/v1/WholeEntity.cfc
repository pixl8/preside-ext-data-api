/**
 * @restUri /entity/{entity}/
 *
 */
component {

	property name="dataApiService"              inject="dataApiService";
	property name="dataApiConfigurationService" inject="dataApiConfigurationService";

	private void function get(
		  required string  entity
		,          numeric page           = 1
		,          numeric pageSize       = 100
		,          string  fields         = ""
		,          string  cursor         = ""
		,          string  paginationMode = ""
	) {
		var filters  = {};
		var filterQs = "";
		var handler  = event.getValue( name="dataApiHandler", defaultValue="data.v1" );
		var resolvedPaginationMode = "";

		for( var paramName in rc ) {
			if ( paramName.reFindNoCase( "^filter\." ) ) {
				filters[ paramName.reReplaceNoCase( "^filter\.", "" ) ] = rc[ paramName ];
			}
		}

		if ( !isEmpty( filters ) ) {
			for ( var f in filters ) {
				filterQs &= "&filter.#f#=#filters[f]#";
			}
		}

		try {
			resolvedPaginationMode = dataApiConfigurationService.resolvePaginationMode(
				  entity        = arguments.entity
				, requestedMode = arguments.paginationMode
			);
		} catch( "dataApiPaginationMode.invalid dataApiPaginationMode.notAllowed" e ) {
			restResponse.setError(
				  errorCode = 400
				, title     = "Bad request"
				, message   = e.message
			);
			return;
		}

		if ( dataApiConfigurationService.paginationModeUsesCursor( resolvedPaginationMode ) ) {
			_getCursorPage(
				  argumentCollection = arguments
				, entity             = arguments.entity
				, pageSize           = arguments.pageSize
				, fields             = arguments.fields
				, cursor             = arguments.cursor
				, filters            = filters
				, filterQs           = filterQs
				, handler            = handler
				, paginationMode     = resolvedPaginationMode
			);
			return;
		}

		try {
			var result = dataApiService.getPaginatedRecords(
				  entity         = arguments.entity
				, page           = arguments.page
				, pageSize       = arguments.pageSize
				, fields         = ListToArray( arguments.fields )
				, filters        = filters
				, paginationMode = resolvedPaginationMode
			);
		} catch( "dataApi.relativeDate.invalid" e ) {
			restResponse.setError(
				  errorCode = 400
				, title     = "Bad request"
				, message   = e.message
			);
			return;
		}

		restResponse.setData( result.records );

		if ( StructKeyExists( result, "totalCount" ) ) {
			restResponse.setHeader( "X-Total-Records", result.totalCount );
		}
		if ( StructKeyExists( result, "totalPages" ) ) {
			restResponse.setHeader( "X-Total-Pages", result.totalPages );
		}

		var linkHeader      = "";
		var linkHeaderDelim = "";
		var paginationQs    = _paginationQueryString( resolvedPaginationMode );

		if ( result.nextPage ) {
			var nextLink = event.buildLink( linkto="api.#handler#.entity.#arguments.entity#", queryString="#paginationQs#&pageSize=#arguments.pageSize#&page=#result.nextPage#" );
			if ( !isEmptyString( filterQs ) ) {
				nextLink &= "#filterQs#";
			}

			linkHeader &= "<#nextLink#>; rel=""next""";
			linkHeaderDelim = ", ";
		}
		if ( result.prevPage ) {
			var prevLink = event.buildLink( linkto="api.#handler#.entity.#arguments.entity#", queryString="#paginationQs#&pageSize=#arguments.pageSize#&page=#result.prevPage#" );
			if ( !isEmptyString( filterQs ) ) {
				prevLink &= "#filterQs#";
			}

			linkHeader &= linkHeaderDelim & "<#prevLink#>; rel=""prev""";
		}

		if ( Len( linkHeader ) ) {
			restResponse.setHeader( "Link", linkHeader );
		}
	}

	private void function _getCursorPage(
		  required string  entity
		, required numeric pageSize
		, required string  fields
		, required string  cursor
		, required struct  filters
		, required string  filterQs
		, required string  handler
		, required string  paginationMode
		, required any     restResponse
	) {
		var result = "";

		try {
			result = dataApiService.getCursorRecords(
				  entity   = arguments.entity
				, pageSize = arguments.pageSize
				, fields   = ListToArray( arguments.fields )
				, cursor   = arguments.cursor
				, filters  = arguments.filters
			);
		} catch( "dataApiCursor.invalid" e ) {
			restResponse.setError(
				  errorCode = 400
				, title     = "Bad request"
				, message   = e.message
			);
			return;
		} catch( "dataApi.relativeDate.invalid" e ) {
			restResponse.setError(
				  errorCode = 400
				, title     = "Bad request"
				, message   = e.message
			);
			return;
		}

		restResponse.setData( result.records );

		if ( Len( result.nextCursor ) ) {
			var paginationQs = _paginationQueryString( arguments.paginationMode );
			var nextLink     = event.buildLink( linkto="api.#arguments.handler#.entity.#arguments.entity#", queryString="#paginationQs#&pageSize=#arguments.pageSize#&cursor=#URLEncodedFormat( result.nextCursor )#" );
			if ( !isEmptyString( arguments.filterQs ) ) {
				nextLink &= "#arguments.filterQs#";
			}

			restResponse.setHeader( "Link", "<#nextLink#>; rel=""next""" );
		}
	}

	private string function _paginationQueryString( required string paginationMode ) {
		return "paginationMode=#arguments.paginationMode#";
	}

	private void function post( required string entity ) {
		var body = event.getHttpContent();

		try {
			body = DeserializeJson( body );
		} catch( any e ) {
			logError( e );
			restResponse.setError(
				  errorCode = 400
				, title     = "Bad request"
				, message   = "Could not parse JSON body.."
			);
			return;
		}

		var validationResult = dataApiService.validateUpsertData(
			  entity        = entity
			, data          = body
			, ignoreMissing = false
		);

		if ( IsArray( body ) ) {
			if ( !validationResult.validated ) {
				restResponse.setError(
					  errorCode      = 422
					, title          = "Validation failure"
					, message        = "One or more fields contained validation errors. See records key for detailed validation error messages."
					, additionalInfo = { records=validationResult.validationResults }
				);
				return;
			}
		} else if ( validationResult.len() ) {
			restResponse.setError(
				  errorCode      = 422
				, title          = "Validation failure"
				, message        = "One or more fields contained validation errors. See messages for detailed validation error messages."
				, additionalInfo = { messages=validationResult }
			);
			return;
		}

		var created = dataApiService.createRecords(
			  entity  = entity
			, records = IsArray( body ) ? body : [ body ]
		);

		if ( IsArray( created ) ) {
			restResponse.setData( created );
		} else {
			restResponse.noData();
		}
	}

	private void function put( required string entity ) {
		var body = event.getHttpContent();

		try {
			body = DeserializeJson( body );
		} catch( any e ) {
			logError( e );
			restResponse.setError(
				  errorCode = 400
				, title     = "Bad request"
				, message   = "Could not parse JSON body.."
			);
			return;
		}

		if ( !IsArray( body ) ) {
			restResponse.setError(
				  errorCode      = 400
				, title          = "Bad request"
				, message        = "Request body did not contain an array of objects."
				, detail         = event.getHttpContent()
			);
			return;
		}

		var validationResult = dataApiService.validateUpsertData(
			  entity        = entity
			, data          = body
			, ignoreMissing = true
			, isUpdate      = true
		);

		if ( !validationResult.validated ) {
			restResponse.setError(
				  errorCode      = 422
				, title          = "Validation failure"
				, message        = "One or more fields contained validation errors. See records key for detailed validation error messages."
				, additionalInfo = { records=validationResult.validationResults }
			);
			return;
		}

		var updated = dataApiService.batchUpdateRecords(
			  entity  = entity
			, records = body
		);

		if ( IsArray( updated ) ) {
			restResponse.setData( updated );
		} else {
			restResponse.noData();
		}
	}
}
