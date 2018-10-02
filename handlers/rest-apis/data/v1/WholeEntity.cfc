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
	) {
		var result = dataApiService.getPaginatedRecords(
			  entity   = arguments.entity
			, page     = arguments.page
			, pageSize = arguments.pageSize
			// TODO, extra dynamic args based on the object and available filters
		);

		restResponse.setData( result.records );
		restResponse.setHeader( "X-Total-Records", result.totalCount );
		restResponse.setHeader( "X-Total-Pages", result.totalPages );

		var linkHeader      = "";
		var linkHeaderDelim = "";

		if ( result.nextPage ) {
			var nextLink = event.buildLink( linkto="api.data.v1.entity.#arguments.entity#", queryString="pageSize=#arguments.pageSize#&page=#result.nextPage#" );
			linkHeader &= "<#nextLink#>; rel=""next""";
			linkHeaderDelim = ", ";
		}
		if ( result.prevPage ) {
			var prevLink = event.buildLink( linkto="api.data.v1.entity.#arguments.entity#", queryString="pageSize=#arguments.pageSize#&page=#result.prevPage#" );
			linkHeader &= linkHeaderDelim & "<#prevLink#>; rel=""prev""";
		}

		if ( Len( linkHeader ) ) {
			restResponse.setHeader( "Link", linkHeader );
		}
	}

	private void function post( required string entity ) {
		var body = event.getHTTPContent();

		try {
			body = DeserializeJson( body );
		} catch( any e ) {
			logError( e );
			restResponse.setError(
				  errorCode = 400
				, title     = "Bad request"
				, message   = "Could not parse JSON body.."
			);
		}

		var created = dataApiService.batchCreateRecords(
			  entity = entity
			, data   = body
		);

		restResponse.setData( created );
	}

	private void function put( required string entity ) {
		var body = event.getHTTPContent();

		try {
			body = DeserializeJson( body );
		} catch( any e ) {
			logError( e );
			restResponse.setError(
				  errorCode = 400
				, title     = "Bad request"
				, message   = "Could not parse JSON body.."
			);
		}

		var updated = dataApiService.batchUpdateRecords(
			  entity = entity
			, data   = body
		);

		restResponse.setData( updated );
	}

	private void function delete( required string entity, required string recordId ) {
		var body = event.getHTTPContent();

		try {
			body = DeserializeJson( body );
		} catch( any e ) {
			logError( e );
			restResponse.setError(
				  errorCode = 400
				, title     = "Bad request"
				, message   = "Could not parse JSON body.."
			);
		}

		var deleted = dataApiService.batchDeleteRecords(
			  entity = entity
			, data   = body
		);

		restResponse.setData( deleted );
	}
}