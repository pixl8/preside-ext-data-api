/**
 * @restUri /html/
 *
 */
component {

	property name="dataApiSpecService" inject="dataApiSpecService";
	property name="dataApiService"     inject="dataApiService";

	public void function get() {
		var api = event.getValue( name="dataApiNamespace", defaultValue="" );
		if ( !variables.keyExists( "_spec#api#" ) ) {
			variables[ "_spec#api#" ] = dataApiSpecService.getSpec();
		}

		args.spec = variables[ "_spec#api#" ];

try {

		restResponse.setData( Trim( renderView( view="/dataApiHtmlDocs/index", args=args ) ) );
} catch( any e ) {
	WriteDump( e ); abort;
}
		restResponse.setMimeType( "text/html" );
		restResponse.setRenderer( "html" );
	}

}