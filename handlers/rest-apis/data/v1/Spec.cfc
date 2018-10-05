/**
 * @restUri /spec/
 *
 */
component {

	property name="dataApiService" inject="dataApiService";

	public void function get() {
		restResponse.setData( dataApiService.getSpec() );
	}

}