<cfscript>
	spec        = args.spec ?: {};
	requestBody = args.requestBody ?: {};
	title       = translateResource( "dataapi:html.docs.request.body.title" );
	schemas     = requestBody.content ?: {};
</cfscript>

<cfoutput>
	<cfloop collection="#schemas#" item="schema" index="schemaName">
		<cfif schemaName == "application/json"><!-- TODO: support more schemas -->
			<div class="api-doc-method-params api-doc-method-params-request-body">
				<h4 class="api-doc-params-title">#title#: <span class="api-docs-params-title-schema">#schemaName#</span></h4>
				<cfif Len( Trim( requestBody.description ?: "" ) )>
					<div class="api-doc-markdown">#openApiMarkdown( requestBody.description )#</div>
				</cfif>

				<cfif StructCount( schema.schema ?: {} )>
					#renderView( view="/dataApiHtmlDocs/_schema", args={ schema=schema.schema, spec=spec } )#
				</cfif>
			</div>
		</cfif>
	</cfloop>
</cfoutput>