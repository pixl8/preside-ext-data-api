/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @configService.inject  dataApiConfigurationService
	 * @dataApiService.inject dataApiService
	 *
	 */
	public any function init( required any configService, required any dataApiService ) {
		_setConfigService( arguments.configService );
		_setDataApiService( arguments.dataApiService );

		return this;
	}

// PUBLIC API METHODS
	public struct function getNextQueuedItem( required string subscriber ) {
		var dao    = $getPresideObject( "data_api_queue" );
		var record = dao.selectData(
			  selectFields = [ "id", "object_name", "record_id", "operation" ]
			, filter       = { is_checked_out=false, subscriber=arguments.subscriber }
			, maxRows      = 1
			, orderBy      = "order_number"
		);

		if ( record.recordCount ) {
			var checkedOut = dao.updateData(
				  filter = { is_checked_out=false, id=record.id }
				, data   = { is_checked_out=true, check_out_date=Now() }
			);

			if ( !checkedOut ) {
				return getNextQueuedItem( argumentCollection=arguments );
			}

			var entity = _getConfigService().getObjectEntity( record.object_name );

			switch( record.operation ) {
				case "delete":
					return {
						  operation = "delete"
						, entity    = entity
						, recordId  = record.record_id
						, queueId   = record.id
					};
				break;
				case "update":
				case "insert":
					return {
						  operation = record.operation
						, entity    = entity
						, recordId  = record.record_id
						, record    = _getDataApiService().getSingleRecord( entity=entity, recordId=record.record_id, fields=[] )
						, queueId   = record.id
					};
			}
		}

		return {};
	}

	public numeric function getQueueCount( required string subscriber ) {
		return $getPresideObject( "data_api_queue" ).selectData(
			  filter  = { is_checked_out=false, subscriber=arguments.subscriber }
			, recordCountOnly = true
		);
	}


	public void function queueInsert(
		  string objectName = ""
		, string newId         = ""
	) {
		if ( objectName.len() && newId.len() && _getConfigService().objectIsApiEnabled( objectName ) ) {
			var subscribers = getSubscribers( arguments.objectName, "insert" );

			if ( subscribers.len() ) {
				var dao = $getPresideObject( "data_api_queue" );
				for( var subscriber in subscribers ) {
					dao.insertData( {
						  object_name = arguments.objectName
						, record_id   = arguments.newId
						, subscriber  = subscriber
						, operation   = "insert"
					} );
				}
			}
		}
	}

	public void function queueUpdate(
		  string objectName = ""
		, string id         = ""
	) {
		if ( objectName.len() && id.len() && _getConfigService().objectIsApiEnabled( objectName ) ) {
			var subscribers = getSubscribers( arguments.objectName, "update" );

			if ( subscribers.len() ) {
				var dao = $getPresideObject( "data_api_queue" );
				for( var subscriber in subscribers ) {
					var insertStillQueued = dao.dataExists( filter={
						  object_name    = arguments.objectName
						, record_id      = arguments.id
						, subscriber     = subscriber
						, operation      = "insert"
						, is_checked_out = true
					} );

					if ( insertStillQueued ) {
						dao.insertData( {
							  object_name = arguments.objectName
							, record_id   = arguments.id
							, subscriber  = subscriber
							, operation   = "update"
						} );
					}
				}
			}
		}
	}

	public void function queueDelete(
		  string objectName = ""
		, string id         = ""
		, any    filter     = {}
	) {
		if ( IsStruct( filter ) && filter.count() == 1 ) {
			var value = filter.id ?: filter[ "#objectName#.id" ];
			if ( !IsArray( value ) ) {
				value = ListToArray( value );
			}
			for( var id in value ) {
				queueDelete( arguments.objectName, id );
			}
			return;
		}

		if ( objectName.len() && id.len() && _getConfigService().objectIsApiEnabled( objectName ) ) {
			var subscribers = getSubscribers( arguments.objectName, "delete" );

			if ( subscribers.len() ) {
				var dao = $getPresideObject( "data_api_queue" );
				for( var subscriber in subscribers ) {
					var deletedInserts = dao.deleteData( filter = {
						  is_checked_out = false
						, subscriber     = subscriber
						, operation      = "insert"
						, object_name    = arguments.objectName
						, record_id      = arguments.id
					} );

					if ( !deletedInserts ) {
						dao.insertData( {
							  object_name = arguments.objectName
							, record_id   = arguments.id
							, subscriber  = subscriber
							, operation   = "delete"
						} );

						dao.deleteData( filter = {
							  is_checked_out = false
							, subscriber     = subscriber
							, operation      = "update"
							, object_name    = arguments.objectName
							, record_id      = arguments.id
						} );
					}
				}
			}
		}
	}

	public array function getSubscribers( required string objectName, required string operation ) {

		var currentApiUser = $getRequestContext().getRestRequestUser();
		var operationField = "";
		var subscribers    = [];

		switch( arguments.operation ) {
			case "insert":
				operationField = "subscribe_to_inserts";
			break;
			case "update":
				operationField = "subscribe_to_updates";
			break;
			case "delete":
				operationField = "subscribe_to_deletes";
			break;
		}

		if ( !operationField.len() ) {
			return [];
		}

		var defaultSubscribers = $getPresideObject( "data_api_user_settings" ).selectData(
			  selectFields = [ "user" ]
			, filter       = { "#operationField#"=true, object_name="" }
		);
		var specificSubscribers = $getPresideObject( "data_api_user_settings" ).selectData(
			  selectFields = [ "user", operationField ]
		);

		subscribers = ValueArray( defaultSubscribers.user );
		for( var subscriber in specificSubscribers ) {
			if ( subscriber[ operationField ] && !subscribers.find( subscriber.user ) ) {
				subscribers.append( subscriber.user );
			} else if ( !subscriber[ operationField ] ) {
				subscribers.delete( subscriber.user );
			}
		}

		if ( subscribers.len() && currentApiUser.len() ) {
			subscribers.delete( currentApiUser );
		}

		return subscribers;
	}


// PRIVATE HELPERS

// GETTERS AND SETTERS
	private any function _getConfigService() {
		return _configService;
	}
	private void function _setConfigService( required any configService ) {
		_configService = arguments.configService;
	}

	private any function _getDataApiService() {
		return _dataApiService;
	}
	private void function _setDataApiService( required any dataApiService ) {
		_dataApiService = arguments.dataApiService;
	}
}