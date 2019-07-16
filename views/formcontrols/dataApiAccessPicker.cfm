<cfscript>
	entities = args.entities ?: [];
	event.include( "/js/admin/specific/dataapiAccessTable/" )
	     .include( "/css/admin/specific/dataapiAccessTable/" );
</cfscript>
<cfoutput>

	<div class="table table-responsive">
		<table class="table data-api-access-table">
			<thead>
				<tr class="data-api-perms-super-header">
					<th>&nbsp;</th>
					<th colspan="5" class="text-center stand first">#translateResource( "dataapi:configure.access.table.standard.rest.th" )#</th>
					<th colspan="4" class="text-center queue first">#translateResource( "dataapi:configure.access.table.queue.th" )#</th>
				</tr>
				<tr>
					<th class="resource-header">&nbsp;</th>
					<th class="stand first all">#translateResource( "dataapi:configure.access.table.standard.all.th" )#</th>
					<th class="stand">#translateResource( "dataapi:configure.access.table.standard.read.th" )#</th>
					<th class="stand">#translateResource( "dataapi:configure.access.table.standard.insert.th" )#</th>
					<th class="stand">#translateResource( "dataapi:configure.access.table.standard.update.th" )#</th>
					<th class="stand">#translateResource( "dataapi:configure.access.table.standard.delete.th" )#</th>
					<th class="queue first all">#translateResource( "dataapi:configure.access.table.queue.all.th" )#</th>
					<th class="queue">#translateResource( "dataapi:configure.access.table.queue.inserts.th" )#</th>
					<th class="queue">#translateResource( "dataapi:configure.access.table.queue.updates.th" )#</th>
					<th class="queue">#translateResource( "dataapi:configure.access.table.queue.deletes.th" )#</th>
				</tr>
			</thead>
			<tbody>
				<tr class="all">
					<th class="resource-header all">#translateResource( "dataapi:configure.access.table.all.apis.th" )#</th>
					<td class="stand first"><input type="checkbox" data-subj="all"    data-cat="standard" name="all_all" class="all" checked></td>
					<td class="stand"><input type="checkbox" data-subj="read"   data-cat="standard" name="all_read" checked></td>
					<td class="stand"><input type="checkbox" data-subj="insert" data-cat="standard" name="all_insert" checked></td>
					<td class="stand"><input type="checkbox" data-subj="update" data-cat="standard" name="all_update" checked></td>
					<td class="stand"><input type="checkbox" data-subj="delete" data-cat="standard" name="all_delete" checked></td>
					<td class="queue first"><input type="checkbox" data-subj="all"    data-cat="queue"    name="all_queue_all"></td>
					<td class="queue"><input type="checkbox" data-subj="insert" data-cat="queue"    name="all_queue_insert"></td>
					<td class="queue"><input type="checkbox" data-subj="update" data-cat="queue"    name="all_queue_update"></td>
					<td class="queue"><input type="checkbox" data-subj="delete" data-cat="queue"    name="all_queue_delete"></td>
				</tr>
				<cfloop array="#entities#" index="i" item="entity">
					<tr class="entity">
						<th><i class="fa fa-fw fa-angle-double-right light-grey"></i> <code>/#entity#</code></th>
						<td class="stand first"><input type="checkbox" data-subj="all"    data-cat="standard" name="#HtmlEditFormat( entity )#_all" class="all" checked></td>
						<td class="stand"><input type="checkbox" data-subj="read"   data-cat="standard" name="#HtmlEditFormat( entity )#_read" checked></td>
						<td class="stand"><input type="checkbox" data-subj="insert" data-cat="standard" name="#HtmlEditFormat( entity )#_insert" checked></td>
						<td class="stand"><input type="checkbox" data-subj="update" data-cat="standard" name="#HtmlEditFormat( entity )#_update" checked></td>
						<td class="stand"><input type="checkbox" data-subj="delete" data-cat="standard" name="#HtmlEditFormat( entity )#_delete" checked></td>
						<td class="queue first"><input type="checkbox" data-subj="all"    data-cat="queue"    name="#HtmlEditFormat( entity )#_queue_all"></td>
						<td class="queue"><input type="checkbox" data-subj="insert" data-cat="queue"    name="#HtmlEditFormat( entity )#_queue_insert"></td>
						<td class="queue"><input type="checkbox" data-subj="update" data-cat="queue"    name="#HtmlEditFormat( entity )#_queue_update"></td>
						<td class="queue"><input type="checkbox" data-subj="delete" data-cat="queue"    name="#HtmlEditFormat( entity )#_queue_delete"></td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	</div>
</cfoutput>