<cfscript>
	api         = args.api         ?: "";
	apiUsers    = args.apiUsers    ?: [];
	addUserLink = event.buildAdminLink( linkto="dataApiManager.addUser", querystring="api=#api#" );
</cfscript>

<cfoutput>
	<cfif !apiUsers.len()>
		<p class="alert alert-warning">
			<i class="fa fa-fw fa-exclamation-triangle"></i>
			#translateResource( "dataapi:auth.configuration.no.users" )#

			<br><br>

			<a href="#addUserLink#" class="btn btn-success">
				<i class="fa fa-fw fa-plus"></i>
				#translateResource( "dataapi:add.user.btn" )#
			</a>
		</p>
	<cfelse>
		<div class="row">
			<div class="col-md-8 col-lg-6">
				<div class="table-responsive">
					<table class="table table-striped">
						<thead>
							<tr>
								<th><i class="fa fa-fw fa-user"></i> #translateResource( "dataapi:auth.user.table.name.th" )#</th>
								<th>#translateResource( "dataapi:auth.user.table.queueenabled.th" )#</th>
								<th>&nbsp;</th>
							</tr>
						</thead>
						<tbody>
							<cfloop array="#apiUsers#" index="i" item="usr">
								<tr class="clickable">
									<td>
										<a href="#event.buildAdminLink( linkto='apiuserManager.view', queryString='id=#usr.id#' )#">
											<i class="fa fa-fw fa-user"></i>
											#usr.name#
										</a>
									</td>
									<td>#renderContent( "boolean", IsTrue( usr.queueAccess ), "admin" )#</td>
									<td class="text-right">
										<div class="action-buttons btn-group">
											<a class="row-link" href="#event.buildAdminLink( linkto='dataApiManager.configureApiUser', queryString='id=#usr.id#&api=#api#' )#">
												<i class="fa fa-fw fa-cogs blue"></i>
											</a>
											<a class="confirmation-prompt" href="#event.buildAdminLink( linkto='dataApiManager.revokeAccessAction', queryString='id=#usr.id#&api=#api#' )#" title="#HtmlEditFormat( translateResource( uri='dataapi:revoke.access.prompt', data=[ usr.name, api ] ) )#">
												<i class="fa fa-fw fa-ban red"></i>
											</a>
										</div>
									</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				</div>
				<hr>
				<div class="text-center">
					<a href="#addUserLink#" class="btn btn-success">
						<i class="fa fa-fw fa-plus"></i>
						#translateResource( "dataapi:add.user.btn" )#
					</a>
				</div>
			</div>
		</div>
	</cfif>
</cfoutput>