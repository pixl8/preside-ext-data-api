component {

	property name="assetManagerService" inject="assetManagerService";

	private string function default( event, rc, prc, args={} ){
		var assetId    = args.data       ?: "";
		var derivative = args.derivative ?: "";

		if ( assetId.len() ) {
			var link = len( derivative ) ? assetManagerService.getDerivativeUrl( assetId=assetId, derivativeName=derivative ) : assetManagerService.getAssetUrl( id=assetId );
			if ( !link.reFind( "^(https?:)?\/\/" ) ) {
				link = event.getSiteUrl( includePath=false, includeLanguageSlug=false ) & link;
			}

			return link;
		}

		return "";
	}
}