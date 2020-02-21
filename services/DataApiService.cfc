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

		if ( restRequest.getUri().reFindNoCase( "^/(queue|spec|docs|swagger|html)/" ) ) {
			return;
		}

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
		, required array   fields
		,          struct  filters = {}
	) {
		var args = {
			  maxRows  = pageSize
			, startRow = ( ( arguments.page - 1 ) * arguments.pageSize ) + 1
			, orderby  = "datemodified"
			, filter   = {}
		};
		if ( args.maxRows < 1 ) {
			args.maxRows = 100;
		}
		if ( args.startRow < 1 ) {
			args.startRow = 1;
		}

		if ( arguments.filters.count() ) {
			var configService = _getConfigService();
			var filterFields = configService.getFilterFields( arguments.entity );

			for( var field in filterFields ) {
				var propName = configService.getPropertyNameFromFieldAlias( arguments.entity, field );
				if ( StructKeyExists( arguments.filters, field ) || StructKeyExists( arguments.filters, propName ) ) {
					args.filter[ propName ] = arguments.filters[ field ] ?: arguments.filters[ propName ];
				}
			}
		}

		var result = {
			  records    = _selectData( arguments.entity, args, arguments.fields )
			, totalCount = _selectData( arguments.entity, { recordCountOnly=true, filter=args.filter } )
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
		var objectName = _getConfigService().getEntityObject( arguments.entity );
		var dao        = $getPresideObject( objectName );
		var namespace  = _getInterceptorNamespace();
		var args       = {
			  data                      = _prepRecordForInsertAndUpdate( arguments.entity, arguments.record )
			, insertManyToManyRecords   = true
			, bypassTrivialInterceptors = true
		};

		$announceInterception( "preDataApiInsertData#namespace#", { insertDataArgs=args, entity=arguments.entity, record=arguments.record } );
		var newId = dao.insertData( argumentCollection=args );
		$announceInterception( "postDataApiInsertData#namespace#", { insertDataArgs=args, entity=arguments.entity, record=arguments.record, newId=newId } );

		return getSingleRecord( arguments.entity, newId, [] );
	}

	public any function batchUpdateRecords( required string entity, required array records ) {
		var objectName = _getConfigService().getEntityObject( arguments.entity );
		var dao        = $getPresideObject( objectName );
		var idField    = $getPresideObjectService().getIdField( objectName );
		var updated    = [];
		var recordId   = "";

		for( var record in records ) {
			recordId = record[ idField ] ?: "";
			if ( Len( Trim( recordId ) ) ) {
				if ( updateSingleRecord( arguments.entity, record, recordId ) ) {
					updated.append( getSingleRecord( entity, recordId, [] ) );
				}
			}
		}

		return updated;
	}

	public any function updateSingleRecord( required string entity, required struct data, required string recordId ) {
		var objectName = _getConfigService().getEntityObject( arguments.entity );
		var dao        = $getPresideObject( objectName );
		var namespace  = _getInterceptorNamespace();
		var args       = {
			  id                      = arguments.recordId
			, data                    = _prepRecordForInsertAndUpdate( arguments.entity, arguments.data )
			, updateManyToManyRecords = true
		};

		$announceInterception( "preDataApiUpdateData#namespace#", { updateDataArgs=args, entity=arguments.entity, recordId=arguments.recordId, data=arguments.data } );
		var recordsUpdated = dao.updateData( argumentCollection=args );
		$announceInterception( "postDataApiUpdateData#namespace#", { updateDataArgs=args, entity=arguments.entity, recordId=arguments.recordId, data=arguments.data } );


		return recordsUpdated;
	}

	public numeric function deleteSingleRecord( required string entity, required string recordId ) {
		var dao       = $getPresideObject( _getConfigService().getEntityObject( arguments.entity ) );
		var namespace = _getInterceptorNamespace();
		var args      = { id=arguments.recordId };

		$announceInterception( "preDataApiDeleteData#namespace#", { deleteDataArgs=args, entity=arguments.entity, recordId=arguments.recordId } );
		var recordsDeleted = dao.deleteData( argumentCollection=args );
		$announceInterception( "postDataApiDeleteData#namespace#", { deleteDataArgs=args, entity=arguments.entity, recordId=arguments.recordId } );

		return recordsDeleted;
	}

	public any function validateUpsertData( required string entity, required any data, boolean ignoreMissing=false, boolean isUpdate=false ) {
		var ruleset   = _getConfigService().getValidationRulesetForEntity( arguments.entity );
		var namespace = _getInterceptorNamespace();

		if ( IsArray( arguments.data ) ) {
			var result = { validated=true, validationResults=[] };
			for( var record in arguments.data ) {

				var prepped = _prepRecordForInsertAndUpdate( arguments.entity, record, arguments.isUpdate );
				$announceInterception( "preValidateUpsertData#namespace#", { validateUpsertDataArgs=prepped, entity=arguments.entity, data=record } );

				var validation = $getValidationEngine().validate(
					  ruleset       = ruleset
					, data          = prepped
					, ignoreMissing = arguments.ignoreMissing
				);

				if ( validation.validated() ) {
					result.validationResults.append({
						  record        = record
						, valid         = true
						, errorMessages = {}
					});

				} else {
					result.validationResults.append({
						  record        = record
						, valid         = false
						, errorMessages = _translateValidationErrors( validation )
					});

					result.validated = false;
				}
			}

			return result;
		}

		var prepped = _prepRecordForInsertAndUpdate( arguments.entity, arguments.data, arguments.isUpdate );
		$announceInterception( "preValidateUpsertData#namespace#", { validateUpsertDataArgs=prepped, entity=arguments.entity, data=arguments.data } );

		return _translateValidationErrors( $getValidationEngine().validate(
			  ruleset       = ruleset
			, data          = prepped
			, ignoreMissing = arguments.ignoreMissing
		) );
	}

	public string function i18nNamespaced(
		  required string uri
		,          string defaultValue = $getColdbox().getSetting( "UnknownTranslation" )
		,          array  data         = []
	) {
		var dataApiNamespace = $getRequestContext().getValue( name="dataApiNamespace", defaultValue="" );

		if ( len( dataApiNamespace ) ) {
			var nsArgs              = duplicate( arguments );
			    nsArgs.uri          = replaceNoCase( nsArgs.uri, ":", ":#dataApiNamespace#." );
			    nsArgs.defaultValue = "";
			var nsText              = $translateResource( argumentCollection=nsArgs );

			if ( len( nsText ) ) {
				return nsText;
			}
		}
		return $translateResource( argumentCollection=arguments );
	}


// PRIVATE HELPERS
	private string function _getInterceptorNamespace() {
		var dataApiNamespace = $getRequestContext().getValue( name="dataApiNamespace", defaultValue="" );
		if ( len( dataApiNamespace ) ) {
			return "_" & dataApiNamespace;
		}
		return "";
	}

	private any function _selectData( required string entity, required struct args, array fields=[] ) {
		var configService = _getConfigService();
		var objectName    = configService.getEntityObject( arguments.entity );
		var dao           = $getPresideObject( objectName );
		var namespace     = _getInterceptorNamespace();
		var fieldSettings = configService.getFieldSettings( arguments.entity );

		args.selectFields            = _prepareSelectFields( arguments.entity, objectName, configService.getSelectFields( arguments.entity ), arguments.fields );
		args.fromVersionTable        = false;
		args.orderBy                 = configService.getSelectSortOrder( arguments.entity );
		args.savedFilters            = configService.getSavedFilters( arguments.entity );
		args.allowDraftVersions      = false;
		args.autoGroupBy             = true;
		args.distinct                = true;
		args.recordCountOnly         = args.recordCountOnly ?: false;

		$announceInterception( "preDataApiSelectData#namespace#", { selectDataArgs=args, entity=arguments.entity } );

		if ( args.recordCountOnly ) {
			return dao.selectData( argumentCollection=args );
		}

		var records   = dao.selectData( argumentCollection=args );
		var processed = [];

		for( var record in records ) {
			processed.append( _processFields( record, fieldSettings ) );
		}
		$announceInterception( "postDataApiSelectData#namespace#", { selectDataArgs=args, entity=arguments.entity, data=processed } );

		return processed;
	}

	private struct function _processFields( required struct record, required struct fieldSettings ) {
		var processed = {};

		for( var field in record ) {
			var renderer = fieldSettings[ field ].renderer ?: "none";
			var alias    = fieldSettings[ field ].alias ?: field;

			processed[ alias ] = _renderField( record[ field ], renderer, fieldSettings[ field ] );
		}

		return processed;
	}

	private any function _renderField( required any value, required string renderer, struct fieldSettings={} ) {
		switch( renderer ) {
			case "date"           : return IsDate( arguments.value ) ? DateFormat( arguments.value, "yyyy-mm-dd" ) : NullValue();
			case "datetime"       : return IsDate( arguments.value ) ? DateTimeFormat( arguments.value, "yyyy-mm-dd HH:nn:ss" ) : NullValue();
			case "strictboolean"  : return IsBoolean( arguments.value ) && arguments.value ? true : false; // looks odd, but aimed at ensuring that we definitely get boolean values back
			case "nullableboolean": return IsBoolean( arguments.value ) ? ( arguments.value ? true : false ) : NullValue();
			case "array"          : return ListToArray( arguments.value );
			case "none":
			case "":
				return arguments.value;
		}

		if ( $getContentRendererService().rendererExists( renderer, "dataapi" ) ) {
			return $renderContent( renderer, arguments.value, "dataapi", arguments.fieldSettings );
		}

		return arguments.value;
	}

	private array function _prepareSelectFields( required string entity, required string objectName, required array defaultFields, required array suppliedFields ) {
		var filtered = [];
		var props    = $getPresideObjectService().getObjectProperties( arguments.objectName );

		if ( !suppliedFields.len() ) {
			filtered = arguments.defaultFields;
		} else {
			for( var field in suppliedFields ) {
				var propName = _getConfigService().getPropertyNameFromFieldAlias( arguments.entity, field );
				if ( defaultFields.find( LCase( field ) ) ) {
					filtered.append( field );
				} else if ( defaultFields.find( LCase( propName ) ) ) {
					filtered.append( propName );
				}
			}
		}

		var prepared = [];
		for( var field in filtered ) {
			if ( ( props[ field ].relationship ?: "" ) == "many-to-many" ) {
				prepared.append( "group_concat( distinct `#field#`.`id` ) as `#field#`" );
			} else {
				prepared.append( field );
			}
		}

		return prepared;
	}

	private struct function _prepRecordForInsertAndUpdate( required string entity, required struct record, boolean isUpdate=false ) {
		var prepped       = {};
		var allowedFields = _getConfigService().getUpsertFields( arguments.entity );
		var fieldSettings = _getConfigService().getFieldSettings( arguments.entity );

		for( var field in allowedFields ) {
			var alias = fieldSettings[ field ].alias ?: field;
			if ( record.keyExists( alias ) ) {
				if ( IsSimpleValue( arguments.record[ alias ] ) ) {
					prepped[ field ] = arguments.record[ alias ];
				} else if ( IsArray( arguments.record[ alias ] ) ) {
					prepped[ field ] = arguments.record[ alias ].toList();
				}
			}
		}

		if( arguments.isUpdate && len( arguments.record.id ?: '' ) ) {
			prepped.id = arguments.record.id;
		}

		return prepped;
	}

	private array function _translateValidationErrors( required any validationResult ) {
		var messages = validationResult.getMessages();
		var translated = [];

		for( var fieldName in messages ) {
			translated.append( { field=fieldName, message=i18nNamespaced(
				  uri          = messages[ fieldName ].message ?: ""
				, defaultValue = messages[ fieldName ].message ?: ""
				, data         = messages[ fieldName ].params  ?: []
			) } );
		}

		return translated;
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