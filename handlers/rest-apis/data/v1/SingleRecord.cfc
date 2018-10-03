/**
 * @restUri /entity/{entity}/{recordid}/
 *
 */
component {

	property name="dataApiService" inject="dataApiService";

	private void function get( required string entity, required string recordId, string fields="" ) {
		var record = dataApiService.getSingleRecord(
			  entity   = arguments.entity
			, recordId = arguments.recordId
			, fields   = ListToArray( arguments.fields )
		);

		restResponse.setData( record );

		if ( !record.count() ) {
			restResponse.setError(
				  errorCode = 404
				, title     = "Not found"
				, message   = "No [#arguments.entity#] record was found with ID [#arguments.recordId#]"
			);
		}
	}

	private void function put( required string entity, required string recordId ) {
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

		var updated = dataApiService.updateSingleRecord(
			  entity   = entity
			, recordId = recordId
			, data     = body
		);

		if ( updated ) {
			get( argumentCollection=arguments );
		} else {
			restResponse.setError(
				  errorCode = 404
				, title     = "Not found"
				, message   = "No [#arguments.entity#] record was found with ID [#arguments.recordId#]"
			);
		}
	}

	private void function delete( required string entity, required string recordId ) {
		dataApiService.deleteSingleRecord(
			  entity   = arguments.entity
			, recordId = arguments.recordId
		);

		restResponse.setData( { success=true } );
	}
}