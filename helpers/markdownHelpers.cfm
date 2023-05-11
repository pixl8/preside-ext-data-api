<cffunction name="openApiMarkdown" access="public" returntype="any" output="false">
	<cfargument name="markdown" type="string" required="true" />

	<cfscript>
		highlighted = getSingleton( "HtmlDocumentationSyntaxHighlighter" ).renderHighlights( arguments.markdown );
		return getSingleton( "Processor@cbmarkdown" ).toHtml( highlighted );
	</cfscript>
</cffunction>
