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

		event?.setContentSecurityPolicy( "default-src 'self'; style-src 'self' 'unsafe-inline' 'nonce-#event?.getRequestNonce()#'" );

		restResponse.setData( Trim( renderView( view="/dataApiHtmlDocs/index", args=args ) ) );

		restResponse.setMimeType( "text/html" );
		restResponse.setRenderer( "html" );
	}

}