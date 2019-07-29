component {

	property name="assetManagerService" inject="assetManagerService";

	private array function default( event, rc, prc, args={} ){
		var links = ListToArray( args.data ?: "" );

		for( var i=1; i<=links.len(); i++ ) {
			var links[ i ] = assetManagerService.getAssetUrl( id=links[ i ] );
			if ( !links[ i ].reFind( "^(https?:)?\/\/" ) ) {
				links[ i ] = event.getSiteUrl( includePath=false, includeLanguageSlug=false ) & links[ i ];
			}
		}

		return links;
	}
}