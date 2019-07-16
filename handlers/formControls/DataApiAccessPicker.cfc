component {

	property name="apiConfigService" inject="dataApiConfigurationService";
	property name="userConfigService" inject="dataApiUserConfigurationService";

	private string function index() {
		var api = rc.api ?: "";
		var userId = prc.apiUserId ?: "";

		if ( userId.len() ) {
			args.existingData = userConfigService.getExistingAccessDetailsForFormControl( api, userId );
		} else {
			args.existingData = userConfigService.getDefaultAccessDetailsForFormControl( api );
		}

		var namespace = apiConfigService.getNamespaceForRoute( api );

		args.entities = StructKeyArray( apiConfigService.getEntities( namespace ) );
		ArraySort( args.entities, "textnocase" );

		return renderView( view="/formcontrols/dataApiAccessPicker", args=args );
	}

}