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
	public struct function getNextQueuedItems( required string subscriber, required string queueName ) {
		var dao           = $getPresideObject( "data_api_queue" );
		var namespace     = $getRequestContext().getValue( name="dataApiNamespace", defaultValue="" );
		var configSvc     = _getConfigService();
		var apiSvc        = _getDataApiService();
		var queueSettings = configSvc.getQueue( queueName, namespace );
		var returnStruct  = {
			  queueSize = getQueueCount( arguments.subscriber, arguments.queueName  )
			, data      = []
		};
		var records       = dao.selectData(
			  selectFields = [ "id", "object_name", "record_id", "operation", "data", "dateCreated" ]
			, filter       = { subscriber=arguments.subscriber, namespace=namespace, queue_name=arguments.queueName }
			, maxRows      = Val( queueSettings.pageSize ?: 1 )
			, orderBy      = "order_number"
		);

		if ( records.recordCount ) {
			dao.updateData(
				  filter = { id=ValueArray( records.id ) }
				, data = { is_checked_out=true, check_out_date=Now() }
			);

			for( var record in records ) {
				var entity = configSvc.getObjectEntity( record.object_name );

				switch( record.operation ) {
					case "delete":
						returnStruct.data.append( {
							  operation = "delete"
							, entity    = entity
							, recordId  = record.record_id
							, queueId   = record.id
							, timestamp = _unixTimestamp( record.dateCreated )
						} );
					break;
					case "update":
					case "insert":
						var dataEntry = {
							  operation = record.operation
							, entity    = entity
							, recordId  = record.record_id
							, queueId   = record.id
							, timestamp = _unixTimestamp( record.dateCreated )
						};
						if ( queueSettings.atomicChanges && Len( Trim( record.data ) ) ) {
							try {
								dataEntry.record = _aliasFields( record.object_name, DeserializeJson( record.data ) );
							} catch( any e ) {
								dataEntry.record = record.data;
							}
						} else {
							dataEntry.record = apiSvc.getSingleRecord( entity=entity, recordId=record.record_id, fields=[] )
						}
						returnStruct.data.append( dataEntry );
				}
			}
		}

		if ( queueSettings.pageSize == 1 ) {
			returnStruct.data = returnStruct.data[ 1 ] ?: {};
		}

		return returnStruct;
	}

	public numeric function getQueueCount( required string subscriber, required string queueName ) {
		var namespace = $getRequestContext().getValue( name="dataApiNamespace", defaultValue="" );
		return $getPresideObject( "data_api_queue" ).selectData(
			  filter  = { subscriber=arguments.subscriber, namespace=namespace, queue_name=arguments.queueName }
			, recordCountOnly = true
		);
	}

	public numeric function removeFromQueue( required string subscriber, required array queueIds, required string queueName ) {
		var namespace = $getRequestContext().getValue( name="dataApiNamespace", defaultValue="" );
		return $getPresideObject( "data_api_queue" ).deleteData( filter={
			  id         = arguments.queueIds
			, subscriber = arguments.subscriber
			, namespace  = namespace
			, queue_name = arguments.queueName
		} );
	}

	public void function queueInsert(
		  string objectName = ""
		, string newId      = ""
		, struct data       = {}
	) {
		if ( Len( objectName ) && Len( newId ) && _getConfigService().objectIsApiEnabledInAnyNamespace( objectName ) ) {
			var configService = _getConfigService();
			var namespaces = configService.getNamespaces( true );

			for( var namespace in namespaces ) {
				if ( !configService.objectIsApiEnabled( objectName, namespace ) || !configService.isObjectQueueEnabled( objectName, namespace ) ) {
					continue;
				}

				var subscribers  = getSubscribers( arguments.objectName, "insert", namespace );
				if ( subscribers.len() ) {
					var objEntity = configService.getObjectEntity( arguments.objectName, namespace );
					var savedFilters = configService.getSavedFilters( objEntity, namespace );

					if ( savedFilters.len() && !$getPresideObject( objectName ).dataExists( id=newId, savedFilters=savedFilters ) ) {
						continue;
					}

					var queueSettings = configService.getQueueForObject( objectName, namespace );
					var dao = $getPresideObject( "data_api_queue" );
					for( var subscriber in subscribers ) {
						dao.insertData( {
							  object_name = arguments.objectName
							, record_id   = arguments.newId
							, queue_name  = queueSettings.name
							, subscriber  = subscriber
							, namespace   = namespace
							, operation   = "insert"
							, data        = queueSettings.atomicChanges ? SerializeJson( arguments.data ) : ""
						} );
					}
				}
			}
		}
	}

	public void function queueUpdate(
		  string objectName  = ""
		, string id          = ""
		, struct changedData = {}
	) {
		var configService = _getConfigService();
		if ( objectName.len() && changedData.count() && configService.objectIsApiEnabledInAnyNamespace( objectName ) ) {
			var actualChanges = {};

			for( var recordId in arguments.changedData ) {
				if ( arguments.changedData[ recordId ].count() ) {
					actualChanges[ recordId ] = arguments.changedData[ recordId ];
				}
			}

			if ( !actualChanges.count() ) {
				return;
			}

			var namespaces = configService.getNamespaces( true );

			for( var namespace in namespaces ) {
				if ( !configService.objectIsApiEnabled( objectName, namespace ) || !configService.isObjectQueueEnabled( objectName, namespace ) ) {
					continue;
				}
				var subscribers = getSubscribers( arguments.objectName, "update", namespace );

				if ( subscribers.len() ) {
					var queueSettings = configService.getQueueForObject( objectName, namespace );
					var dao = $getPresideObject( "data_api_queue" );
					var objDao = $getPresideObject( objectName );
					var objEntity = configService.getObjectEntity( objectName, namespace );
					var savedFilters = configService.getSavedFilters( objEntity, namespace );

					for( var subscriber in subscribers ) {
						for( var recordId in actualChanges ) {
							if ( savedFilters.len() && !objDao.dataExists( id=recordId, savedFilters=savedFilters ) ) {
								continue;
							}

							var alreadyQueued = !queueSettings.atomicChanges && dao.dataExists( filter={
								  object_name    = arguments.objectName
								, queue_name     = queueSettings.name
								, record_id      = recordId
								, subscriber     = subscriber
								, namespace      = namespace
								, operation      = [ "insert", "update" ]
								, is_checked_out = false
							} );

							if ( !alreadyQueued ) {
								dao.insertData( {
									  object_name = arguments.objectName
									, queue_name  = queueSettings.name
									, record_id   = recordId
									, subscriber  = subscriber
									, namespace   = namespace
									, operation   = "update"
									, data        = queueSettings.atomicChanges ? SerializeJson( actualChanges[ recordId ] ) : ""
								} );
							}
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
		var configService = _getConfigService();

		if ( objectName.len() && Len( id ) && configService.objectIsApiEnabledInAnyNamespace( objectName ) ) {
			var namespaces = configService.getNamespaces( true );

			for( var namespace in namespaces ) {
				if ( !configService.objectIsApiEnabled( objectName, namespace ) || !configService.isObjectQueueEnabled( objectName, namespace ) ) {
					continue;
				}
				var subscribers = getSubscribers( arguments.objectName, "delete", namespace );

				if ( subscribers.len() ) {
					var queueSettings = configService.getQueueForObject( objectName, namespace );
					var dao = $getPresideObject( "data_api_queue" );
					for( var subscriber in subscribers ) {
						var deletedInserts = !queueSettings.atomicChanges && dao.deleteData( filter = {
							  is_checked_out = false
							, subscriber     = subscriber
							, namespace      = namespace
							, queue_name     = queueSettings.name
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
								, queue_name  = queueSettings.name
								, operation   = "delete"
							} );

							if ( !queueSettings.atomicChanges ) {
								dao.deleteData( filter = {
									  is_checked_out = false
									, subscriber     = subscriber
									, namespace      = namespace
									, queue_name     = queueSettings.name
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
	}

	public boolean function queueRequired( string objectName="", ) {
		return ( objectName.len() && _getConfigService().objectIsApiEnabledInAnyNamespace( objectName ) );
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
	private numeric function _unixTimestamp( required string theDate ) {
		if ( IsDate( arguments.thedate ) ) {
			return dateDiff( 's', '1970-01-01', arguments.theDate );
		}

		return 0;
	}

	private struct function _aliasFields( required string objectName, required struct data ) {
		var aliased = {};
		var configService = _getConfigService();
		for( var key in arguments.data ) {
			var alias = configService.getAliasForPropertyName( arguments.objectName, key );
			aliased[ alias ] = arguments.data[ key ];
		}

		return aliased;
	}

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