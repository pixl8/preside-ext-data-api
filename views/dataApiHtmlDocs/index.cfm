<cfscript>
	spec           = args.spec              ?: {};
	tags           = spec.tags              ?: [];
	categories     = spec[ "x-categories" ] ?: [];
	authentication = renderView( view="/dataApiHtmlDocs/_authenticationInfo", args=args )
	args.hasAuth   = Len( Trim( authentication ) );
</cfscript>

<cfoutput>
<!DOCTYPE html>
<html>
	<head>
		<title>#( spec.info.title ?: 'API' )# #( spec.info.version ?: '1.0.0')#</title>
		<cfif Len( Trim( spec.info[ "x-favicon" ] ?: "" ) )>
			<link rel="shortcut icon" href="#spec.info[ "x-favicon" ]#" type="image/x-icon" />
		</cfif>
		<style>
			<cfinclude template="htmlDocsCss.css" />
		</style>
	</head>
	<body class="api-doc">
		<div class="api-doc-toc">
			<div class="api-doc-toc-inner">
				#renderView( view="/dataApiHtmlDocs/_toc", args=args )#
			</div>
		</div>
		<div class="api-doc-content">
			<div class="api-doc-content-inner">
				#renderView( view="/dataApiHtmlDocs/_headerInfo", args=args )#
				#authentication#
				<cfloop array="#tags#" index="i" item="tag">
					<cfif !categories.len() || !Len( Trim( tag[ "x-category" ] ?: "" ) )>
						#renderView( view="/dataApiHtmlDocs/_tag", args={ spec=spec, tag=tag } )#
					</cfif>
				</cfloop>
				<cfloop array="#categories#" index="i" item="category">
					#renderView( view="/dataApiHtmlDocs/_category", args={ spec=spec, category=category } )#
				</cfloop>
			</div>
		</div>
	</body>
</html>
</cfoutput>