<cfscript>
	spec = args.spec ?: {};
</cfscript>

<cfoutput>
	<div class="api-doc-header">
		<h1 class="api-doc-header-title">#( spec.info.title ?: "" )# <span class="api-doc-header-version">#( spec.info.version ?: '' )#</span></h1>
		<cfif Len( Trim( spec.info.description ?: "" ) )>
			<div class="api-doc-markdown">#openApiMarkdown( spec.info.description )#</div>
		</cfif>
	</div>
</cfoutput>