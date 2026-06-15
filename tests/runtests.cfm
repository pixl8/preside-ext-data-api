<cfscript>
	reporter = url.reporter ?: "simple";
	testbox  = new testbox.system.TestBox( options={}, directory={
		  recurse  = true
		, mapping  = "tests.unit"
		, filter   = function( required path ){ return true; }
	} );

	results = Trim( testbox.run( reporter=reporter ) );
	content reset=true; echo( results ); abort;
</cfscript>
