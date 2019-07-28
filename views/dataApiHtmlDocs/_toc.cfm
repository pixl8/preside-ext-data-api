<cfscript>
	spec    = args.spec ?: {};
	tags    = spec.tags ?: [];
	hasAuth = ( args.hasAuth ?: "" );
	apiTitle = ( spec.info.title ?: "" ) & " " & ( spec.info.version ?: "" );
</cfscript>

<cfoutput>
	<h2 class="data-api-toc-title">#translateResource( "dataapi:html.docs.toc.title" )#</h2>
	<ul class="data-api-toc-list" role="navigation">
		<li data-item-id="home">
			<label role="menuitem" type="section">
				<a href="##home" title="#HtmlEditFormat( apiTitle )#">#apiTitle#</a>
			</label>
		</li>

		<cfif hasAuth>
			<li data-item-id="section/authentication">
				<label role="menuitem" type="section">
					<a href="##section/authentication" title="Authentication">Authentication</a>
				</label>
			</li>
		</cfif>

		<cfloop array="#tags#" index="i" item="tag">
			#renderView( view="/dataApiHtmlDocs/_tagToc", args={ spec=spec, tag=tag } )#
		</cfloop>
	</ul>
</cfoutput>