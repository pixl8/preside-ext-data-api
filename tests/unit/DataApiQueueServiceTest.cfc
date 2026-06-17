component extends="tests.BaseTest" {

	function run() {
		describe( "queueRequired()", function(){
			it( "should return true for API-enabled objects", function(){
				var configSvc = _getConfigService();
				var apiSvc    = _getDataApiService( configSvc );
				var svc       = _getQueueService( configSvc, apiSvc );

				expect( svc.queueRequired( objectName="test_contact" ) ).toBeTrue();
			} );

			it( "should return false for disabled objects", function(){
				var configSvc = _getConfigService();
				var apiSvc    = _getDataApiService( configSvc );
				var svc       = _getQueueService( configSvc, apiSvc );

				expect( svc.queueRequired( objectName="disabled_object" ) ).toBeFalse();
			} );
		} );

		describe( "getSubscribers()", function(){
			it( "should merge default and object-specific subscribers", function(){
				var configSvc   = _getConfigService();
				var apiSvc      = _getDataApiService( configSvc );
				var svc         = _getQueueService( configSvc, apiSvc );
				var settingsDao = _mockPresideObject( "data_api_user_settings" );
				var selectCall  = 0;

				settingsDao.$( "selectData" ).$callback( function() {
					selectCall++;
					if ( selectCall == 1 ) {
						return _queryFromRows( "user", "varchar", [ { user="default-user" } ] );
					}
					return _queryFromRows( "user,subscribe_to_updates", "varchar,boolean", [ { user="specific-user", subscribe_to_updates=true } ] );
				} );
				svc.$( "$getPresideObject" ).$args( "data_api_user_settings" ).$results( settingsDao );

				var subscribers = svc.getSubscribers( objectName="test_contact", operation="update" );

				expect( subscribers ).toInclude( "default-user" );
				expect( subscribers ).toInclude( "specific-user" );
			} );

			it( "should exclude the current API user from subscribers", function(){
				var configSvc   = _getConfigService();
				var apiSvc      = _getDataApiService( configSvc );
				var svc         = _getQueueService( configSvc, apiSvc );
				var settingsDao = _mockPresideObject( "data_api_user_settings" );
				var rc          = _mockRequestContext();
				var selectCall  = 0;

				rc.$( "getRestRequestUser" ).$results( "current-user" );
				svc.$( "$getRequestContext" ).$results( rc );

				settingsDao.$( "selectData" ).$callback( function() {
					selectCall++;
					if ( selectCall == 1 ) {
						return _queryFromRows( "user", "varchar", [ { user="current-user" }, { user="other-user" } ] );
					}
					return QueryNew( "user,subscribe_to_inserts", "varchar,boolean" );
				} );
				svc.$( "$getPresideObject" ).$args( "data_api_user_settings" ).$results( settingsDao );

				var subscribers = svc.getSubscribers( objectName="test_contact", operation="insert" );

				expect( subscribers ).notToInclude( "current-user" );
				expect( subscribers ).toInclude( "other-user" );
			} );
		} );

		describe( "getNextQueuedItems()", function(){
			it( "should checkout queue items and return structured queue data", function(){
				var configSvc  = _getConfigService();
				var apiSvc     = _getDataApiService( configSvc );
				var svc        = _getQueueService( configSvc, apiSvc );
				var queueDao   = _mockPresideObject( "data_api_queue" );
				var contactDao = _mockPresideObject( "test_contact" );
				var recordId   = CreateUUID();
				var queueQuery = _queryFromRows(
					  "id,object_name,record_id,operation,data,dateCreated"
					, "varchar,varchar,varchar,varchar,varchar,timestamp"
					, [ {
						  id          = CreateUUID()
						, object_name = "test_contact"
						, record_id   = recordId
						, operation   = "insert"
						, data        = ""
						, dateCreated = Now()
					} ]
				);
				var queueSelectCall = 0;

				queueDao.$( "selectData" ).$callback( function() {
					queueSelectCall++;
					if ( queueSelectCall == 1 ) {
						return 1;
					}
					return queueQuery;
				} );
				queueDao.$( "updateData" ).$results( 1 );
				contactDao.$( "selectData" ).$results( [ { id=recordId, label="Queued", datemodified=Now(), datecreated=Now(), is_active=true, status="" } ] );

				svc.$( "$getPresideObject" ).$callback( function( objectName ) {
					if ( arguments.objectName == "data_api_queue" ) {
						return queueDao;
					}
					if ( arguments.objectName == "test_contact" ) {
						return contactDao;
					}
					return _mockPresideObject( arguments.objectName );
				} );

				apiSvc.$( "getSingleRecord" ).$results( { id=recordId, name="Queued" } );

				var result = svc.getNextQueuedItems( subscriber="test-subscriber", queueName="default" );

				expect( result.queueSize ).toBe( 1 );
				expect( result.data.operation ).toBe( "insert" );
				expect( result.data.entity ).toBe( "contact" );
				expect( result.data.record.name ).toBe( "Queued" );
			} );
		} );

		describe( "queueInsert()", function(){
			it( "should queue inserts for subscribed users", function(){
				var configSvc   = _getConfigService();
				var apiSvc      = _getDataApiService( configSvc );
				var svc         = _getQueueService( configSvc, apiSvc );
				var queueDao    = _mockPresideObject( "data_api_queue" );
				var settingsDao = _mockPresideObject( "data_api_user_settings" );
				var selectCall  = 0;

				settingsDao.$( "selectData" ).$callback( function() {
					selectCall++;
					if ( selectCall == 1 ) {
						return _queryFromRows( "user", "varchar", [ { user="subscriber-one" } ] );
					}
					return QueryNew( "user,subscribe_to_inserts", "varchar,boolean" );
				} );
				queueDao.$( "insertData" ).$results( CreateUUID() );

				svc.$( "$getPresideObject" ).$callback( function( objectName ) {
					if ( arguments.objectName == "data_api_queue" ) {
						return queueDao;
					}
					if ( arguments.objectName == "data_api_user_settings" ) {
						return settingsDao;
					}
					return _mockPresideObject( arguments.objectName );
				} );

				svc.queueInsert(
					  objectName = "test_contact"
					, newId      = CreateUUID()
					, data       = { label="New contact" }
				);

				expect( queueDao.$count( "insertData" ) ).toBe( 1 );
			} );
		} );

		describe( "getDeletedRecordIds()", function(){
			it( "should return ids for records matched by the delete filter", function(){
				var configSvc  = _getConfigService();
				var apiSvc     = _getDataApiService( configSvc );
				var svc        = _getQueueService( configSvc, apiSvc );
				var contactDao = _mockPresideObject( "test_contact" );
				var deletedId  = CreateUUID();

				contactDao.$( "selectData" ).$results( _queryFromRows( "id", "varchar", [ { id=deletedId } ] ) );
				svc.$( "$getPresideObject" ).$args( "test_contact" ).$results( contactDao );

				var ids = svc.getDeletedRecordIds(
					  objectName = "test_contact"
					, filter     = { id=deletedId }
				);

				expect( ArrayLen( ids ) ).toBe( 1 );
				expect( ids[ 1 ] ).toBe( deletedId );
			} );
		} );
	}

}
