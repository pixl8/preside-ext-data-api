component extends="preside.system.base.AdminHandler" {

	property name="dataApiUserConfigurationService" inject="dataApiUserConfigurationService";
	property name="messagebox" inject="messagebox@cbmessagebox";

	function prehandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		_checkPermissions( event=event, key="read" );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:apiManager.breadcrumbTitle" )
			, link  = event.buildAdminLink( linkTo = "apimanager" )
		);

		var api = rc.api ?: "";

		if ( Len( Trim( api ) ) ) {
			event.addAdminBreadCrumb(
				  title = translateResource( uri="cms:apiManager.configureauth.page.breadcrumbTitle", data=[ api ] )
				, link  = event.buildAdminLink( linkTo = "apimanager.configureAuth", queryString="id=#api#" )
			);
		}
	}

	public void function addUser() {
		var api = rc.api ?: "";

		if ( !Len( Trim( api ) ) ) {
			event.notFound();
		}

		_checkPermissions( event=event, key="add" );

		prc.pageIcon = "fa-plus";
		prc.pagetitle = translateResource( "dataapi:add.user.page.title" );
		prc.pagesubtitle = translateResource( "dataapi:add.user.page.subtitle" );

		prc.cancelAction = event.buildAdminLink( linkTo="apimanager.configureAuth", queryString="id=#api#" );
		prc.submitAction = event.buildAdminLink( linkto="dataapiManager.addUserAction" );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="dataapi:add.user.page.crumb" )
			, link  = ""
		);
	}

	public void function addUserAction() {
		var api = rc.api ?: "";
		var userId = rc.user ?: "";

		if ( !Len( Trim( api ) ) ) {
			event.notFound();
		}

		_checkPermissions( event=event, key="add" );

		var formName         = "admin.dataapi.user.access";
		var formData         = event.getCollectionForForm( formName );
		var wholeSubmission  = event.getCollectionWithoutSystemVars();
		var validationResult = validateForm( formName, formData );

		if ( !validationResult.validated() ) {
			var persist = wholeSubmission;
			persist.validationResult = validationResult;

			messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );
			setNextEvent(
				  url           = event.buildAdminLink( linkto="dataApiManager.addUser", queryString="api=#api#" )
				, persistStruct = persist
			);
		}

		dataApiUserConfigurationService.saveUserAccess(
			  api    = api
			, userId = userId
			, rules  = wholeSubmission
		);

		var userName = renderLabel( "rest_user", userId );

		event.audit(
			  action   = "configureDataApiAccess"
			, type     = "datamanager"
			, recordId = userId
			, detail   = { objectName="rest_user", id=userId, recordId=userId, name=userName }
		);


		messageBox.info( translateResource( uri="dataapi:user.added.confirmation", data=[ api, username ] ) );

		setNextEvent( url=event.buildAdminLink( linkTo="apimanager.configureAuth", queryString="id=#api#" ) );
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
