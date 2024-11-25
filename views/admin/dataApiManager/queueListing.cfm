<cfscript>
	queueRestUsers = prc.queueRestUsers  ?: QueryNew( "" );
	activeRestUser = Len( Trim( prc.activeRestUser ?: "" ) ) ? prc.activeRestUser : ( queueRestUsers.id ?: "" );
	apiRoute       = rc.apiRoute    ?: "";
	gridFields     = prc.gridFields ?: [ "queue_name", "object_name", "record_id", "operation", "order_number" ];

	if ( isEmptyString( apiRoute ) && !ArrayFindNoCase( gridFields, "namespace" ) ) {
		ArrayPrepend( gridFields, "namespace" )
	}
</cfscript>

<cfoutput>
	<cfif !queueRestUsers.recordcount>
		<p class="alert alert-warning">
			<i class="fa fa-fw fa-exclamation-circle"></i>
			#translateResource( "cms:apiQueueListing.alert.no.queue.user.msg" )#
		</p>
	<cfelse>
		<div class="tabbable tabs-left">
			<ul class="nav nav-tabs">
				<cfloop query="#queueRestUsers#">
					<li<cfif activeRestUser eq queueRestUsers.id> class="active"</cfif>>
						<a href="#event.buildAdminLink(
							  linkto      = "dataApiManager.queueListing"
							, queryString = "restUser=#queueRestUsers.id##Len( Trim( apiRoute ) ) ? "&apiRoute=#apiRoute#" : ""#"
						)#" >#queueRestUsers.name#</a>
					</li>
				</cfloop>
			</ul>

			<div class="tab-content">
				<div id="tab-#activeRestUser#" class="tab-pane active">
					#objectDataTable( objectName="data_api_queue", args={
						  gridFields      = gridFields
						, allowDataExport = false
						, useMultiActions = false
						, compact         = true
					} )#
				</div>
			</div>
		</div>
	</cfif>
</cfoutput>