component extends="preside.system.base.AdminHandler" {

	property name="dataApiUserConfigurationService" inject="dataApiUserConfigurationService";

	function prehandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		_checkPermissions( event=event, key="read" );
	}

	public void function addUser() {
		WriteDump( 'TODO' ); abort;
	}

	public void function configureApiUser() {
		WriteDump( 'TODO' ); abort;
	}

	public void function revokeAccessAction() {
		_checkPermissions( event=event, key="delete" );

		var userId = rc.id ?: "";
		var api    = rc.api ?: "";

		dataApiUserConfigurationService.revokeAccess(
			  userId = rc.id
			, api    = api
		);

		event.audit(
			  action   = "revokeDataApiAccess"
			, type     = "datamanager"
			, recordId = userId
			, detail   = { objectName="rest_user", id=userId, name=renderLabel( "rest_user", userId ) }
		);

		messageBox.info( translateResource( uri="dataapi:user.access.revoked" ) );
		setNextEvent( url=event.buildAdminLink( linkto="apimanager.configureAuth", querystring="id=#api#" ) );

	}


	private boolean function _checkPermissions( required any event, required string key, boolean throwOnError=true ) {
		var hasPermission = hasCmsPermission( "apiManager." & arguments.key );
		if ( !hasPermission && arguments.throwOnError ) {
			event.adminAccessDenied();
		}

		return hasPermission;
	}

}
