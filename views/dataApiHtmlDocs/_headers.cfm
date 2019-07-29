<cfscript>
	spec    = args.spec ?: {};
	headers = args.headers ?: {};
	title   = translateResource( "dataapi:html.docs.response.headers.title" );
</cfscript>

<cfoutput>
	<div class="api-doc-responses-response-headers">
		<h6 class="api-doc-responses-response-headers-title">#title#</h6>

		<table class="api-doc-responses-response-headers-table table">
			<tbody>
				<cfloop collection="#headers#" item="header" index="headerName">
					<tr>
						<td kind="field" title="#HtmlEditFormat( headerName )#">
							#headerName#
						</td>
						<td>
							#renderView( view="/dataApiHtmlDocs/_schema", args={ schema=header, spec=spec } )#
						</td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	</div>
</cfoutput>