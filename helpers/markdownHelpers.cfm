<cffunction name="openApiMarkdown" access="public" returntype="any" output="false">
	<cfargument name="markdown" type="string" required="true" />

	<cfscript>
		highlighted = getSingleton( "HtmlDocumentationSyntaxHighlighter" ).renderHighlights( arguments.markdown );
		return getSingleton( "Processor@cbmarkdown" ).toHtml( highlighted );
	</cfscript>
</cffunction>

<!--- helpers --->
<cffunction name="simpleRequestCache" access="public" returntype="any" output="false">
	<cfargument name="key" type="string" required="true" />
	<cfargument name="generator" type="any" required="true" />

	<cfscript>
		request._simpleRequestCache = request._simpleRequestCache ?: {};

		if ( !request._simpleRequestCache.keyExists( arguments.key ) ) {
			request._simpleRequestCache[ arguments.key ] = arguments.generator();
		}

		return request._simpleRequestCache[ arguments.key ];
	</cfscript>
</cffunction>
<cffunction name="getSingleton" access="public" returntype="any" output="false">
	<cfargument name="objectName" type="string" required="true" />

	<cfscript>
		var args = arguments;
		return simpleRequestCache( "getSingleton" & args.objectName, function(){
			return getController().getWireBox().getInstance( args.objectName );
		} );
	</cfscript>
</cffunction>