<!---@feature admin and apiManager--->
<cfscript>
	apis           = prc.apis ?: [];
	configLinkBase = prc.configLinkBase ?: "";
</cfscript>

<cfoutput>
	<cfif isFeatureEnabled( "dataApiQueue" )>
		<div class="top-right-button-group">
			<a class="pull-right btn btn-sm btn-info inline" href="#event.buildAdminLink( linkTo="dataApiManager.queueListing" )#">
				<i class="fa fa-fw #translateResource( uri="cms:apiQueueListing.iconclass" )#"></i>
				#translateResource( uri="cms:apiQueueListing.btn" )#
			</a>
		</div>
	</cfif>

	<cfinclude template="/preside/system/views/admin/apiManager/index.cfm" />
</cfoutput>