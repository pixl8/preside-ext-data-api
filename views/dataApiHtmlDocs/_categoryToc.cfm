<cfscript>
	category = args.category ?: {};
	spec     = args.spec     ?: {};
	paths    = spec.paths    ?: {};
	tags     = category.tags ?: [];
	headerId = "category/#slugify( category.name ?: '' )#";
</cfscript>

<cfoutput>
	<li class="data-api-toc-category">
		<label role="menuitem" type="category">
			<a href="###headerId#" title="#HtmlEditFormat( category.name ?: '' )#">#( category.name ?: '' )#</a>
		</label>
		<ul>
			<cfloop array="#tags#" item="tag" index="i">
				#renderView( view="/dataApiHtmlDocs/_tagToc", args={ spec=spec, tag=tag } )#
			</cfloop>
		</ul>
	</li>
</cfoutput>