/**
 * Handler for authenticating with token authentication
 *
 */
component {

	property name="authService" inject="presideRestAuthService";
	property name="dataApiUserConfigurationService" inject="dataApiUserConfigurationService";

	private string function authenticate() {
		var headers    = getHTTPRequestData().headers;
		var authHeader = headers.Authorization ?: "";
		var token      = "";

		try {
			authHeader = toString( toBinary( listRest( authHeader, ' ' ) ) );
			token      = ListFirst( authHeader, ":" );

			if ( !token.trim().len() ) {
				throw( type="missing.token" );
			}
		} catch( any e ) {
			return "";
		}

		var userId = authService.getUserIdByToken( token );
		if ( userId.len() && authService.userHasAccessToApi( userId, restRequest.getApi() ) ) {
			return userId;
		}

		return "";
	}

	private string function configure() {
		args.api = rc.id ?: "";
		args.apiUsers = dataApiUserConfigurationService.listUsersWithApiAccess( args.api );

		return renderView( view="/admin/rest/auth/dataapi/configure", args=args );
	}

}