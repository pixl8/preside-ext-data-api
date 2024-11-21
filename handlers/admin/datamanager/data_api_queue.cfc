component {
	property name="loginService" inject="LoginService";

	private string function getAdditionalQueryStringForBuildAjaxListingLink( event, rc, prc, args={} ) {
		var qs = [];
		if ( Len( Trim( prc.activeRestUser ?: "" ) ) ) {
			ArrayAppend( qs, "subscriber=#prc.activeRestUser#" );
		}
		if ( StructKeyExists( prc, "filterNamespace" ) ) {
			ArrayAppend( qs, "namespace=#prc.filterNamespace#" );
		}
		return ArrayToList( qs, "&" );
	}
	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		args.extraFilters = args.extraFilters ?: [];

		if ( Len( Trim( rc.subscriber ?: "" ) ) ) {
			ArrayAppend( args.extraFilters, { filter={ subscriber=rc.subscriber } } );
		}
		if ( StructKeyExists( rc, "namespace" ) ) {
			ArrayAppend( args.extraFilters, { filter={ namespace=rc.namespace } } );
		}
	}

	private void function extraRecordActionsForGridListing( event, rc, prc, args={} ) {
		args.actions = args.actions ?: [];

		if ( Len( Trim( args.record.record_id ?: "" ) ) && Len( Trim( args.record.object_name ?: "" ) ) ) {
			for ( var action in args.actions ) {
				if ( ( action.contextKey ?: "" ) == "v" ) {
					action.link = event.buildAdminLink( objectName=args.record.object_name, recordId=args.record.record_id );
				}
			}
		}
	}
}