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
				, object_name          = ( entity == "all" ? "" : entity )
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