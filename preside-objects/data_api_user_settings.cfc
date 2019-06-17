/**
 * @versioned false
 * @nolabel   true
 */
component {
	property name="user" relatedto="rest_user" relationship="many-to-one" required=true uniqueindexes="userobject|1";
	property name="namespace"   type="string" dbtype="varchar" maxlength=50  required=false indexes="namespace"   uniqueindexes="userobject|2";
	property name="object_name" type="string" dbtype="varchar" maxlength=100 required=false indexes="object_name" uniqueindexes="userobject|3";

	property name="subscribe_to_deletes" type="boolean" dbtype="boolean" required=true indexes="deletes";
	property name="subscribe_to_updates" type="boolean" dbtype="boolean" required=true indexes="updates";
	property name="subscribe_to_inserts" type="boolean" dbtype="boolean" required=true indexes="inserts";

	property name="access_allowed" type="boolean" dbtype="boolean" required=true indexes="access";
	property name="get_allowed"    type="boolean" dbtype="boolean" required=true indexes="get";
	property name="put_allowed"    type="boolean" dbtype="boolean" required=true indexes="put";
	property name="delete_allowed" type="boolean" dbtype="boolean" required=true indexes="delete";
	property name="post_allowed"   type="boolean" dbtype="boolean" required=true indexes="post";
}