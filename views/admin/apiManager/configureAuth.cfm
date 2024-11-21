<!---@feature admin and apiManager--->
<cfoutput>
	<cfif isFeatureEnabled( "dataApiQueue" )>
		<div class="top-right-button-group">
			<a class="pull-right btn btn-sm btn-info inline" href="#event.buildAdminLink( linkTo="dataApiManager.queueListing", querystring="apiRoute=#rc.id ?: ""#" )#">
				<i class="fa fa-fw #translateResource( uri="cms:apiQueueListing.iconclass" )#"></i>
				#translateResource( uri="cms:apiQueueListing.btn" )#
			</a>
		</div>
	</cfif>

	#( prc.body ?: "" )#
</cfoutput>