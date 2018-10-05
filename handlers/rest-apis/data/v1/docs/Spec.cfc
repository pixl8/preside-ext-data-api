/**
 * @restUri /spec/
 *
 */
component {

	property name="dataApiSpecService" inject="dataApiSpecService";

	public void function get() {
		restResponse.setData( dataApiSpecService.getSpec() );
	}

}