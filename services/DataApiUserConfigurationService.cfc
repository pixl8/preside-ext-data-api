/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @apiConfigService.inject dataApiConfigurationService
	 *
	 */
	public any function init( required any apiConfigService ) {
		_setApiConfigService( arguments.apiConfigService );

		return this;
	}

// PUBLIC API METHODS
	public array function listUsersWithApiAccess( required string apiEndpoint ) {
		var namespace = _getApiConfigService().getNamespaceForRoute( arguments.apiEndpoint );
		var users     = [];
		var usersWithAnyAccess = $getPresideObject( "rest_user_api_access" ).selectData(
			  filter       = { api=arguments.apiEndpoint }
			, selectFields = [ "rest_user.id", "rest_user.name" ]
			, orderBy      = "rest_user.name"
		);
		var queueAccess = $getPresideObject( "data_api_user_settings" ).selectData(
			  selectFields = [ "user" ]
			, filter       = "namespace = :namespace and ( subscribe_to_deletes = 1 or subscribe_to_updates = 1 or subscribe_to_inserts = 1 )"
			, filterParams = { namespace=namespace }
 		);

 		for( var usr in usersWithAnyAccess ) {
 			var userWithApiAccess = {
 				  id          = usr.id
 				, name        = usr.name
 				, queueAccess = false
 			};

			for( var record in queueAccess ) {
				if ( record.user == usr.id ) {
 					userWithApiAccess.queueAccess = true;
 					break;
 				}
			}

 			users.append( userWithApiAccess );
 		}

 		return users;
	}

	public void function revokeAccess( required string userId, required string api ) {
		var namespace = _getApiConfigService().getNamespaceForRoute( arguments.api );

		$getPresideObject( "rest_user_api_access" ).deleteData( filter={ api=arguments.api, rest_user=arguments.userId } );
		$getPresideObject( "data_api_user_settings" ).deleteData( filter={ namespace=namespace, user=arguments.userId } );
	}

	public void function saveUserAccess( required string api, required string userId, required struct rules ){
		var apiConfigService = _getApiConfigService();
		var namespace        = apiConfigService.getNamespaceForRoute( api );
		var entities         = StructKeyArray( apiConfigService.getEntities( namespace ) );
		var hasAnyAccess     = false;
		var accessRecords    = [];
		var restAccessDao    = $getPresideObject( "rest_user_api_access" );
		var dataApiAccessDao = $getPresideObject( "data_api_user_settings" );

		if( !entities.len() ) {
			entities = [ "all" ];
		}

		for( var entity in entities ) {
			var accessRecord = {
				  user                 = arguments.userId
				, namespace            = namespace
				, object_name          = ( entity == "all" ? "" : apiConfigService.getEntityObject( entity, namespace ) )
				, get_allowed          = _isTrue( arguments.rules[ "#entity#_read"         ] ?: "" )
				, post_allowed         = _isTrue( arguments.rules[ "#entity#_insert"       ] ?: "" )
				, put_allowed          = _isTrue( arguments.rules[ "#entity#_update"       ] ?: "" )
				, delete_allowed       = _isTrue( arguments.rules[ "#entity#_delete"       ] ?: "" )
				, subscribe_to_inserts = _isTrue( arguments.rules[ "#entity#_queue_insert" ] ?: "" )
				, subscribe_to_updates = _isTrue( arguments.rules[ "#entity#_queue_update" ] ?: "" )
				, subscribe_to_deletes = _isTrue( arguments.rules[ "#entity#_queue_delete" ] ?: "" )
			};

			accessRecord.access_allowed = accessRecord.get_allowed || accessRecord.post_allowed || accessRecord.put_allowed || accessRecord.delete_allowed || accessRecord.subscribe_to_inserts || accessRecord.subscribe_to_updates || accessRecord.subscribe_to_deletes;
			if ( accessRecord.access_allowed ) {
				accessRecords.append( accessRecord );
			}

			hasAnyAccess = hasAnyAccess || accessRecord.access_allowed;
		}

		if ( !hasAnyAccess ) {
			revokeAccess( arguments.userId, arguments.api );
			return;
		}

		if ( !restAccessDao.dataExists( filter={ api=arguments.api, rest_user=arguments.userId } ) ) {
			restAccessDao.insertData( {
				  rest_user = arguments.userId
				, api       = arguments.api
			} );
		}

		transaction {
			dataApiAccessDao.deleteData( filter={ user=arguments.userId, namespace=namespace } );
			for( var accessRecord in accessRecords ) {
				dataApiAccessDao.insertData( accessRecord );
			}
		}

	}

	public struct function getExistingAccessDetailsForFormControl( required string api, required string userId ) {
		var accessDetails = {};
		var hasDefaultAccess = false;
		var apiConfigService = _getApiConfigService();
		var namespace = apiConfigService.getNamespaceForRoute( arguments.api );
		var entities  = StructKeyArray( apiConfigService.getEntities( namespace ) );
		var settings = $getPresideObject( "data_api_user_settings" ).selectData( filter={
			  namespace = namespace
			, user      = arguments.userId
		} );
		var globalConfigOnly = !settings.recordCount || ( settings.recordCount == 1 && settings.object_name == "" );

		if ( globalConfigOnly ) {
			if ( !settings.recordCount ) {
				var hasAnyAccess = $getPresideObject( "rest_user_api_access" ).dataExists( filter={
					  rest_user = arguments.userId
					, api       = arguments.api
				} );

				if ( !hasAnyAccess ) {
					return {};
				}

				return getDefaultAccessDetailsForFormControl( arguments.api );
			} else {
				accessDetails.all_read         = _isTrue( settings.get_allowed          );
				accessDetails.all_insert       = _isTrue( settings.post_allowed         );
				accessDetails.all_update       = _isTrue( settings.put_allowed          );
				accessDetails.all_delete       = _isTrue( settings.delete_allowed       );
				accessDetails.all_queue_insert = _isTrue( settings.subscribe_to_inserts );
				accessDetails.all_queue_update = _isTrue( settings.subscribe_to_updates );
				accessDetails.all_queue_delete = _isTrue( settings.subscribe_to_deletes );
				accessDetails.all_all          = ( accessDetails.all_read && accessDetails.all_insert && accessDetails.all_update && accessDetails.all_delete );
				accessDetails.all_queue_all    = ( accessDetails.all_queue_insert && accessDetails.all_queue_update && accessDetails.all_queue_delete );
			}

			for( var entity in entities ) {
				accessDetails[ "#entity#_read"         ] = accessDetails.all_read;
				accessDetails[ "#entity#_insert"       ] = accessDetails.all_insert;
				accessDetails[ "#entity#_update"       ] = accessDetails.all_update;
				accessDetails[ "#entity#_delete"       ] = accessDetails.all_delete;
				accessDetails[ "#entity#_queue_insert" ] = accessDetails.all_queue_insert;
				accessDetails[ "#entity#_queue_update" ] = accessDetails.all_queue_update;
				accessDetails[ "#entity#_queue_delete" ] = accessDetails.all_queue_delete;
				accessDetails[ "#entity#_all"          ] = accessDetails.all_all;
				accessDetails[ "#entity#_queue_all"    ] = accessDetails.all_queue_all;
			}

			return accessDetails;
		}

		var readAll        = true;
		var insertAll      = true;
		var updateAll      = true;
		var deleteAll      = true;
		var queueInsertAll = true;
		var queueUpdateAll = true;
		var queueDeleteAll = true;

		for( var setting in settings ) {
			var entity = apiConfigService.getObjectEntity( setting.object_name, namespace );

			accessDetails[ "#entity#_read"         ] = _isTrue( setting.get_allowed          );
			accessDetails[ "#entity#_insert"       ] = _isTrue( setting.post_allowed         );
			accessDetails[ "#entity#_update"       ] = _isTrue( setting.put_allowed          );
			accessDetails[ "#entity#_delete"       ] = _isTrue( setting.delete_allowed       );
			accessDetails[ "#entity#_queue_insert" ] = _isTrue( setting.subscribe_to_inserts );
			accessDetails[ "#entity#_queue_update" ] = _isTrue( setting.subscribe_to_updates );
			accessDetails[ "#entity#_queue_delete" ] = _isTrue( setting.subscribe_to_deletes );
			accessDetails[ "#entity#_all"          ] = accessDetails[ "#entity#_read" ] && accessDetails[ "#entity#_insert" ] && accessDetails[ "#entity#_update" ] && accessDetails[ "#entity#_delete" ];
			accessDetails[ "#entity#_queue_all"    ] = accessDetails[ "#entity#_queue_insert" ] && accessDetails[ "#entity#_queue_update" ] && accessDetails[ "#entity#_queue_delete" ];

			readAll        = readAll        && accessDetails[ "#entity#_read"         ];
			insertAll      = insertAll      && accessDetails[ "#entity#_insert"       ];
			updateAll      = updateAll      && accessDetails[ "#entity#_update"       ];
			deleteAll      = deleteAll      && accessDetails[ "#entity#_delete"       ];
			queueInsertAll = queueInsertAll && accessDetails[ "#entity#_queue_insert" ];
			queueUpdateAll = queueUpdateAll && accessDetails[ "#entity#_queue_update" ];
			queueDeleteAll = queueDeleteAll && accessDetails[ "#entity#_queue_delete" ];
		}

		accessDetails.all_read         = readAll;
		accessDetails.all_insert       = insertAll;
		accessDetails.all_update       = updateAll;
		accessDetails.all_delete       = deleteAll;
		accessDetails.all_queue_insert = queueInsertAll;
		accessDetails.all_queue_update = queueUpdateAll;
		accessDetails.all_queue_delete = queueDeleteAll;
		accessDetails.all_all          = ( accessDetails.all_read && accessDetails.all_insert && accessDetails.all_update && accessDetails.all_delete );
		accessDetails.all_queue_all    = ( accessDetails.all_queue_insert && accessDetails.all_queue_update && accessDetails.all_queue_delete );

		return accessDetails;
	}

	public struct function getDefaultAccessDetailsForFormControl( required string api ) {
		var apiConfigService = _getApiConfigService();
		var namespace = apiConfigService.getNamespaceForRoute( arguments.api );
		var entities  = StructKeyArray( apiConfigService.getEntities( namespace ) );
		var accessDetails = {};

		accessDetails.all_all          = true;
		accessDetails.all_read         = true;
		accessDetails.all_insert       = true;
		accessDetails.all_update       = true;
		accessDetails.all_delete       = true;
		accessDetails.all_queue_all    = false;
		accessDetails.all_queue_insert = false;
		accessDetails.all_queue_update = false;
		accessDetails.all_queue_delete = false;

		for( var entity in entities ) {
			accessDetails[ "#entity#_read"         ] = accessDetails.all_read;
			accessDetails[ "#entity#_insert"       ] = accessDetails.all_insert;
			accessDetails[ "#entity#_update"       ] = accessDetails.all_update;
			accessDetails[ "#entity#_delete"       ] = accessDetails.all_delete;
			accessDetails[ "#entity#_queue_insert" ] = accessDetails.all_queue_insert;
			accessDetails[ "#entity#_queue_update" ] = accessDetails.all_queue_update;
			accessDetails[ "#entity#_queue_delete" ] = accessDetails.all_queue_delete;
			accessDetails[ "#entity#_all"          ] = accessDetails.all_all;
			accessDetails[ "#entity#_queue_all"    ] = accessDetails.all_queue_all;
		}

		return accessDetails;
	}

// PRIVATE HELPERS
	private boolean function _isTrue( required any value ) {
		return IsBoolean( arguments.value ) && arguments.value;
	}

// GETTERS AND SETTERS
	private any function _getApiConfigService() {
	    return _apiConfigService;
	}
	private void function _setApiConfigService( required any apiConfigService ) {
	    _apiConfigService = arguments.apiConfigService;
	}
}