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
		var dao       = $getPresideObject( "data_api_queue" );
		var namespace = $getRequestContext().getValue( name="dataApiNamespace", defaultValue="" );
		var record    = dao.selectData(
			  selectFields = [ "id", "object_name", "record_id", "operation" ]
			, filter       = { subscriber=arguments.subscriber, namespace=namespace }
			, maxRows      = 1
			, orderBy      = "order_number"
		);

		if ( record.recordCount ) {
			dao.updateData(
				  id   = record.id
				, data = { is_checked_out=true, check_out_date=Now() }
			);

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
		var namespace = $getRequestContext().getValue( name="dataApiNamespace", defaultValue="" );
		return $getPresideObject( "data_api_queue" ).selectData(
			  filter  = { subscriber=arguments.subscriber, namespace=namespace }
			, recordCountOnly = true
		);
	}

	public numeric function removeFromQueue( required string subscriber, required string queueId ) {
		var namespace = $getRequestContext().getValue( name="dataApiNamespace", defaultValue="" );
		return $getPresideObject( "data_api_queue" ).deleteData( filter={
			  id         = arguments.queueId
			, subscriber = arguments.subscriber
			, namespace  = namespace
		} );
	}

	public void function queueInsert(
		  string objectName = ""
		, string newId         = ""
	) {
		if ( objectName.len() && newId.len() && _getConfigService().objectIsApiEnabledInAnyNamespace( objectName ) ) {
			var namespaces = _getConfigService().getNamespaces( true );
			for( var namespace in namespaces ) {
				if ( !_getConfigService().objectIsApiEnabled( objectName, namespace ) ) {
					continue;
				}
				var subscribers = getSubscribers( arguments.objectName, "insert", namespace );

				if ( subscribers.len() ) {
					var dao = $getPresideObject( "data_api_queue" );
					for( var subscriber in subscribers ) {
						dao.insertData( {
							  object_name = arguments.objectName
							, record_id   = arguments.newId
							, subscriber  = subscriber
							, namespace   = namespace
							, operation   = "insert"
						} );
					}
				}
			}
		}
	}

	public void function queueUpdate(
		  string objectName = ""
		, string id         = ""
	) {
		if ( objectName.len() && id.len() && _getConfigService().objectIsApiEnabledInAnyNamespace( objectName ) ) {
			var namespaces = _getConfigService().getNamespaces( true );

			for( var namespace in namespaces ) {
				if ( !_getConfigService().objectIsApiEnabled( objectName, namespace ) ) {
					continue;
				}
				var subscribers = getSubscribers( arguments.objectName, "update", namespace );

				if ( subscribers.len() ) {
					var dao = $getPresideObject( "data_api_queue" );
					for( var subscriber in subscribers ) {
						var alreadyQueued = dao.dataExists( filter={
							  object_name    = arguments.objectName
							, record_id      = arguments.id
							, subscriber     = subscriber
							, namespace      = namespace
							, operation      = [ "insert", "update" ]
							, is_checked_out = false
						} );

						if ( !alreadyQueued ) {
							dao.insertData( {
								  object_name = arguments.objectName
								, record_id   = arguments.id
								, subscriber  = subscriber
								, namespace   = namespace
								, operation   = "update"
							} );
						}
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
			var value = filter.id ?: ( filter[ "#objectName#.id" ] ?: "" );
			if ( !IsArray( value ) ) {
				value = ListToArray( value );
			}
			for( var id in value ) {
				queueDelete( arguments.objectName, id );
			}
			return;
		}

		if ( objectName.len() && id.len() && _getConfigService().objectIsApiEnabledInAnyNamespace( objectName ) ) {
			var namespaces = _getConfigService().getNamespaces( true );

			for( var namespace in namespaces ) {
				if ( !_getConfigService().objectIsApiEnabled( objectName, namespace ) ) {
					continue;
				}
				var subscribers = getSubscribers( arguments.objectName, "delete", namespace );

				if ( subscribers.len() ) {
					var dao = $getPresideObject( "data_api_queue" );
					for( var subscriber in subscribers ) {
						var deletedInserts = dao.deleteData( filter = {
							  is_checked_out = false
							, subscriber     = subscriber
							, namespace      = namespace
							, operation      = "insert"
							, object_name    = arguments.objectName
							, record_id      = arguments.id
						} );

						if ( !deletedInserts ) {
							dao.insertData( {
								  object_name = arguments.objectName
								, record_id   = arguments.id
								, subscriber  = subscriber
								, namespace   = namespace
								, operation   = "delete"
							} );

							dao.deleteData( filter = {
								  is_checked_out = false
								, subscriber     = subscriber
								, namespace      = namespace
								, operation      = "update"
								, object_name    = arguments.objectName
								, record_id      = arguments.id
							} );
						}
					}
				}
			}
		}
	}

	public array function getSubscribers( required string objectName, required string operation, string namespace="" ) {

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
			, filter       = { "#operationField#"=true, object_name="", namespace=arguments.namespace }
		);
		var specificSubscribers = $getPresideObject( "data_api_user_settings" ).selectData(
			  selectFields = [ "user", operationField ]
			, filter       = { object_name=arguments.objectName, namespace=arguments.namespace }
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