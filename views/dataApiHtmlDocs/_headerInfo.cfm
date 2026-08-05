<cfscript>
	spec = args.spec ?: {};
	specsEndpoint = args.specsEndpoint ?: "";
</cfscript>

<cfoutput>
	<div class="api-doc-header">
		<h1 class="api-doc-header-title" id="home">#( spec.info.title ?: "" )# <span class="api-doc-header-version">#( spec.info.version ?: '' )#</span></h1>

		<cfif Len( Trim( specsEndpoint ) )>
			<p class="api-doc-header-specs-link-container text-muted text-right">
				#translateResource( "dataApi:download.specs.txt" )# <a href="#specsEndpoint#" class="api-doc-header-specs-link btn btn-secondary">#translateResource( "dataApi:download.specs.btn" )#</a>
			</p>
		</cfif>
		<cfif Len( Trim( spec.info.description ?: "" ) )>
			<div class="api-doc-markdown">#openApiMarkdown( spec.info.description )#</div>
		</cfif>
	</div>
</cfoutput>