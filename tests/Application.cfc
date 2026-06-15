component {
	this.name = "Data API Test suite";

	this.mappings[ '/tests'   ] = ExpandPath( "/" );
	this.mappings[ '/testbox' ] = ExpandPath( "/testbox" );
	this.mappings[ '/dataApi' ] = ExpandPath( "../" );

	setting requesttimeout="6000";
}
