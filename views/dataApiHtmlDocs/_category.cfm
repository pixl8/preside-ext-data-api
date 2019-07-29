<cfscript>
	category = args.category ?: {};
	tags     = category.tags ?: [];
	spec     = args.spec ?: {};
	headerId = "category/#slugify( category.name ?: '' )#";
</cfscript>

<cfoutput>
	<section class="api-doc-section api-doc-category-section">
		<h2 class="api-doc-section-title" id="#headerId#">
			<a href="###headerId#"></a>
			#( category.name ?: '' )#
		</h2>
		<cfif Len( Trim( category.description ?: "" ) )>
			<div class="api-doc-markdown">#openApiMarkdown( category.description )#</div>
		</cfif>

		<cfloop array="#tags#" item="tag" index="i">
			#renderView( view="/dataApiHtmlDocs/_tag", args={ spec=spec, tag=tag } )#
		</cfloop>
	</section>
</cfoutput>