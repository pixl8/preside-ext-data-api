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

		args.allEntities = apiConfigService.getEntities( namespace );
		args.entities = StructKeyArray( args.allEntities );
		ArraySort( args.entities, "textnocase" );

		args.queueEnabled = apiConfigService.isQueueEnabled( namespace );

		return renderView( view="/formcontrols/dataApiAccessPicker", args=args );
	}

}