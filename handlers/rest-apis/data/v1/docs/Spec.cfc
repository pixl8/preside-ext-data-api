/**
 * @restUri /spec/
 *
 */
component {

	property name="dataApiSpecService" inject="dataApiSpecService";

	public void function get() {
		var api = event.getValue( name="dataApiNamespace", defaultValue="" );
		if ( !variables.keyExists( "_spec#api#" ) ) {
			variables[ "_spec#api#" ] = dataApiSpecService.getSpec();
		}

		restResponse.setData( variables[ "_spec#api#" ] );
	}

}