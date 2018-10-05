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

		if ( restRequest.getUri().reFindNoCase( "^/(queue|spec|docs)/" ) ) {
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
		var objectName = _getConfigService().getEntityObject( arguments.entity );
		var dao        = $getPresideObject( objectName );
		var newId      = dao.insertData(
			  data                      = _prepRecordForInsertAndUpdate( arguments.entity, arguments.record )
			, insertManyToManyRecords   = true
			, bypassTrivialInterceptors = true
		);

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

		return dao.updateData(
			  id                      = arguments.recordId
			, data                    = _prepRecordForInsertAndUpdate( arguments.entity, arguments.data )
			, updateManyToManyRecords = true
		);
	}

	public numeric function deleteSingleRecord( required string entity, required string recordId ) {
		var dao = $getPresideObject( _getConfigService().getEntityObject( arguments.entity ) );

		return dao.deleteData( id=arguments.recordId );
	}

	public numeric function batchDeleteRecords( required string entity, required array recordIds ) {
		if ( !arguments.recordIds.len() ) {
			return 0;
		}

		var objectName = _getConfigService().getEntityObject( arguments.entity );
		var idField    = $getPresideObjectService().getIdField( objectName );
		var dao        = $getPresideObject( objectName );
		var filter     = {};

		filter[ idField ] = arguments.recordIds;

		return dao.deleteData( filter=filter );
	}

	public any function validateUpsertData( required string entity, required any data, boolean ignoreMissing=false ) {
		var ruleset = _getConfigService().getValidationRulesetForEntity( arguments.entity );

		if ( IsArray( arguments.data ) ) {
			var result = { validated=true, validationResults=[] };
			for( var record in arguments.data ) {
				var validation = $getValidationEngine().validate(
					  ruleset       = ruleset
					, data          = _prepRecordForInsertAndUpdate( arguments.entity, record )
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

		return _translateValidationErrors( $getValidationEngine().validate(
			  ruleset       = ruleset
			, data          = _prepRecordForInsertAndUpdate( arguments.entity, arguments.data )
			, ignoreMissing = arguments.ignoreMissing
		) );
	}

	public struct function getSpec() {
		var event    = $getRequestContext();
		var site     = event.getSite();
		var domain   = site.domain ?: event.getServerName()
		var protocol = site.protocol ?: event.getProtocol();
		var spec = {
			  openapi    = "3.0.1"
			, info       = { title="Preside data API", version="1.0.0" }
			, servers    = [ { url="#protocol#://#domain#/api/data/v1" } ]
			, security   = [ { basic=[] } ]
			, paths      = StructNew( "linked" )
			, tags       = [ { name="Queue", description="Operations related to the data change queue that allows you to keep up to date with changes to the system's data." } ]
			, components = {
				  securitySchemes = { basic={ type="http", scheme="Basic", description="Authentication uses the Basic HTTP Authentication scheme over HTTPS. You will be given a secret API token and this must be used as the authentication PASSWORD. The username will be ignored." } }
				, schemas         = {}
				, headers         = {}
			  }
		};

		spec.components.headers.XTotalRecords = {
			  description = "Total number of records in paginated recordset or queue"
			, schema      = { type="integer" }
		};
		spec.components.headers.Link = {
			  description = "Contains pagination info in the form: '<{nexthref}>; rel=""next"", <{prevhref}>; rel=""prev""'. Either or both prev and next links may be omitted if there are no previous or next records."
			, schema      = { type="string" }
		};
		spec.components.schemas.QueueItem = {
			  required = [ "operation", "entity", "recordId", "queueId" ]
			, properties = {
				  operation = { type="string", description="Either `insert`, `update` or `delete`." }
				, entity    = { type="string", description="The name of the entity whose record has been created, modified or deleted." }
				, recordId  = { type="string", description="The ID of the entity record that has been created, modified or deleted." }
				, queueId   = { type="string", description="The ID of the queue entry. Once you have finished processing the queue item, you are responsible for removing it from the queue using this ID." }
				, record    = { type="object", description="For the `update` and `insert` operations, this object will represent the record as if you had fetched it with GET /entity/{entity}/{recordId}/" }
			}
		};


		spec.paths[ "/queue/" ] = {
			get = {
				  summary = "Get the next entry in the data change queue. Returns empty object {} if no data in the queue."
				, tags = [ "Queue" ]
				, responses = { "200" = {
					  description = "Response to a valid request"
					, content     = { "application/json" = { schema={ "$ref"="##/components/schemas/QueueItem" } } }
					, headers     = {
						  "X-Total-Records" = { "$ref"="##/components/headers/XTotalRecords" }
						, "Link"            = { "$ref"="##/components/headers/Link" }
					  }
				  } }
			}
		};
		spec.paths[ "/queue/{queueId}/" ] = {
			delete = {
				  summary = "Removes the given queue item from the queue."
				, tags = [ "Queue" ]
				, responses = { "200" = {
					  description = "Response to a valid request"
					, content     = { "application/json" = { schema={ required=[ "removed" ], properties={ removed={ type="integer", description="Number of items removed from the queue. i.e. 1 for success, 0 for no items removed. Either way, operation should be deemed as successful as the item is definitely no longer in the queue." } } } } }
				  } }
			},
			parameters = [{name="queueId", in="path", required=true, description="ID of the queue item to remove.", schema={ type="string" } } ]
		};

		return spec;
	}


// PRIVATE HELPERS
	private any function _selectData( required string entity, required struct args, array fields=[] ) {
		var configService = _getConfigService();
		var objectName    = configService.getEntityObject( arguments.entity );
		var dao           = $getPresideObject( objectName );
		var fieldSettings = configService.getFieldSettings( arguments.entity );

		args.selectFields            = _prepareSelectFields( objectName, configService.getSelectFields( arguments.entity ), arguments.fields );
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
			processed.append( _processFields( record, fieldSettings ) );
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

	private array function _prepareSelectFields( required string objectName, required array defaultFields, required array suppliedFields ) {
		var filtered = [];
		var props    = $getPresideObjectService().getObjectProperties( arguments.objectName );

		if ( !suppliedFields.len() ) {
			filtered = arguments.defaultFields;
		} else {
			for( var field in suppliedFields ) {
				if ( defaultFields.find( LCase( field ) ) ) {
					filtered.append( field );
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

	private struct function _prepRecordForInsertAndUpdate( required string entity, required struct record ) {
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

		return prepped;
	}

	private struct function _translateValidationErrors( required any validationResult ) {
		var messages = validationResult.getMessages();

		for( var fieldName in messages ) {
			messages[ fieldName ] = $translateResource(
				  uri          = messages[ fieldName ].message ?: ""
				, defaultValue = messages[ fieldName ].message ?: ""
				, data         = messages[ fieldName ].params  ?: []
			);
		}

		return messages;
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