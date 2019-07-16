<cfscript>
	entities = args.entities ?: [];
	event.include( "/js/admin/specific/dataapiAccessTable/" );
</cfscript>
<cfoutput>

	<div class="table table-responsive">
		<table class="table table-striped data-api-access-table">
			<thead>
				<tr class="data-api-perms-super-header">
					<th>&nbsp;</th>
					<th colspan="5" class="text-center">#translateResource( "dataapi:configure.access.table.standard.rest.th" )#</th>
					<th colspan="4" class="text-center">#translateResource( "dataapi:configure.access.table.queue.th" )#</th>
				</tr>
				<tr>
					<th>&nbsp;</th>
					<th style="width:6em;">#translateResource( "dataapi:configure.access.table.standard.all.th" )#</th>
					<th style="width:6em;">#translateResource( "dataapi:configure.access.table.standard.read.th" )#</th>
					<th style="width:6em;">#translateResource( "dataapi:configure.access.table.standard.insert.th" )#</th>
					<th style="width:6em;">#translateResource( "dataapi:configure.access.table.standard.update.th" )#</th>
					<th style="width:6em;">#translateResource( "dataapi:configure.access.table.standard.delete.th" )#</th>
					<th style="width:6em;">#translateResource( "dataapi:configure.access.table.queue.all.th" )#</th>
					<th style="width:6em;">#translateResource( "dataapi:configure.access.table.queue.inserts.th" )#</th>
					<th style="width:6em;">#translateResource( "dataapi:configure.access.table.queue.updates.th" )#</th>
					<th style="width:6em;">#translateResource( "dataapi:configure.access.table.queue.deletes.th" )#</th>
				</tr>
			</thead>
			<tbody>
				<tr class="all">
					<th>#translateResource( "dataapi:configure.access.table.all.apis.th" )#</th>
					<td><input type="checkbox" data-subj="all"    data-cat="standard" name="all_all" class="all" checked></td>
					<td><input type="checkbox" data-subj="read"   data-cat="standard" name="all_read" checked></td>
					<td><input type="checkbox" data-subj="insert" data-cat="standard" name="all_insert" checked></td>
					<td><input type="checkbox" data-subj="update" data-cat="standard" name="all_update" checked></td>
					<td><input type="checkbox" data-subj="delete" data-cat="standard" name="all_delete" checked></td>
					<td><input type="checkbox" data-subj="all"    data-cat="queue"    name="all_queue_all"></td>
					<td><input type="checkbox" data-subj="insert" data-cat="queue"    name="all_queue_insert"></td>
					<td><input type="checkbox" data-subj="update" data-cat="queue"    name="all_queue_update"></td>
					<td><input type="checkbox" data-subj="delete" data-cat="queue"    name="all_queue_delete"></td>
				</tr>
				<cfloop array="#entities#" index="i" item="entity">
					<tr class="entity">
						<th><i class="fa fa-fw fa-arrow-right light-grey"></i> /#entity#</th>
						<td><input type="checkbox" data-subj="all"    data-cat="standard" name="#HtmlEditFormat( entity )#_all" class="all" checked></td>
						<td><input type="checkbox" data-subj="read"   data-cat="standard" name="#HtmlEditFormat( entity )#_read" checked></td>
						<td><input type="checkbox" data-subj="insert" data-cat="standard" name="#HtmlEditFormat( entity )#_insert" checked></td>
						<td><input type="checkbox" data-subj="update" data-cat="standard" name="#HtmlEditFormat( entity )#_update" checked></td>
						<td><input type="checkbox" data-subj="delete" data-cat="standard" name="#HtmlEditFormat( entity )#_delete" checked></td>
						<td><input type="checkbox" data-subj="all"    data-cat="queue"    name="#HtmlEditFormat( entity )#_queue_all"></td>
						<td><input type="checkbox" data-subj="insert" data-cat="queue"    name="#HtmlEditFormat( entity )#_queue_insert"></td>
						<td><input type="checkbox" data-subj="update" data-cat="queue"    name="#HtmlEditFormat( entity )#_queue_update"></td>
						<td><input type="checkbox" data-subj="delete" data-cat="queue"    name="#HtmlEditFormat( entity )#_queue_delete"></td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	</div>
</cfoutput>