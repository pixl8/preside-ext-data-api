<cfscript>
	spec = args.spec ?: {};
	security = spec.security ?: [];
</cfscript>

<cfif security.len()>
	<cfoutput>
		<div class="api-doc-section api-doc-auth-section">
			<h2 class="api-doc-section-title" id="section/authentication">Authentication</h2>

			<cfloop array="#security#" index="i" item="instance">
				<cfloop collection="#security[ i ]#" index="securityType" item="whatever">
					<cfset scheme = spec.components.securitySchemes[ securityType ] ?: {}>
					<cfif scheme.count()>
						<h3 class="api-doc-sub-section-title">#( scheme.scheme ?: '' )#</h3>
						<cfif Len( Trim( scheme.description ?: "" ) )>
							<div class="api-doc-markdown">#openApiMarkdown( scheme.description )#</div>
						</cfif>
						<!-- TODO: document technical specifics about the API in a table as redoc does -->
					</cfif>
				</cfloop>
			</cfloop>
		</div>
	</cfoutput>
</cfif>