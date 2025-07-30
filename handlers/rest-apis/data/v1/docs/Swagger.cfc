/**
 * @restUri /swagger/
 *
 */
component {

	property name="dataApiSpecService" inject="dataApiSpecService";

	public void function get() {
		var args = {
			  specsEndpoint = event.buildLink( linkto="api.data.v1.docs.spec" )
			, favicon32     = event.buildLink( systemStaticAsset="/extension/preside-ext-data-api/assets/favicon-32x32.png" )
			, favicon16     = event.buildLink( systemStaticAsset="/extension/preside-ext-data-api/assets/favicon-16x16.png" )
			, docsJs        = event.buildLink( systemStaticAsset="/extension/preside-ext-data-api/assets/redoc.standalone.js" )
		};

		event?.setContentSecurityPolicy( "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; worker-src blob:;" );

		restResponse.setData( Trim( renderView( view="/swaggerLayout", args=args ) ) );
		restResponse.setMimeType( "text/html" );
		restResponse.setRenderer( "html" );
	}

}