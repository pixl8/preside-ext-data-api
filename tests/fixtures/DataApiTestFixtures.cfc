component {

	public struct function getObjectFixtures() {
		return {
			  test_contact = {
				  attributes = {
					  dataApiEnabled        = true
					, dataApiEntityName     = "contact"
					, dataApiVerbs          = "get,post,put,delete"
					, dataApiCategory       = "crm"
					, dataApiQueueEnabled   = true
					, dataApiQueue          = "default"
					, dbFieldlist           = "id,label,datemodified,datecreated,is_active,status"
				  }
				, properties = {
					  id           = { type="string" , dbtype="varchar"  , required=true }
					, label        = { type="string" , dbtype="varchar"  , dataApiAlias="name" }
					, datemodified = { type="date"   , dbtype="datetime" }
					, datecreated  = { type="date"   , dbtype="datetime" }
					, is_active    = { type="boolean", dbtype="boolean"   }
					, status       = { type="string" , dbtype="varchar"  , enum="contact_status" }
				  }
			  }
			, cursor_contact = {
				  attributes = {
					  dataApiEnabled        = true
					, dataApiEntityName     = "cursor_contact"
					, dataApiPaginationMode = "cursor"
					, dataApiSortOrder      = "datemodified desc"
					, dbFieldlist           = "id,label,datemodified,datecreated"
				  }
				, properties = {
					  id           = { type="string", dbtype="varchar"  , required=true }
					, label        = { type="string", dbtype="varchar"  }
					, datemodified = { type="date"  , dbtype="datetime" }
					, datecreated  = { type="date"  , dbtype="datetime" }
				  }
			  }
			, offset_contact = {
				  attributes = {
					  dataApiEnabled        = true
					, dataApiEntityName     = "offset_contact"
					, dataApiPaginationMode = "offset"
					, dbFieldlist           = "id,label,datemodified,datecreated"
				  }
				, properties = {
					  id           = { type="string", dbtype="varchar"  , required=true }
					, label        = { type="string", dbtype="varchar"  }
					, datemodified = { type="date"  , dbtype="datetime" }
					, datecreated  = { type="date"  , dbtype="datetime" }
				  }
			  }
			, get_only_contact = {
				  attributes = {
					  dataApiEnabled    = true
					, dataApiEntityName = "readonly_contact"
					, dataApiVerbs      = "get"
					, dbFieldlist       = "id,label,datemodified,datecreated"
				  }
				, properties = {
					  id           = { type="string", dbtype="varchar" , required=true }
					, label        = { type="string", dbtype="varchar" }
					, datemodified = { type="date"  , dbtype="datetime" }
					, datecreated  = { type="date"  , dbtype="datetime" }
				  }
			  }
			, namespace_contact = {
				  attributes = {
					  "dataApiEnabled:myApi"        = true
					, "dataApiEntityName:myApi"     = "ns_contact"
					, "dataApiVerbs:myApi"          = "get"
					, "dataApiPaginationMode:myApi" = "offset"
					, "dataApiAllowIdInsert:myApi"  = true
					, dbFieldlist                   = "id,label,datemodified,datecreated"
				  }
				, properties = {
					  id           = { type="string", dbtype="varchar" , required=true }
					, label        = { type="string", dbtype="varchar" , "dataApiAlias:myApi"="title" }
					, datemodified = { type="date"  , dbtype="datetime" }
					, datecreated  = { type="date"  , dbtype="datetime" }
				  }
			  }
			, disabled_object = {
				  attributes = {
					  dataApiEnabled = false
					, dbFieldlist    = "id,label"
				  }
				, properties = {
					  id    = { type="string", dbtype="varchar", required=true }
					, label = { type="string", dbtype="varchar" }
				  }
			  }
			, vrsn_test = {
				  attributes = {
					  dataApiEnabled = true
					, dbFieldlist    = "id"
				  }
				, properties = {
					  id = { type="string", dbtype="varchar", required=true }
				  }
			  }
		};
	}

	public struct function loadI18nProperties( string path="" ) {
		var propsPath = Len( arguments.path ) ? arguments.path : ExpandPath( "/dataApi/i18n/dataapi.properties" );
		var props     = CreateObject( "java", "java.util.Properties" );
		var fis       = CreateObject( "java", "java.io.FileInputStream" ).init( propsPath );

		props.load( fis );
		fis.close();

		var bundle = {};
		var keys   = props.propertyNames();

		while ( keys.hasMoreElements() ) {
			var key = keys.nextElement();
			bundle[ key ] = props.getProperty( key );
		}

		return bundle;
	}

	public string function translateFromBundle( required struct bundle, required string uri, string defaultValue="" ) {
		var key = ReReplaceNoCase( arguments.uri, "^dataapi:", "" );

		if ( arguments.bundle.keyExists( key ) && Len( Trim( arguments.bundle[ key ] ) ) ) {
			return arguments.bundle[ key ];
		}

		return arguments.defaultValue;
	}

}
