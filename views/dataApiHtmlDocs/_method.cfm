<cfscript>
	method      = args.method        ?: {};
	methodName  = args.methodName    ?: "";
	pathName    = args.pathName      ?: "";
	tagSlug     = args.tagSlug       ?: "";
	spec        = args.spec          ?: {};
	requestBody = method.requestBody ?: {};
	responses   = method.responses   ?: {};
	params      = method.parameters  ?: [];
	pathParams  = params.filter( function( param ){ return ( ( param.in ?: "" ) == "path"  ) } );
	queryParams = params.filter( function( param ){ return ( ( param.in ?: "" ) == "query" ) } );
	headerId    = "#tagSlug##pathName#~#methodName#";
</cfscript>

<cfoutput>
	<div class="api-doc-subsection api-doc-method-section">
		<h3 class="api-doc-subsection-title" id="#headerId#">
			<a href="###headerId#"></a>
			<cfif Len( Trim( method.summary ?: "" ) )>
				#method.summary#
			<cfelse>
				#UCase( methodName )# #pathName#
			</cfif>
		</h3>
		<cfif Len( Trim( method.description ?: "" ) )>
			<div class="api-doc-markdown">#openApiMarkdown( method.description )#</div>
		</cfif>

		<!-- TODO: authorizations for custom, per-method authorization -->

		<cfif pathParams.len()>
			#renderView( view="/dataApiHtmlDocs/_methodParams", args={ params=pathParams, spec=spec, type="path" } )#
		</cfif>

		<cfif queryParams.len()>
			#renderView( view="/dataApiHtmlDocs/_methodParams", args={ params=queryParams, spec=spec, type="query" } )#
		</cfif>

		<cfif requestBody.count()>
			#renderView( view="/dataApiHtmlDocs/_requestBody", args={ requestBody=requestBody, spec=spec } )#
		</cfif>

		<cfif responses.count()>
			#renderView( view="/dataApiHtmlDocs/_responses", args={ responses=responses, spec=spec } )#
		</cfif>

	</div>
</cfoutput>