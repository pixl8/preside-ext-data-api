component {

	property name="linksService" inject="linksService";

	private string function default( event, rc, prc, args={} ){
		var linkId = args.data ?: "";

		if ( linkId.len() ) {
			return linksService.getLinkUrl( linkId=linkId );
		}

		return "";
	}
}