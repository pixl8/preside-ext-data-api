/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @presideRestService.inject presideRestService
	 * @configService.inject      dataApiConfigurationService
	 *
	 */
	public any function init( required any presideRestService, required any configService ) {
		_setPresideRestService( arguments.presideRestService );
		_setConfigService( arguments.configService );

		return this;
	}

// PUBLIC API METHODS
	public void function onRestRequest( required any restRequest, required any restResponse ) {
		var tokens        = _getPresideRestService().extractTokensFromUri( restRequest );
		var entity        = tokens.entity ?: "";
		var configService = _getConfigService();

		if ( !configService.entityIsEnabled( entity ) ) {
			restResponse.setStatus( 404, "not found" );
			restRequest.finish();
		}

		if ( !configService.entityVerbIsSupported( entity, restRequest.getVerb() ) ) {
			restResponse.setError(
				  errorCode = 405
				, title     = "REST API Method not supported"
				, type      = "rest.method.unsupported"
				, message   = "The requested resource, [#restRequest.getUri()#], does not support the [#UCase( restRequest.getVerb() )#] method"
			);
			restRequest.finish();
		}
	}

	public any function getPaginatedRecords(
		  required string  entity
		, required numeric page
		, required numeric pageSize
	) {
		var configService  = _getConfigService();
		var dao            = $getPresideObject( configService.getEntityObject( arguments.entity ) );
		var selectDataArgs = {
			  maxRows            = pageSize
			, startRow           = ( ( arguments.page - 1 ) * arguments.pageSize ) + 1
			, selectFields       = configService.getSelectFields( arguments.entity )
			, fromVersionTable   = false
			, allowDraftVersions = false
		};

		if ( selectDataArgs.maxRows < 1 ) {
			selectDataArgs.maxRows = 100;
		}
		if ( selectDataArgs.startRow < 1 ) {
			selectDataArgs.startRow = 1;
		}

		var result  = { records=[] };
		var records = dao.selectData( argumentCollection=selectDataArgs );

		for( var r in records ) {
			result.records.append( r );
		}

		selectDataArgs.delete( "maxRows" );
		selectDataArgs.delete( "startRow" );
		selectDataArgs.recordCountOnly = true;

		result.totalCount = dao.selectData( argumentCollection=selectDataArgs );
		result.totalPages = Ceiling( result.totalCount / arguments.pageSize );
		result.prevPage   = arguments.page -1;
		result.nextPage   = arguments.page >= result.totalPages ? 0 : arguments.page+1;


		return result;
	}

	public any function getSingleRecord( required string entity, required string recordId ) {
		var configService  = _getConfigService();
		var dao            = $getPresideObject( configService.getEntityObject( arguments.entity ) );
		var selectDataArgs = {
			  id                 = arguments.recordId
			, selectFields       = configService.getSelectFields( arguments.entity )
			, fromVersionTable   = false
			, allowDraftVersions = false
		};

		var records = dao.selectData( argumentCollection=selectDataArgs );

		for( var r in records ) {
			return r;
		}

		return {};
	}

	public any function batchCreateRecords() {
		return { todo=true };
	}

	public any function batchUpdateRecords() {
		return { todo=true };
	}

	public any function batchDeleteRecords() {
		return { todo=true };
	}


	public any function updateSingleRecord() {
		return { todo=true };
	}

	public any function deleteSingleRecord() {
		return { todo=true };
	}


// PRIVATE HELPERS

// GETTERS AND SETTERS
	private any function _getPresideRestService() {
		return _presideRestService;
	}
	private void function _setPresideRestService( required any presideRestService ) {
		_presideRestService = arguments.presideRestService;
	}

	private any function _getConfigService() {
		return _configService;
	}
	private void function _setConfigService( required any configService ) {
		_configService = arguments.configService;
	}

}