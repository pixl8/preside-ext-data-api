/**
 * @restUri /entity/{entity}/
 *
 */
component {

	property name="dataApiService" inject="dataApiService";

	private void function get(
		  required string  entity
		,          numeric page     = 1
		,          numeric pageSize = 100
		,          string  fields   = ""
	) {
		var filters  = {};
		var filterQs = "";

		for( var paramName in rc ) {
			if ( paramName.reFindNoCase( "^filter\." ) ) {
				filters[ paramName.reReplaceNoCase( "^filter\.", "" ) ] = rc[ paramName ];
			}
		}
		var result = dataApiService.getPaginatedRecords(
			  entity   = arguments.entity
			, page     = arguments.page
			, pageSize = arguments.pageSize
			, fields   = ListToArray( arguments.fields )
			, filters  = filters
		);

		restResponse.setData( result.records );
		restResponse.setHeader( "X-Total-Records", result.totalCount );
		restResponse.setHeader( "X-Total-Pages", result.totalPages );

		var linkHeader      = "";
		var linkHeaderDelim = "";
		var handler         = event.getValue( name="dataApiHandler"  , defaultValue="data.v1" );

		if ( !isEmpty( filters ) ) {
			for ( var f in filters ) {
				filterQs &= "&filter.#f#=#filters[f]#";
			}
		}

		if ( result.nextPage ) {
			var nextLink = event.buildLink( linkto="api.#handler#.entity.#arguments.entity#", queryString="pageSize=#arguments.pageSize#&page=#result.nextPage#" );
			if ( !isEmptyString( filterQs ) ) {
				nextLink &= "#filterQs#";
			}

			linkHeader &= "<#nextLink#>; rel=""next""";
			linkHeaderDelim = ", ";
		}
		if ( result.prevPage ) {
			var prevLink = event.buildLink( linkto="api.#handler#.entity.#arguments.entity#", queryString="pageSize=#arguments.pageSize#&page=#result.prevPage#" );
			if ( !isEmptyString( filterQs ) ) {
				prevLink &= "#filterQs#";
			}

			linkHeader &= linkHeaderDelim & "<#prevLink#>; rel=""prev""";
		}

		if ( Len( linkHeader ) ) {
			restResponse.setHeader( "Link", linkHeader );
		}
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

		restResponse.setData( created );
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

		restResponse.setData( updated );
	}

}