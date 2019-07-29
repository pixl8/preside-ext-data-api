<cfscript>
	params        = args.params ?: [];
	type          = args.type ?: "query";
	title         = translateResource( "dataapi:html.docs.#type#.params.title" );
	requiredTitle = translateResource( "dataapi:html.docs.required.param.title" );
</cfscript>

<cfoutput>
	<div class="api-doc-method-params api-doc-method-params-#type#">
		<h4 class="api-doc-params-title">#title#</h4>

		<table class="api-doc-method-params-table table">
			<tbody>
				<cfloop array="#params#" index="i" item="param">
					<tr>
						<td kind="field" title="#HtmlEditFormat( param.name ?: '' )#">
							#param.name ?: ""#
							<cfif IsTrue( param.required ?: "" )>
								<em class="api-doc-params-required">#requiredTitle#</em>
							</cfif>
						</td>
						<td>
							#renderView( view="/dataApiHtmlDocs/_schema", args={
								  spec        = spec
								, schema      = param.schema ?: {}
								, description = param.description ?: ""
							} )#
						</td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	</div>
</cfoutput>