component {

	private string function default( event, rc, prc, args={} ){
		var pageId = args.data ?: "";

		if ( pageId.len() ) {
			return event.buildLink( page=pageId );
		}
	}
}