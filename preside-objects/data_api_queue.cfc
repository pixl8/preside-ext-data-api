/**
 * @versioned      false
 * @nolabel        true
 * @noDateModified true
 * @feature        dataApiQueue
 *
 * @dataManagerEnabled              true
 * @datamanagerAllowedOperations    read
 * @datamanagerDefaultSortOrder     order_number desc
 */
component {
	property name="object_name"     type="string"  dbtype="varchar" maxlength=100 required=true  indexes="object_name" renderer="DataApiQueueObjectName";
	property name="namespace"       type="string"  dbtype="varchar" maxlength=50  required=false indexes="namespace,api_queue_poll|3";
	property name="queue_name"      type="string"  dbtype="varchar" maxlength=50  required=false indexes="queuename,api_queue_poll|2";
	property name="record_id"       type="string"  dbtype="varchar" maxlength=100 required=true  indexes="record_id";
	property name="operation"       type="string"  dbtype="varchar" maxlength=10  required=true  indexes="operation"   enum="dataApiQueueOperation";
	property name="order_number"    type="numeric" dbtype="int"                   required=true  indexes="ordernumber,api_queue_poll|4" generate="insert" generator="method:getNextOrderNumber";
	property name="is_checked_out"  type="boolean" dbtype="boolean"               required=false indexes="checkedout" default=false;
	property name="check_out_date"  type="date"    dbtype="datetime"              required=false indexes="checkedoutdate";
	property name="data"            type="string"  dbtype="longtext"              required=false;

	property name="subscriber" relatedto="rest_user" relationship="many-to-one" required=true indexes="api_queue_poll|1";

	public numeric function getNextOrderNumber() {
		var record = this.selectData( selectFields = [ "Max( order_number ) as order_number" ] );

		return Val( record.order_number ) + 1;
	}
}