<cfscript>
	spec = args.spec ?: {};
	tags = spec.tags ?: [];
</cfscript>

<cfoutput>
<!DOCTYPE html>
<html>
	<head>
		<title>#( spec.info.title ?: 'API' )# #( spec.info.version ?: '1.0.0')#</title>
		<link href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T" crossorigin="anonymous">
		<style>
			<cfinclude template="htmlDocsCss.css" />
		</style>
	</head>
	<body class="api-doc">
		<div class="container">
			#renderView( view="/dataApiHtmlDocs/_headerInfo", args=args )#
			#renderView( view="/dataApiHtmlDocs/_authenticationInfo", args=args )#
			<cfloop array="#tags#" index="i" item="tag">
				#renderView( view="/dataApiHtmlDocs/_tag", args={ spec=spec, tag=tag } )#
			</cfloop>
		</div>
	</body>
</html>
</cfoutput>