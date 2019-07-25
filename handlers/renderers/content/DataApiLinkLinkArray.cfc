component {

	property name="linksService" inject="linksService";

	private array function default( event, rc, prc, args={} ){
		var links = ListToArray( args.data ?: "" );

		for( var i=1; i<=links.len(); i++ ) {
			links[ i ] = linksService.getLinkUrl( linkId=links[ i ] );
		}

		return links;
	}
}