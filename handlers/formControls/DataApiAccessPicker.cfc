component {

	property name="apiConfigService" inject="dataApiConfigurationService";

	private string function index() {
		var api = rc.api ?: "";
		var namespace = apiConfigService.getNamespaceForRoute( api );

		args.entities = StructKeyArray( apiConfigService.getEntities( namespace ) );
		ArraySort( args.entities, "textnocase" );

		return renderView( view="/formcontrols/dataApiAccessPicker", args=args );
	}

}