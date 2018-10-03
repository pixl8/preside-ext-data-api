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

		$getRequestContext().cachePage( false );
	}

	public any function getPaginatedRecords(
		  required string  entity
		, required numeric page
		, required numeric pageSize
		, required array   fields
	) {
		var args = {
			  maxRows  = pageSize
			, startRow = ( ( arguments.page - 1 ) * arguments.pageSize ) + 1
			, orderby  = "datemodified"
		};
		if ( args.maxRows < 1 ) {
			args.maxRows = 100;
		}
		if ( args.startRow < 1 ) {
			args.startRow = 1;
		}

		var result = {
			  records    = _selectData( arguments.entity, args, arguments.fields )
			, totalCount = _selectData( arguments.entity, { recordCountOnly=true } )
		};


		result.totalPages = Ceiling( result.totalCount / arguments.pageSize );
		result.prevPage   = arguments.page -1;
		result.nextPage   = arguments.page >= result.totalPages ? 0 : arguments.page+1;

		return result;
	}

	public any function getSingleRecord( required string entity, required string recordId, required array fields ) {
		var records  = _selectData( arguments.entity, { id=arguments.recordId }, arguments.fields );

		return records[ 1 ] ?: {};
	}

	public array function createRecords( required string entity, required array records ) {
		var created = [];

		for( var record in records ) {
			created.append( createRecord( entity, record ) );
		}

		return created;
	}

	public struct function createRecord( required string entity, required any record ) {
		// todo, check incoming fields, etc.
		var objectName = _getConfigService().getEntityObject( arguments.entity );
		var dao        = $getPresideObject( objectName );
		var newId      = dao.insertData( arguments.record );

		return getSingleRecord( arguments.entity, newId, [] );
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
	private any function _selectData( required string entity, required struct args, array fields=[] ) {
		var configService       = _getConfigService();
		var dao                 = $getPresideObject( configService.getEntityObject( arguments.entity ) );
		var selectFieldSettings = configService.getSelectFieldSettings( arguments.entity );

		args.selectFields            = _filterFields( configService.getSelectFields( arguments.entity ), arguments.fields );
		args.fromVersionTable        = false;
		args.orderBy                 = configService.getSelectSortOrder( arguments.entity );
		args.allowDraftVersions      = false;
		args.autoGroupBy             = true;
		args.distinct                = true;
		args.recordCountOnly         = args.recordCountOnly ?: false;

		if ( args.recordCountOnly ) {
			return dao.selectData( argumentCollection=args );
		}

		var records   = dao.selectData( argumentCollection=args );
		var processed = [];

		for( var record in records ) {
			processed.append( _processFields( record, selectFieldSettings ) );
		}

		return processed;
	}

	private struct function _processFields( required struct record, required struct fieldSettings ) {
		var processed = {};

		for( var field in record ) {
			var renderer = fieldSettings[ field ].renderer ?: "none";
			var alias    = fieldSettings[ field ].alias ?: field;

			processed[ alias ] = _renderField( record[ field ], renderer );
		}

		return processed;
	}

	private any function _renderField( required any value, required string renderer ) {
		switch( renderer ) {
			case "date"           : return IsDate( arguments.value ) ? DateFormat( arguments.value, "yyyy-mm-dd" ) : NullValue();
			case "datetime"       : return IsDate( arguments.value ) ? DateTimeFormat( arguments.value, "yyyy-mm-dd HH:nn:ss" ) : NullValue();
			case "strictboolean"  : return IsBoolean( arguments.value ) && arguments.value;
			case "nullableboolean": return IsBoolean( arguments.value ) ? arguments.value : NullValue();
			case "array"          : return ListToArray( arguments.value );
			case "none":
			case "":
				return arguments.value;
		}

		if ( $getContentRendererService().rendererExists( renderer, "dataapi" ) ) {
			return $renderContent( renderer, arguments.value, "dataapi" );
		}

		return arguments.value;
	}

	private array function _filterFields( required array defaultFields, required array suppliedFields ) {
		if ( !suppliedFields.len() ) {
			return arguments.defaultFields;
		}

		var filteredFields = [];

		for( var field in suppliedFields ) {
			if ( defaultFields.find( LCase( field ) ) ) {
				filteredFields.append( field );
			}
		}

		return filteredFields;
	}

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