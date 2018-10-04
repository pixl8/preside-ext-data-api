/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public void function queueInsert(
		  string objectName = ""
		, string id         = ""
	) {
		if ( objectName.len() && id.len() ) {
			var subscribers = getSubscribers( arguments.objectName, "insert" );

			if ( subscribers.len() ) {
				var dao = $getPresideObject( "data_api_queue" );
				for( var subscriber in subscribers ) {
					dao.insertData( {
						  object_name = arguments.objectName
						, record_id   = arguments.id
						, subscriber  = subscriber
						, operation   = "insert"
					} );
				}
			}
		}
	}

	public void function queueUpdate(
		  string objectName = ""
		, string id         = ""
	) {
		if ( objectName.len() && id.len() ) {
			var subscribers = getSubscribers( arguments.objectName, "update" );

			if ( subscribers.len() ) {
				var dao = $getPresideObject( "data_api_queue" );
				for( var subscriber in subscribers ) {
					dao.insertData( {
						  object_name = arguments.objectName
						, record_id   = arguments.id
						, subscriber  = subscriber
						, operation   = "update"
					} );
				}
			}
		}
	}

	public void function queueDelete(
		  string objectName = ""
		, string id         = ""
	) {
		if ( objectName.len() && id.len() ) {
			var subscribers = getSubscribers( arguments.objectName, "delete" );

			if ( subscribers.len() ) {
				var dao = $getPresideObject( "data_api_queue" );
				for( var subscriber in subscribers ) {
					dao.insertData( {
						  object_name = arguments.objectName
						, record_id   = arguments.id
						, subscriber  = subscriber
						, operation   = "delete"
					} );
				}
			}
		}
	}

	public array function getSubscribers( required string objectName, required string operation ) {
		var currentApiUser = $getRequestContext().getValue( "restUserId", "" );
		var subscribers    = []; // todo, get from DB

		if ( currentApiUser.len() ) {
			subscribers.delete( currentApiUser );
		}

		return subscribers;
	}


// PRIVATE HELPERS

// GETTERS AND SETTERS

}