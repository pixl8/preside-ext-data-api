<cfscript>
	api    = rc.api ?: "";
	userId = rc.id  ?: "";
	cancelAction = prc.cancelAction ?: "";
	submitAction = prc.submitAction ?: "";
</cfscript>

<cfoutput>
	<form class="form form-horizontal" method="post" action="#submitAction#" id="add-data-api-user">
		<input type="hidden" name="api" value="#HtmlEditFormat( api )#" />
		<input type="hidden" name="user" value="#HtmlEditFormat( userId )#" />

		#renderForm(
			  formName         = "admin.dataapi.user.access.edit"
			, formId           = "add-data-api-user"
			, context          = "admin"
			, validationResult = rc.validationResult ?: ""
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#cancelAction#" class="btn btn-default">
					<i class="fa fa-fw fa-reply bigger-110"></i>
					#translateResource( "cms:cancel.btn" )#
				</a>
				<button type="submit" class="btn btn-success" tabindex="#getNextTabIndex()#">
					<i class="fa fa-fw fa-check bigger-110"></i>

					#translateResource( "dataapi:configure.access.form.save.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>