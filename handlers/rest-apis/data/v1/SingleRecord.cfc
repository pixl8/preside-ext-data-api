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

		if ( !IsStruct( body ) ) {
			restResponse.setError(
				  errorCode      = 400
				, title          = "Bad request"
				, message        = "Request body did not contain expected object."
				, detail         = event.getHttpContent()
			);
			return;
		}

		var validationData          = StructCopy( body );
		    validationData.id       = recordId;
		    validationData.isUpdate = true;

		var validationResult = dataApiService.validateUpsertData(
			  entity        = entity
			, data          = validationData
			, ignoreMissing = true
			, isUpdate      = true
		);

		if ( validationResult.len() ) {
			restResponse.setError(
				  errorCode      = 422
				, title          = "Validation failure"
				, message        = "One or more fields contained validation errors. See messages for detailed validation error messages."
				, additionalInfo = { messages=validationResult }
			);
			return;
		}


		var updated = dataApiService.updateSingleRecord(
			  entity   = entity
			, recordId = recordId
			, data     = validationData
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
		var deletedCount = dataApiService.deleteSingleRecord(
			  entity   = arguments.entity
			, recordId = arguments.recordId
		);

		restResponse.setData( { deleted=deletedCount } );
	}
}
