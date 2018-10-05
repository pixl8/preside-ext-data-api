/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @configService.inject dataApiConfigurationService
	 *
	 */
	public any function init( required any configService ) {
		_setConfigService( arguments.configService );

		return this;
	}

// PUBLIC API METHODS
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
					dao.insertData( {
						  object_name = arguments.objectName
						, record_id   = arguments.id
						, subscriber  = subscriber
						, operation   = "delete"
					} );
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
}