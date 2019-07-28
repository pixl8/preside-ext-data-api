<cfscript>
	tag = args.tag ?: {};
	spec = args.spec ?: {};
	paths = spec.paths ?: {};
	headerId = "section/#slugify( tag.name ?: '' )#";
</cfscript>

<cfoutput>
	<section class="api-doc-section api-doc-tag-section">
		<h2 class="api-doc-section-title" id="#headerId#">
			<a href="###headerId#"></a>
			#( tag.name ?: '' )#
		</h2>
		<cfif Len( Trim( tag.description ?: "" ) )>
			<div class="api-doc-markdown">#openApiMarkdown( tag.description )#</div>
		</cfif>

		<cfif IsFalse( tag[ "x-traitTag" ] ?: "" )>
			<cfloop collection="#paths#" item="path" index="pathName">
				<cfset pathFound = false />
				<cfloop collection="#path#" item="method" index="methodName">
					<cfif ArrayFindNoCase( method.tags ?: [], tag.name ?: "" )>
						#renderView( view="/dataApiHtmlDocs/_method", args={
							  spec       = spec
							, method     = method
							, methodName = methodName
							, pathName   = pathName
							, tagSlug    = headerId
						} )#
					</cfif>
				</cfloop>
			</cfloop>
		</cfif>
	</section>
</cfoutput>