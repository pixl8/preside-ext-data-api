/**
 * @restUri /spec/
 *
 */
component {

	property name="dataApiSpecService" inject="dataApiSpecService";



	public void function get() {
		if ( !variables.keyExists( "_spec" ) ) {
			variables._spec = dataApiSpecService.getSpec();
		}

		restResponse.setData( variables._spec );
	}

}