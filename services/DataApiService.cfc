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
		,          struct  filters        = {}
		,          string  paginationMode = ""
	) {
		var mode              = Len( Trim( arguments.paginationMode ) ) ? arguments.paginationMode : _getConfigService().getEntityDefaultPaginationMode( arguments.entity );
		var countTotalRecords = _getConfigService().paginationModeCountsTotalRecords( mode );
		var args              = {
			  maxRows      = pageSize
			, startRow     = ( ( arguments.page - 1 ) * arguments.pageSize ) + 1
			, orderby      = "datemodified"
			, filter       = {}
			, extraFilters = []
		};
		if ( args.maxRows < 1 ) {
			args.maxRows = 100;
		}
		if ( args.startRow < 1 ) {
			args.startRow = 1;
		}

		_prepareFilters( arguments.entity, arguments.filters, args );

		var result = {
			  prevPage = arguments.page - 1
			, nextPage = 0
		};

		if ( countTotalRecords ) {
			result.records = _selectData( arguments.entity, args, arguments.fields );

			args.recordCountOnly = true;
			structDelete( args, "maxRows" );

			result.totalCount = _selectData( arguments.entity, args, arguments.fields );
			result.totalPages = Ceiling( result.totalCount / arguments.pageSize );
			result.nextPage   = arguments.page >= result.totalPages ? 0 : arguments.page + 1;
		} else {
			var effectivePageSize = args.maxRows;

			args.maxRows   = effectivePageSize + 1;
			result.records = _selectData( arguments.entity, args, arguments.fields );

			if ( ArrayLen( result.records ) > effectivePageSize ) {
				ArrayDeleteAt( result.records, ArrayLen( result.records ) );
				result.nextPage = arguments.page + 1;
			}
		}

		return result;
	}

	public struct function getCursorRecords(
		  required string  entity
		, required numeric pageSize
		, required array   fields
		,          string  cursor  = ""
		,          struct  filters = {}
	) {
		var configService = _getConfigService();
		var objectName    = configService.getEntityObject( arguments.entity );
		var idField       = $getPresideObjectService().getIdField( objectName );
		var sort          = _resolveCursorSort( arguments.entity, idField );
		var pageSize      = arguments.pageSize < 1 ? 100 : arguments.pageSize;

		var args = {
			  maxRows      = pageSize + 1
			, filter       = {}
			, extraFilters = []
		};

		_prepareFilters( arguments.entity, arguments.filters, args );

		if ( Len( Trim( arguments.cursor ) ) ) {
			_appendKeysetFilter( objectName, sort, _decodeCursor( arguments.cursor, sort ), args );
		}

		return _selectCursorPage(
			  entity   = arguments.entity
			, args     = args
			, fields   = arguments.fields
			, sort     = sort
			, pageSize = pageSize
		);
	}

	public any function getSingleRecord( required string entity, required string recordId, required array fields ) {
		var records  = _selectData( arguments.entity, { id=arguments.recordId }, arguments.fields );

		return records[ 1 ] ?: {};
	}

	public array function getMultipleRecords( required string entity, required string recordIds, array fields=[] ) {
		return _selectData( arguments.entity, { filter={ id=listToArray( arguments.recordIds ) } }, arguments.fields );
	}

	public any function createRecords( required string entity, required array records ) {
		var created = [];
		var result  = "";

		for( var record in records ) {
			result = createRecord( entity, record );
			if ( !IsEmpty( result ) ) {
				ArrayAppend( created, result );
			}
		}

		return ArrayLen( created ) ? created : "";
	}

	public any function createRecord( required string entity, required any record ) {
		var objectName = _getConfigService().getEntityObject( arguments.entity );
		var dao        = $getPresideObject( objectName );
		var namespace  = _getInterceptorNamespace();
		var args       = {
			  data                      = _prepRecordForInsertAndUpdate( arguments.entity, arguments.record )
			, insertManyToManyRecords   = true
			, bypassTrivialInterceptors = true
		};

		var interceptDataArgs = { insertDataArgs=args, entity=arguments.entity, record=arguments.record };

		interceptDataArgs.responseType = _getConfigService().entityResponseTypeOnInsert( arguments.entity ); // default config on api or object level

		$announceInterception( "preDataApiInsertData#namespace#", interceptDataArgs );
		var newId = dao.insertData( argumentCollection=args );
		interceptDataArgs.newId = newId;
		$announceInterception( "postDataApiInsertData#namespace#", interceptDataArgs );

		interceptDataArgs.responseType = _getConfigService().validateResponseType( interceptDataArgs.responseType );

		if ( _getConfigService().isEmptyResponseType( interceptDataArgs.responseType ) ) {
			return "";
		} else if ( _getConfigService().isIdOnlyResponseType( interceptDataArgs.responseType ) ) {
			return newId;
		}

		return getSingleRecord( arguments.entity, newId, [] );
	}

	public any function batchUpdateRecords( required string entity, required array records ) {
		var namespace  = _getInterceptorNamespace();
		var objectName = _getConfigService().getEntityObject( arguments.entity );
		var dao        = $getPresideObject( objectName );
		var idField    = $getPresideObjectService().getIdField( objectName );
		var updated    = [];
		var recordId   = "";

		var interceptDataArgs = { entity=arguments.entity, records=arguments.records };

		interceptDataArgs.responseType = _getConfigService().entityResponseTypeOnUpdate( arguments.entity ); // default config on api or object level

		$announceInterception( "preDataApiBatchUpdateRecords#namespace#", interceptDataArgs );

		interceptDataArgs.responseType = _getConfigService().validateResponseType( interceptDataArgs.responseType );

		var isEmptyResponseType  = _getConfigService().isEmptyResponseType( interceptDataArgs.responseType );
		var isIdOnlyResponseType = _getConfigService().isIdOnlyResponseType( interceptDataArgs.responseType );

		for( var record in records ) {
			recordId = record[ idField ] ?: "";
			if ( Len( Trim( recordId ) ) ) {
				if ( updateSingleRecord( arguments.entity, record, recordId ) ) {
					if ( isEmptyResponseType ) {
						continue;
					} else if ( isIdOnlyResponseType ) {
						ArrayAppend( updated, recordId );
					} else {
						ArrayAppend( updated, getSingleRecord( entity, recordId, [] ) );
					}
				}
			}
		}

		interceptDataArgs.updated = updated;

		$announceInterception( "postDataApiBatchUpdateRecords#namespace#", interceptDataArgs );

		interceptDataArgs.responseType = _getConfigService().validateResponseType( interceptDataArgs.responseType );

		return _getConfigService().isEmptyResponseType( interceptDataArgs.responseType ) ? "" : interceptDataArgs.updated;
	}

	public any function updateSingleRecord( required string entity, required struct data, required string recordId, boolean returnResponse=false ) {
		var objectName = _getConfigService().getEntityObject( arguments.entity );
		var dao        = $getPresideObject( objectName );
		var namespace  = _getInterceptorNamespace();
		var args       = {
			  id                      = arguments.recordId
			, data                    = _prepRecordForInsertAndUpdate( arguments.entity, arguments.data )
			, updateManyToManyRecords = true
		};

		var interceptDataArgs = { updateDataArgs=args, entity=arguments.entity, recordId=arguments.recordId, data=arguments.data };

		interceptDataArgs.responseType = _getConfigService().entityResponseTypeOnUpdate( arguments.entity ); // default config on api or object level

		$announceInterception( "preDataApiUpdateData#namespace#", interceptDataArgs );
		var recordsUpdated = dao.updateData( argumentCollection=args );
		$announceInterception( "postDataApiUpdateData#namespace#", interceptDataArgs );

		interceptDataArgs.responseType = _getConfigService().validateResponseType( interceptDataArgs.responseType );

		if ( arguments.returnResponse ) {
			if ( recordsUpdated == 0 ) {
				return 0;
			}
			else if ( _getConfigService().isRecordResponseType( interceptDataArgs.responseType ) ) {
				return getSingleRecord( arguments.entity, arguments.recordId, [] );
			}
			else if ( _getConfigService().isIdOnlyResponseType( interceptDataArgs.responseType ) ) {
				return [ arguments.recordId ];
			}
			else { // empty
				return "";
			}
		}

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
		var namespace = _getInterceptorNamespace();
		var args      = arguments;

		if ( args.isUpdate ) {
			args.skipValidation = _getConfigService().entitySkipValidationOnUpdate( arguments.entity ); // default config on api or object level
			$announceInterception( "onDataApiUpdateRecordDataValidation#namespace#", args );
		}
		else {
			args.skipValidation = _getConfigService().entitySkipValidationOnInsert( arguments.entity ); // default config on api or object level
			$announceInterception( "onDataApiInsertRecordDataValidation#namespace#", args );
		}
		// to skip the validation completely it could either use the default or could have been overwritten by interceptor (e.g. using a dynamic skip of validation based on a request parameter)

		if ( args.skipValidation ) {
			return IsArray( arguments.data ) ? { validated=true, validationResults=[] } : [];
		}

		var ruleset = _getConfigService().getValidationRulesetForEntity( arguments.entity );

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

				$announceInterception( "postValidateUpsertData#namespace#", { validateUpsertDataArgs=prepped, entity=arguments.entity, data=arguments.data, validation=validation } );

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

		var validation = $getValidationEngine().validate(
			  ruleset       = ruleset
			, data          = prepped
			, ignoreMissing = arguments.ignoreMissing
		);

		$announceInterception( "postValidateUpsertData#namespace#", { validateUpsertDataArgs=prepped, entity=arguments.entity, data=arguments.data, validation=validation } );

		return _translateValidationErrors( validation );
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

		args.recordCountOnly = args.recordCountOnly ?: false;

		if ( args.recordCountOnly ) {
			args.selectFields = [ "1" ];
			args.distinct     = false;
			args.autoGroupBy  = false;
		} else {
			args.selectFields = _prepareSelectFields( arguments.entity, objectName, configService.getSelectFields( arguments.entity ), arguments.fields );
			args.orderBy      = configService.getSelectSortOrder( arguments.entity );
			args.distinct     = true;
			args.autoGroupBy  = true;
		}

		args.fromVersionTable        = false;
		args.savedFilters            = configService.getSavedFilters( arguments.entity );
		args.ignoreDefaultFilters    = configService.getIgnoreDefaultFilters( arguments.entity );
		args.allowDraftVersions      = false;

		$announceInterception( "preDataApiSelectData#namespace#", { selectDataArgs=args, entity=arguments.entity } );

		if ( args.recordCountOnly ) {
			return dao.selectData( argumentCollection=args );
		}

		if ( !ArrayLen( args.selectFields ) ) {
			throw( "Invaid select field" );
		}

		var records   = dao.selectData( argumentCollection=args );
		var processed = [];

		for( var record in records ) {
			processed.append( _processFields( record, fieldSettings ) );
		}
		$announceInterception( "postDataApiSelectData#namespace#", { selectDataArgs=args, entity=arguments.entity, data=processed } );

		return processed;
	}

	private struct function _selectCursorPage(
		  required string  entity
		, required struct  args
		, required array   fields
		, required struct  sort
		, required numeric pageSize
	) {
		var configService = _getConfigService();
		var objectName    = configService.getEntityObject( arguments.entity );
		var dao           = $getPresideObject( objectName );
		var namespace     = _getInterceptorNamespace();
		var fieldSettings = configService.getFieldSettings( arguments.entity );
		var dbAdapter     = $getPresideObjectService().getDbAdapterForObject( objectName );
		var args          = arguments.args;

		args.selectFields         = _prepareSelectFields( arguments.entity, objectName, configService.getSelectFields( arguments.entity ), arguments.fields );
		args.fromVersionTable     = false;
		args.savedFilters         = configService.getSavedFilters( arguments.entity );
		args.ignoreDefaultFilters = configService.getIgnoreDefaultFilters( arguments.entity );
		args.allowDraftVersions   = false;
		args.distinct             = true;
		args.autoGroupBy          = true;
		args.recordCountOnly      = false;
		args.returnType           = "array";
		args.orderBy              = "#arguments.sort.field# #arguments.sort.direction#, #arguments.sort.idField# #arguments.sort.direction#";

		ArrayAppend( args.selectFields, "#dbAdapter.escapeEntity( '#objectName#.#arguments.sort.field#' )# as __cursor_sort_value" );

		$announceInterception( "preDataApiSelectData#namespace#", { selectDataArgs=args, entity=arguments.entity } );

		if ( !ArrayLen( args.selectFields ) ) {
			throw( "Invaid select field" );
		}

		var records    = Duplicate( dao.selectData( argumentCollection=args ) );
		var hasNext    = ArrayLen( records ) > arguments.pageSize;
		var processed  = [];
		var nextCursor = "";

		if ( hasNext ) {
			ArrayDeleteAt( records, ArrayLen( records ) );
		}

		var lastIndex = ArrayLen( records );
		for( var i=1; i<=lastIndex; i++ ) {
			var record = records[ i ];

			if ( hasNext && i == lastIndex ) {
				nextCursor = _encodeCursor( arguments.sort, record[ "__cursor_sort_value" ] ?: "", record[ arguments.sort.idField ] ?: "" );
			}

			StructDelete( record, "__cursor_sort_value" );
			processed.append( _processFields( record, fieldSettings ) );
		}

		$announceInterception( "postDataApiSelectData#namespace#", { selectDataArgs=args, entity=arguments.entity, data=processed } );

		return { records=processed, nextCursor=nextCursor };
	}

	private struct function _resolveCursorSort( required string entity, required string idField ) {
		var sortOrder = _getConfigService().getSelectSortOrder( arguments.entity );
		var firstCol  = Trim( ListFirst( sortOrder, "," ) );
		var parts     = ListToArray( firstCol, " " );
		var field     = ArrayLen( parts ) >= 1 ? parts[ 1 ] : arguments.idField;
		var direction = ArrayLen( parts ) >= 2 ? LCase( parts[ 2 ] ) : "asc";

		if ( direction != "desc" ) {
			direction = "asc";
		}

		return {
			  field     = field
			, direction = direction
			, idField   = arguments.idField
		};
	}

	private void function _appendKeysetFilter( required string objectName, required struct sort, required struct cursorData, required struct args ) {
		var poService = $getPresideObjectService();
		var dbAdapter = poService.getDbAdapterForObject( arguments.objectName );
		var fieldType = poService.getObjectPropertyAttribute( arguments.objectName, arguments.sort.field, "dbtype" );
		var escSort   = dbAdapter.escapeEntity( "#arguments.objectName#.#arguments.sort.field#" );
		var escId     = dbAdapter.escapeEntity( "#arguments.objectName#.#arguments.sort.idField#" );
		var op        = arguments.sort.direction == "desc" ? "<" : ">";
		var sortType  = Len( Trim( fieldType ) ) ? dbAdapter.sqlDataTypeToCfSqlDatatype( fieldType ) : "cf_sql_varchar";

		ArrayAppend( arguments.args.extraFilters, {
			  filter       = "( #escSort# #op# :cursorSortA or ( #escSort# = :cursorSortB and #escId# #op# :cursorId ) )"
			, filterParams = {
				  cursorSortA = { type=sortType, value=arguments.cursorData.v  }
				, cursorSortB = { type=sortType, value=arguments.cursorData.v  }
				, cursorId    = { type="cf_sql_varchar", value=arguments.cursorData.id }
			  }
		} );
	}

	private string function _encodeCursor( required struct sort, required any sortValue, required string id ) {
		var value = arguments.sortValue;

		if ( IsDate( value ) ) {
			value = DateTimeFormat( value, "yyyy-mm-dd HH:nn:ss" );
		}

		return ToBase64( SerializeJson( {
			  f  = arguments.sort.field
			, d  = arguments.sort.direction
			, v  = value
			, id = arguments.id
		} ) );
	}

	private struct function _decodeCursor( required string cursor, required struct sort ) {
		var payload = "";

		try {
			payload = DeserializeJson( ToString( ToBinary( arguments.cursor ) ) );
		} catch( any e ) {
			throw( type="dataApiCursor.invalid", message="The supplied pagination cursor could not be decoded." );
		}

		if ( !IsStruct( payload ) || !StructKeyExists( payload, "v" ) || !StructKeyExists( payload, "id" ) ) {
			throw( type="dataApiCursor.invalid", message="The supplied pagination cursor is not valid." );
		}

		if ( ( payload.f ?: "" ) != arguments.sort.field || ( payload.d ?: "" ) != arguments.sort.direction ) {
			throw( type="dataApiCursor.invalid", message="The supplied pagination cursor does not match the current sort order." );
		}

		return { v=payload.v, id=payload.id };
	}

	private struct function _processFields( required struct record, required struct fieldSettings ) {
		var processed = {};

		for( var field in record ) {
			var renderer = fieldSettings[ field ].renderer ?: "none";
			var alias    = fieldSettings[ field ].alias ?: field;

			fieldSettings[ field ].record = record;

			processed[ alias ] = _renderField( record[ field ], renderer, fieldSettings[ field ] );
		}

		return processed;
	}

	private any function _renderField( required any value, required string renderer, struct fieldSettings={} ) {
		switch( renderer ) {
			case "date"           : return IsDate( arguments.value ) ? DateFormat( arguments.value, "yyyy-mm-dd" ) : NullValue();
			case "datetime"       : return IsDate( arguments.value ) ? DateTimeFormat( arguments.value, "yyyy-mm-dd HH:nn:ss" ) : NullValue();
			case "time"           : return IsDate( arguments.value ) ? TimeFormat( arguments.value, "HH:mm" ) : NullValue();
			case "strictboolean"  : return IsBoolean( arguments.value ) && arguments.value ? true : false; // looks odd, but aimed at ensuring that we definitely get boolean values back
			case "nullableboolean": return IsBoolean( arguments.value ) ? ( arguments.value ? true : false ) : NullValue();
			case "array"          : return ListToArray( arguments.value );
			case "numeric"        :
				if ( IsNumeric( arguments.value ) ) {
					return arguments.value;
				}
				return $isFeatureEnabled( "dataApiUseNullForNumerics" ) ? NullValue() : "";
			case "string"         :
			case "none":
			case "":
				if ( Len( arguments.value ?: "" ) ) {
					return arguments.value;
				}
				return $isFeatureEnabled( "dataApiUseNullForStrings" )  ? NullValue() : "";
		}

		if ( !Len( arguments.value ?: "" ) && !arguments.fieldSettings.renderEmptyValues ) {
			return $isFeatureEnabled( "dataApiUseNullForStrings" )  ? NullValue() : "";
		}

		if ( $getContentRendererService().rendererExists( renderer, "dataapi" ) ) {
			try {
				var renderedContent = $renderContent( renderer, arguments.value, "dataapi", arguments.fieldSettings );
				if ( !IsSimpleValue( renderedContent ) || Len( renderedContent ?: "" ) ) {
					return renderedContent;
				}
				return $isFeatureEnabled( "dataApiUseNullForStrings" ) ? NullValue() : "";
			} catch( any e ) {
				$raiseError( e );
			}
		}

		if ( Len( arguments.value ?: "" ) ) {
			return arguments.value;
		}
		return $isFeatureEnabled( "dataApiUseNullForStrings" )  ? NullValue() : "";
	}

	private array function _prepareSelectFields( required string entity, required string objectName, required array defaultFields, required array suppliedFields ) {
		var filtered = [];
		var props    = $getPresideObjectService().getObjectProperties( arguments.objectName );
		var idField  = $getPresideObjectService().getIdField( arguments.objectName );

		if ( ArrayIsEmpty( suppliedFields ) ) {
			filtered = arguments.defaultFields;
		} else {
			for( var field in suppliedFields ) {
				var propName = _getConfigService().getPropertyNameFromFieldAlias( arguments.entity, field );
				if ( ArrayFind( defaultFields, LCase( field ) ) ) {
					ArrayAppend( filtered, field );
				} else if ( ArrayFind( defaultFields, LCase( propName ) ) ) {
					ArrayAppend( filtered, propName );
				}
			}
		}

		var prepared = [];
		for( var field in filtered ) {
			if ( ( props[ field ].relationship ?: "" ) == "many-to-many" ) {
				ArrayAppend( prepared, "group_concat( distinct `#field#`.`id` ) as `#field#`" );
			} else {
				ArrayAppend( prepared, field );
			}
		}

		if ( !ArrayFindNoCase( prepared, idField ) ) {
			ArrayPrepend( prepared, idField );
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

	private function _prepareFilters( entity, filters, args ) {
		if ( StructCount( arguments.filters ) ) {
			var configService = _getConfigService();
			var objectName    = configService.getEntityObject( arguments.entity );
			var dbAdapter     = $getPresideObjectService().getDbAdapterForObject( objectName );
			var filterFields  = configService.getFilterFields( arguments.entity );

			for( var field in filterFields ) {
				var propName  = configService.getPropertyNameFromFieldAlias( arguments.entity, field );
				var fieldType = $getPresideObjectService().getObjectPropertyAttribute( objectName, propName, "dbtype" );

				if ( StructKeyExists( arguments.filters, field ) || StructKeyExists( arguments.filters, propName ) ) {
					args.filter[ propName ] = arguments.filters[ field ] ?: arguments.filters[ propName ];
				}

				if ( ReFindNoCase( "^date", fieldType ) ) {
					if ( StructKeyExists( arguments.filters, field & ".min" ) || StructKeyExists( arguments.filters, propName & ".min" ) ) {
						var value = arguments.filters[ field & ".min" ] ?: arguments.filters[ propName & ".min" ];
						ArrayAppend( args.extraFilters, {
							  filter       = "#dbAdapter.escapeEntity( '#objectName#.#propName#' )# >= :#propName#__min"
							, filterParams = { "#propName#__min" = {
								  type  = dbAdapter.sqlDataTypeToCfSqlDatatype( fieldType )
								, value = value
							  } }
						} );
					}
					if ( StructKeyExists( arguments.filters, field & ".max" ) || StructKeyExists( arguments.filters, propName & ".max" ) ) {
						var value = arguments.filters[ field & ".max" ] ?: arguments.filters[ propName & ".max" ];
						ArrayAppend( args.extraFilters, {
							  filter       = "#dbAdapter.escapeEntity( '#objectName#.#propName#' )# <= :#propName#__max"
							, filterParams = { "#propName#__max" = {
								  type  = dbAdapter.sqlDataTypeToCfSqlDatatype( fieldType )
								, value = value
							  } }
						} );
					}
				}
			}
		}
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