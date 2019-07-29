<cfscript>
	spec              = args.spec ?: {};
	responses         = args.responses ?: {};
	title             = translateResource( "dataapi:html.docs.responses.title" );
	responseBodyTitle = translateResource( "dataapi:html.docs.response.body.title" );
	codes             = StructKeyArray( responses );

	codes.sort( "textNoCase" );
</cfscript>

<cfoutput>
	<div class="api-doc-responses">
		<h4 class="api-doc-responses-title">#title#</h4>
		<cfloop array="#codes#" item="responseCode" index="i">
			<cfset response = responses[ responseCode ] />
			<cfset headers = response.headers ?: {} />
			<div class="api-doc-responses-response api-doc-responses-response-#Left( responseCode, 1 )#">
				<div class="api-doc-responses-response-title-and-description clearfix">
					<h5 class="api-doc-responses-response-title">#responseCode#</h5>
					<cfif Len( Trim( response.description ?: "" ) )>
						<div class="api-doc-responses-response-description">
							<div class="api-doc-markdown">#openApiMarkdown( response.description )#</div>
						</div>
					</cfif>
				</div>

				<div class="api-doc-responses-response-detail">
					<!-- TODO: support more response types! -->
					<cfif StructCount( response.content[ "application/json" ].schema ?: {} )>
						<h6 class="api-doc-responses-response-body-title">#responseBodyTitle#</h6>
						#renderView( view="/dataApiHtmlDocs/_schema", args={ schema=response.content[ "application/json" ].schema, spec=spec } )#
					</cfif>

					<cfif StructCount( headers )>
						#renderView( view="/dataApiHtmlDocs/_headers", args={ headers=headers, spec=spec } )#
					</cfif>
				</div>
			</div>
		</cfloop>
	</div>
</cfoutput>