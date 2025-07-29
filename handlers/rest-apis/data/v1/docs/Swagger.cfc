/**
 * @restUri /swagger/
 *
 */
component {

	property name="dataApiSpecService" inject="dataApiSpecService";
	property name="dataApiService"     inject="dataApiService";

	public void function get() {
		var api     = event.getValue( name="dataApiNamespace", defaultValue="data" );
		var handler = event.getValue( name="dataApiHandler"  , defaultValue="data.v1.docs" );
		var spec    = dataApiSpecService.getSpec();
		var args    = {
			  specsEndpoint = event.buildLink( linkto="api.#handler#.spec" )
			, favicon       = spec.info[ "x-favicon" ] ?: ""
			, docsJs        = event.buildLink( systemStaticAsset="/extension/preside-ext-data-api/assets/redoc.standalone.js" )
			, pageTitle     = dataApiService.i18nNamespaced( "dataapi:api.title" ) & " " & dataApiService.i18nNamespaced( "dataapi:api.version" )
		};

		if ( !Len( Trim( args.favicon ) ) ) {
			args.favicon = event.buildLink( systemStaticAsset="/extension/preside-ext-data-api/assets/favicon-32x32.png" );
		}

		event?.setContentSecurityPolicy( "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; worker-src blob:;" );

		restResponse.setData( Trim( renderView( view="/swaggerLayout", args=args ) ) );
		restResponse.setMimeType( "text/html" );
		restResponse.setRenderer( "html" );
	}

}