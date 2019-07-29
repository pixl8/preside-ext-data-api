<cfscript>
	schema      = args.schema ?: {};
	spec        = args.spec   ?: {};
	description = args.description ?: "";
	isInArray   = IsTrue( args.isInArray ?: "" );

	requiredTitle = translateResource( "dataapi:html.docs.required.param.title" );

	if ( StructKeyExists( schema, "$ref" ) ) {
		schema = Evaluate( "spec.#( ListChangeDelims( reReplace( schema.$ref, '^##/', '' ), ".", "/" ) )#" );

		if ( StructKeyExists( schema, "description" ) ) {
			description = schema.description;
		}
		if ( StructKeyExists( schema, "schema" ) ) {
			schema = schema.schema;
		}
	}

	if ( ( schema.type ?: "" ) == "array" ) {
		subSchema = schema.items ?: {};

		if ( StructKeyExists( subSchema, "$ref" ) ) {
			subschema = Evaluate( "spec.#( ListChangeDelims( reReplace( subSchema.$ref, '^##/', '' ), ".", "/" ) )#" );
		}
	}
</cfscript>

<cfoutput>
	<cfif StructKeyExists( schema, "type" )>
		<cfswitch expression="#schema.type#">
			<cfcase value="array">

				<cfif !StructKeyExists( subschema, "properties" ) && Len( Trim( subschema.type ?: "" ) )>
					<div class="api-doc-schema">
						<div class="api-doc-schema-type">
							<span class="api-doc-schema-type-type">Array of: #subschema.type#</span>
							<cfif Len( Trim( subschema.format ?: "" ) )>
								<span class="api-doc-schema-type-format">#subschema.format#</span>
							</cfif>
						</div>
						<cfif Len( Trim( subschema.description ?: "" ) )>
							<div class="api-doc-schema-description">
								<div class="api-doc-markdown">#openApiMarkdown( subschema.description )#</div>
							</div>
						</cfif>
						<cfif ArrayLen( subschema.enum ?: [] )>
							<p class="api-doc-schema-type-enum">
								<span class="enum">enum</span>: <cfloop array="#subschema.enum#" index="n" item="enum"><code>#enum#</code><cfif n lt schema.enum.len()>, </cfif></cfloop>
							</p>
						</cfif>
					</div>
				<cfelseif StructKeyExists( subschema, "properties" )>
					<div class="api-doc-schema">
						<div class="api-doc-schema-type api-doc-schema-type-array-of-objects">
							<span class="api-doc-schema-type-type">Array of objects:</span>
							#renderView( view="/dataApiHtmlDocs/_schema", args={
								  spec        = spec
								, schema      = subschema
								, description = subschema.description ?: ""
								, isInArray   = true
							} )#
						</div>
					</div>
				</cfif>
			</cfcase>
			<cfdefaultcase>
				<div class="api-doc-schema">
					<div class="api-doc-schema-type">
						<span class="api-doc-schema-type-type">#schema.type#</span>
						<cfif Len( Trim( schema.format ?: "" ) )>
							<span class="api-doc-schema-type-format">#schema.format#</span>
						</cfif>
					</div>
					<cfif Len( Trim( description ) )>
						<div class="api-doc-schema-description">
							<div class="api-doc-markdown">#openApiMarkdown( description )#</div>
						</div>
					</cfif>
					<cfif ArrayLen( schema.enum ?: [] )>
						<p class="api-doc-schema-type-enum">
							<span class="enum">enum</span>: <cfloop array="#schema.enum#" index="n" item="enum"><code>#enum#</code><cfif n lt schema.enum.len()>, </cfif></cfloop>
						</p>
					</cfif>
				</div>
			</cfdefaultcase>
		</cfswitch>
	<cfelseif StructKeyExists( schema, "properties" )>
		<cfset requiredProps = schema.required ?: []/>

		<cfif !isInArray>
			<div class="api-doc-schema">
				<div class="api-doc-schema-type api-doc-schema-type-object">
					<span class="api-doc-schema-type-type">Object:</span>
		</cfif>

		<table class="api-doc-spec-fields-table table">
			<tbody>
				<cfloop array="#requiredProps#" index="i" item="propName">
					<cfif !StructKeyExists( schema.properties, propName )>
						<cfcontinue />
					</cfif>
					<tr>
						<td kind="field" title="#HtmlEditFormat( propName )#">
							#propName#
							<em class="api-doc-params-required">#requiredTitle#</em>
						</td>
						<td>
							#renderView( view="/dataApiHtmlDocs/_schema", args={
								  spec        = spec
								, schema      = schema.properties[ propName ]
								, description = schema.properties[ propName ].description ?: ""
							} )#
						</td>
					</tr>
				</cfloop>
				<cfloop collection="#schema.properties#" index="propName" item="prop">
					<cfif requiredProps.findNoCase( propName )>
						<cfcontinue />
					</cfif>
					<tr>
						<td kind="field" title="#HtmlEditFormat( propName )#">
							#propName#
						</td>
						<td>
							#renderView( view="/dataApiHtmlDocs/_schema", args={
								  spec        = spec
								, schema      = prop
								, description = prop.description ?: ""
							} )#
						</td>
					</tr>
				</cfloop>
			</tbody>
		</table>

		<cfif !isInArray>
				</div>
			</div>
		</cfif>

	</cfif>
</cfoutput>