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

// PRIVATE HELPERS

// GETTERS AND SETTERS
	private any function _getApiConfigService() {
	    return _apiConfigService;
	}
	private void function _setApiConfigService( required any apiConfigService ) {
	    _apiConfigService = arguments.apiConfigService;
	}
}