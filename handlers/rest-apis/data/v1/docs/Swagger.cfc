/**
 * @restUri /swagger/
 *
 */
component {

	property name="dataApiSpecService" inject="dataApiSpecService";
	property name="dataApiService"     inject="dataApiService";

	public void function get() {
		var api     = event.getValue( name="dataApiNamespace", defaultValue="data" );
		var handler = event.getValue( name="dataApiHandler"  , defaultValue="data.v1" );
		var args    = {
			  specsEndpoint = event.buildLink( linkto="api.#handler#.docs.spec" )
			, favicon32     = event.buildLink( systemStaticAsset="/extension/preside-ext-data-api/assets/favicon-32x32.png" )
			, favicon16     = event.buildLink( systemStaticAsset="/extension/preside-ext-data-api/assets/favicon-16x16.png" )
			, docsJs        = event.buildLink( systemStaticAsset="/extension/preside-ext-data-api/assets/redoc.standalone.js" )
			, pageTitle     = dataApiService.i18nNamespaced( "dataapi:api.title" ) & " " & dataApiService.i18nNamespaced( "dataapi:api.version" )
		};

		restResponse.setData( Trim( renderView( view="/swaggerLayout", args=args ) ) );
		restResponse.setMimeType( "text/html" );
		restResponse.setRenderer( "html" );
	}

}