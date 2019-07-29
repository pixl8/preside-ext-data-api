component {

	property name="assetManagerService" inject="assetManagerService";

	private string function default( event, rc, prc, args={} ){
		var assetId = args.data ?: "";

		if ( assetId.len() ) {
			var link = assetManagerService.getAssetUrl( id=assetId );
			if ( !link.reFind( "^(https?:)?\/\/" ) ) {
				link = event.getSiteUrl( includePath=false, includeLanguageSlug=false ) & link;
			}

			return link;
		}

		return "";
	}
}