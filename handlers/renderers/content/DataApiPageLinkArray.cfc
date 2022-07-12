component {

	private array function default( event, rc, prc, args={} ){
		var pages = ListToArray( args.data ?: "" );

		for( var i=1; i<=pages.len(); i++ ) {
			if ( pages[ i ].len() ) {
				pages[ i ] = event.buildLink( page=pages[ i ] );
			}
		}

		return pages;
	}
}