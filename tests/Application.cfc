component {
	this.name = "Data API Test Suite";

	this.mappings[ '/tests'   ] = ExpandPath( "/" );
	this.mappings[ '/testbox' ] = ExpandPath( "/testbox" );
	this.mappings[ '/data-api'     ] = ExpandPath( "../" );

	setting requesttimeout=60000;
}
