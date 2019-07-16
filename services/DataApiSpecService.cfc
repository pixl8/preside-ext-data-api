/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @configService.inject  dataApiConfigurationService
	 * @dataApiService.inject dataApiService
	 *
	 */
	public any function init( required any configService, required any dataApiService ) {
		_setConfigService( arguments.configService );
		_setDataApiService( arguments.dataApiService );

		return this;
	}

// PUBLIC API METHODS
	public struct function getSpec() {
		var spec      = StructNew( "linked" );
		var namespace = _getInterceptorNamespace();

		_addGeneralSpec( spec );
		_addTraits( spec );
		_addCommonHeaderSpecs( spec );
		_addCommonSchemas( spec );

		if ( $isFeatureEnabled( "dataApiQueue" ) ) {
			_addQueueSpec( spec );
		}

		_addEntitySpecs( spec );

		$announceInterception( "onOpenApiSpecGeneration#namespace#", { spec=spec } );

		return spec;
	}

// PRIVATE HELPERS
	private string function _i18nNamespaced() {
		return _getDataApiService().i18nNamespaced( argumentCollection=arguments );
	}

	private string function _getInterceptorNamespace() {
		var dataApiNamespace = $getRequestContext().getValue( name="dataApiNamespace", defaultValue="" );
		if ( len( dataApiNamespace ) ) {
			return "_" & dataApiNamespace;
		}
		return "";
	}

	private void function _addGeneralSpec( required struct spec ) {
		var event    = $getRequestContext();
		var site     = event.getSite();
		var domain   = site.domain ?: event.getServerName()
		var protocol = site.protocol ?: event.getProtocol();
		var api      = event.getValue( name="dataApiNamespace", defaultValue="data" );
		var route    = event.getValue( name="dataApiRoute"    , defaultValue="/data/v1" );

		spec.openapi = "3.0.1";
		spec.info    = {
				title       = _i18nNamespaced( "dataapi:api.title" )
			  , description = _i18nNamespaced( "dataapi:api.description", "" )
			  , version     = _i18nNamespaced( "dataapi:api.version" )
		};
		spec.servers    = [ { url="#protocol#://#domain#/api#route#" } ];
		spec.security   = [ { "#_i18nNamespaced( "dataapi:basic.auth.name" )#"=[] } ];
		spec.components = {
			  securitySchemes = { "#_i18nNamespaced( "dataapi:basic.auth.name" )#"={ type="http", scheme="Basic", description=_i18nNamespaced( "dataapi:basic.auth.description" ) } }
			, schemas         = {}
			, headers         = {}
		};
		spec.tags  = [];
		spec.paths = StructNew( "linked" );
	}

	private void function _addTraits( required struct spec ) {
		spec.tags.append({
			  name         = _i18nNamespaced( "dataapi:trait.pagination.title" )
			, description  = _i18nNamespaced( "dataapi:trait.pagination.description" )
			, "x-traitTag" = true
		});
		spec.tags.append({
			  name         = _i18nNamespaced( "dataapi:trait.errorhandling.title" )
			, description  = _i18nNamespaced( "dataapi:trait.errorhandling.description" )
			, "x-traitTag" = true
		});
	}

	private void function _addCommonHeaderSpecs( required struct spec ) {
		spec.components.headers.XTotalRecords = {
			  description = _i18nNamespaced( "dataapi:headers.XTotalRecords.description" )
			, schema      = { type="integer" }
		};
		spec.components.headers.XTotalPages = {
			  description = _i18nNamespaced( "dataapi:headers.XTotalPages.description" )
			, schema      = { type="integer" }
		};
		spec.components.headers.Link = {
			  description = _i18nNamespaced( "dataapi:headers.Link.description" )
			, schema      = { type="string" }
		};
	}

	private void function _addCommonSchemas( required struct spec ) {
		spec.components.schemas.validationMessage = {
			  required = [ "field", "message" ]
			, properties = {
				  field   = { type="string", description=_i18nNamespaced( "dataapi:schemas.validationMessage.field" ) }
				, message = { type="string", description=_i18nNamespaced( "dataapi:schemas.validationMessage.message" ) }
			  }
		};

	}

	private void function _addQueueSpec( required struct spec ) {
		spec.tags.append( {
			  name        = _i18nNamespaced( "dataapi:tags.queue.title" )
			, description = _i18nNamespaced( "dataapi:tags.queue.description" )
		} );

		spec.components.schemas.QueueItem = {
			  required = [ "operation", "entity", "recordId", "queueId" ]
			, properties = {
				  operation = { type="string", description=_i18nNamespaced( "dataapi:schemas.queueItem.operation" ), enum=[ "insert", "update", "delete" ] }
				, entity    = { type="string", description=_i18nNamespaced( "dataapi:schemas.queueItem.entity"    ) }
				, recordId  = { type="string", description=_i18nNamespaced( "dataapi:schemas.queueItem.recordId"  ) }
				, queueId   = { type="string", description=_i18nNamespaced( "dataapi:schemas.queueItem.queueId"   ) }
				, record    = { type="object", description=_i18nNamespaced( "dataapi:schemas.queueItem.record"    ) }
			}
		};


		spec.paths[ "/queue/" ] = {
			get = {
				  summary = "GET /queue/"
				, description = _i18nNamespaced( "dataapi:operation.queue.get" )
				, tags = [ _i18nNamespaced( "dataapi:tags.queue.title" ) ]
				, responses = { "200" = {
					  description = _i18nNamespaced( "dataapi:operation.queue.get.200.description" )
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
				  summary = "DELETE /queue/{queueId}/"
				, description = _i18nNamespaced( "dataapi:operation.queue.delete" )
				, tags = [ _i18nNamespaced( "dataapi:tags.queue.title" ) ]
				, responses = { "200" = {
					  description = _i18nNamespaced( "dataapi:operation.queue.delete.200.description" )
					, content = { "application/json" = { schema={ required=[ "removed" ], properties={ removed={ type="integer", description=_i18nNamespaced( "dataapi:operation.queue.delete.schema.removed") } } } } }
				  } }
			},
			parameters = [{name="queueId", in="path", required=true, description=_i18nNamespaced( "dataapi:operation.queue.delete.params.queueId" ), schema={ type="string" } } ]
		};
	}

	private void function _addEntitySpecs( required struct spec ) {
		var configService = _getConfigService();
		var entities = _getConfigService().getEntities();
		var entityNames = StructKeyArray( entities );

		entityNames.sort( "textnocase" );

		for( var entityName in entityNames ) {
			var objectName = entities[ entityName ].objectName;
			var basei18n   = $getPresideObjectService().getResourceBundleUriRoot( objectName );
			var entityTag  = _i18nNamespaced( uri="dataapi:entity.#entityName#.name", defaultValue=_i18nNamespaced( uri=basei18n & "title.singular", defaultValue=entityName ) )

			spec.tags.append( {
				  name        = entityTag
				, description = _i18nNamespaced( uri="dataapi:entity.#entityName#.description", defaultValue=_i18nNamespaced( uri=basei18n & "description", defaultValue="" ) )
			} );
			spec.paths[ "/entity/#entityName#/" ] = StructNew( "linked" );
			spec.paths[ "/entity/#entityName#/{recordId}/" ] = StructNew( "linked" );
			spec.components.schemas[ entityName ] = _getEntitySchema( entityName );

			if ( configService.entityVerbIsSupported( entityName, "get" ) ) {
				var fieldsFilterList = configService.getSelectFields( entityName, true ).toList( ", " );
				var params = [ {
					name        = "page"
				  , in          = "query"
				  , required    = false
				  , description = _i18nNamespaced( uri="dataapi:operation.get.params.page", defaultValue="", data=[ entityTag ] )
				  , schema      = { type="integer" }
				},{
					name        = "pageSize"
				  , in          = "query"
				  , required    = false
				  , description = _i18nNamespaced( uri="dataapi:operation.get.params.pageSize", defaultValue="", data=[ entityTag ] )
				  , schema      = { type="integer" }
				},{
					name        = "fields"
				  , in          = "query"
				  , required    = false
				  , description = _i18nNamespaced( uri="dataapi:operation.get.params.fields", defaultValue="", data=[ entityTag, fieldsFilterList ] )
				  , schema      = { type="string" }
				} ];

				for( var field in configService.getFilterFields( entityName ) ) {
					params.append( {
						  name        = "filter.#field#"
						, in          = "query"
						, required    = false
						, description = _i18nNamespaced( uri="dataapi:operation.#entityName#.get.params.fields.#field#.description", defaultValue=_i18nNamespaced( uri=basei18n & "field.#field#.help", defaultValue=_i18nNamespaced( uri="dataapi:field.#field#.description", defaultValue="" ) ) )
						, schema      = _getFieldSchema( entityName, field )
					} );
				}

				spec.paths[ "/entity/#entityName#/" ].get = {
					  tags = [ entityTag ]
					, summary = "GET /entity/#entityName#/"
					, description = _i18nNamespaced( uri="dataapi:operation.#entityName#.get.description", defaultValue=_i18nNamespaced( uri="dataapi:operation.get.description", defaultValue="", data=[ entityTag ] ) )
					, parameters = params
					, responses = { "200" = {
						  description = _i18nNamespaced( uri="dataapi:operation.#entityName#.get.200.description", defaultValue=_i18nNamespaced( uri="dataapi:operation.get.200.description", defaultValue="", data=[ entityTag ] ) )
						, content     = { "application/json" = { schema={ type="array", items={"$ref"="##/components/schemas/#entityName#" } } } }
						, headers     = {
							  "X-Total-Records" = { "$ref"="##/components/headers/XTotalRecords" }
							, "X-Total-Pages"   = { "$ref"="##/components/headers/XTotalPages" }
							, "Link"            = { "$ref"="##/components/headers/Link" }
						  }
					  } }
				};

				spec.paths[ "/entity/#entityName#/{recordId}/" ].get = {
					  tags = [ entityTag ]
					, summary = "GET /entity/#entityName#/{recordId}/"
					, description = _i18nNamespaced( uri="dataapi:operation.#entityName#.get.by.id.description", defaultValue=_i18nNamespaced( uri="dataapi:operation.get.by.id.description", defaultValue="", data=[ entityTag ] ) )
					, responses = {
						  "200" = {
							  description = _i18nNamespaced( uri="dataapi:operation.#entityName#.get.by.id.200.description", defaultValue=_i18nNamespaced( uri="dataapi:operation.get.by.id.200.description", defaultValue="", data=[ entityTag ] ) )
							, content     = { "application/json" = { schema={ "$ref"="##/components/schemas/#entityName#" } } }
						  }
						, "404" = {
							  description = _i18nNamespaced( uri="dataapi:operation.#entityName#.get.by.id.404.description", defaultValue=_i18nNamespaced( uri="dataapi:operation.get.by.id.404.description", defaultValue="" ) )
						  }
					  }
					, parameters = [ {
							name        = "recordId"
						  , in          = "path"
						  , required    = true
						  , description = _i18nNamespaced( uri="dataapi:operation.#entityName#.get.by.id.params.queueId", defaultValue=_i18nNamespaced( uri="dataapi:operation.get.by.id.params.recordId", defaultValue="", data=[ entityTag ] ) )
						  , schema      = { type="string" }
					  } ]
				};
			}

			if ( configService.entityVerbIsSupported( entityName, "put" ) || configService.entityVerbIsSupported( entityName, "post" ) ) {
				spec.components.schemas[ entityName & "upsert" ] = _getEntitySchema( entityName, false );
				spec.components.schemas[ entityName & "upsertWithId" ] = _getEntitySchema( entityName, false, true );

				spec.components.schemas[ "validationFailureMultiple#entityName#" ] = {
					  required = [ "record", "valid", "errorMessages" ]
					, title    = _i18nNamespaced( uri="dataapi:schemas.validationFailureMultiple.title", data=[ entityTag ] )
					, properties = {
						  record         = { "$ref"="##/components/schemas/#entityName#upsert" }
						, valid          = { type="boolean", description=_i18nNamespaced( uri="dataapi:schemas.validationFailure.valid"         , data=[ entityTag ] ) }
						, errorMessages  = { type="array"  , description=_i18nNamespaced( uri="dataapi:schemas.validationFailure.errorMessages" , data=[ entityTag ] ), items={ "$ref"="##/components/schemas/validationMessage" } }
					}
				};
			}

			if ( configService.entityVerbIsSupported( entityName, "put" ) ) {
				spec.paths[ "/entity/#entityName#/" ].put = {
					  tags = [ entityTag ]
					, summary = "PUT /entity/#entityName#/"
					, description = _i18nNamespaced( uri="dataapi:operation.#entityName#.put.description", defaultValue=_i18nNamespaced( uri="dataapi:operation.put.description", defaultValue="", data=[ entityTag ] ) )
					, requestBody = {
						  description = _i18nNamespaced( uri="dataapi:operation.#entityName#.put.body.description", defaultValue=_i18nNamespaced( uri="dataapi:operation.put.body.description", defaultValue="", data=[ entityTag ] ) )
						, required    = true
						, content     = { "application/json" = {
							schema={ type="array", items={"$ref"="##/components/schemas/#entityName#upsertWithId" } }
						  } }
					  }
					, responses = {
						  "200" = {
							  description = _i18nNamespaced( uri="dataapi:operation.#entityName#.put.200.description", defaultValue=_i18nNamespaced( uri="dataapi:operation.put.200.description", defaultValue="", data=[ entityTag ] ) )
							, content     = { "application/json" = { schema={ type="array", items={"$ref"="##/components/schemas/#entityName#" } } } }
						  }
						, "422" = {
							  description = _i18nNamespaced( uri="dataapi:operation.#entityName#.put.422.description", defaultValue=_i18nNamespaced( uri="dataapi:operation.put.422.description", defaultValue="", data=[ entityTag ] ) )
							, content     = { "application/json" = { schema={ type="array", items={ "$ref"="##/components/schemas/validationFailureMultiple#entityName#" } } } }
						  }
					  }
				};

				spec.paths[ "/entity/#entityName#/{recordId}/" ].put = {
					  tags = [ entityTag ]
					, summary = "PUT /entity/#entityName#/{recordId}/"
					, description = _i18nNamespaced( uri="dataapi:operation.#entityName#.put.by.id.description", defaultValue=_i18nNamespaced( uri="dataapi:operation.put.by.id.description", defaultValue="", data=[ entityTag ] ) )
					, requestBody = {
						  description = _i18nNamespaced( uri="dataapi:operation.#entityName#.put.by.id.body.description", defaultValue=_i18nNamespaced( uri="dataapi:operation.put.by.id.body.description", defaultValue="", data=[ entityTag ] ) )
						, required    = true
						, content     = { "application/json" = {
							schema = { "$ref"="##/components/schemas/#entityName#upsert" }
						  } }
					  }
					, responses = {
						  "200" = {
							  description = _i18nNamespaced( uri="dataapi:operation.#entityName#.put.by.id.200.description", defaultValue=_i18nNamespaced( uri="dataapi:operation.put.by.id.200.description", defaultValue="", data=[ entityTag ] ) )
							, content     = { "application/json" = { schema={ "$ref"="##/components/schemas/#entityName#" } } }
						  }
						, "404" = {
							  description = _i18nNamespaced( uri="dataapi:operation.#entityName#.put.by.id.404.description", defaultValue=_i18nNamespaced( uri="dataapi:operation.put.by.id.404.description", defaultValue="", data=[ entityTag ] ) )
						  }
						, "422" = {
							  description = _i18nNamespaced( uri="dataapi:operation.#entityName#.put.by.id.422.description", defaultValue=_i18nNamespaced( uri="dataapi:operation.put.by.id.422.description", defaultValue="", data=[ entityTag ] ) )
							, content     = { "application/json" = { schema={ type="array", items={ "$ref"="##/components/schemas/validationMessage" } } } }
						  }
					  }
					, parameters = [ {
							name        = "recordId"
						  , in          = "path"
						  , required    = true
						  , description = _i18nNamespaced( uri="dataapi:operation.#entityName#.put.by.id.params.queueId", defaultValue=_i18nNamespaced( uri="dataapi:operation.put.by.id.params.recordId", defaultValue="", data=[ entityTag ] ) )
						  , schema      = { type="string" }
					  } ]
				};
			}

			if ( configService.entityVerbIsSupported( entityName, "post" ) ) {
				spec.paths[ "/entity/#entityName#/" ].post = {
					  tags = [ entityTag ]
					, summary = "POST /entity/#entityName#/"
					, description = _i18nNamespaced( uri="dataapi:operation.#entityName#.post.description", defaultValue=_i18nNamespaced( uri="dataapi:operation.post.description", defaultValue="", data=[ entityTag ] ) )
					, requestBody = {
						  description = _i18nNamespaced( uri="dataapi:operation.#entityName#.post.body.description", defaultValue=_i18nNamespaced( uri="dataapi:operation.post.body.description", defaultValue="", data=[ entityTag ] ) )
						, required    = true
						, content     = { "application/json" = {
							schema={ type="array", items={"$ref"="##/components/schemas/#entityName#upsert" } }
						  } }
					  }
					, responses = {
						  "200" = {
							  description = _i18nNamespaced( uri="dataapi:operation.#entityName#.post.200.description", defaultValue=_i18nNamespaced( uri="dataapi:operation.post.200.description", defaultValue="", data=[ entityTag ] ) )
							, content     = { "application/json" = { schema={ type="array", items={"$ref"="##/components/schemas/#entityName#" } } } }
						  }
						, "422" = {
							  description = _i18nNamespaced( uri="dataapi:operation.#entityName#.post.422.description", defaultValue=_i18nNamespaced( uri="dataapi:operation.post.422.description", defaultValue="", data=[ entityTag ] ) )
							, content     = { "application/json" = { schema={ type="array", items={ "$ref"="##/components/schemas/validationFailureMultiple#entityName#" } } } }
						  }
					  }
				};
			}

			if ( configService.entityVerbIsSupported( entityName, "delete" ) ) {
				spec.paths[ "/entity/#entityName#/{recordId}/" ].delete = {
					  tags = [ entityTag ]
					, summary = "DELETE /entity/#entityName#/{recordId}/"
					, description = _i18nNamespaced( uri="dataapi:operation.#entityName#.delete.description", defaultValue=_i18nNamespaced( uri="dataapi:operation.delete.description", defaultValue="", data=[ entityTag ] ) )
					, responses = { "200" = {
						  description = _i18nNamespaced( uri="dataapi:operation.#entityName#.delete.200.description", defaultValue=_i18nNamespaced( uri="dataapi:operation.delete.200.description", defaultValue="" ) )
						, content     = { "application/json" = { schema={ required=[ "deleted" ], properties={ deleted={ type="integer", description=_i18nNamespaced( uri="dataapi:operation.delete.schema.removed" ) } } } } }
					  } }
					, parameters = [ {
							name        = "recordId"
						  , in          = "path"
						  , required    = true
						  , description = _i18nNamespaced( uri="dataapi:operation.#entityName#.delete.params.queueId", defaultValue=_i18nNamespaced( uri="dataapi:operation.delete.params.recordId", defaultValue="", data=[ entityTag ] ) )
						  , schema      = { type="string" }
					  } ]
				};
			}

		}
	}

	private struct function _getEntitySchema( required string entityName, boolean forSelect=true, boolean forceIdField=false ) {
		var schema        = { required=[], properties=StructNew( "linked" ) };
		var confService   = _getConfigService();
		var fields        = arguments.forSelect ? confService.getSelectFields( arguments.entityName ) : confService.getUpsertFields( arguments.entityName );
		var fieldSettings = confService.getFieldSettings( arguments.entityName );
		var objectName    = confService.getEntityObject( arguments.entityName );
		var props         = $getPresideObjectService().getObjectProperties( objectName );
		var basei18n      = $getPresideObjectService().getResourceBundleUriRoot( objectName );

		if ( arguments.forceIdField ) {
			var idField = $getPresideObjectService().getIdField( objectName );

			if ( !fields.find( idField ) ) {
				fields.prepend( idField );
			}
		}

		for( var field in fields ) {
			if ( IsBoolean( props[ field ].required ?: "" ) && props[ field ].required ) {
				schema.required.append( field );
			}

			var fieldAlias = fieldSettings[ field ].alias ?: field;
			schema.properties[ fieldAlias ] = {
				description = _i18nNamespaced( uri="dataapi:entity.#arguments.entityName#.field.#fieldAlias#.description", defaultValue=_i18nNamespaced( uri="#basei18n#field.#field#.help", defaultValue=_i18nNamespaced( uri="dataapi:field.#fieldAlias#.description", defaultValue="" ) ) )
			};
			schema.properties[ fieldSettings[ field ].alias ?: field ].append(
				_mapFieldType( argumentCollection=props[ field ] ?: {} )
			);
		}

		return schema;
	}

	private struct function _mapFieldType(
		  string relationship = ""
		, string type         = ""
		, string dbtype       = ""
		, string enum         = ""
	) {
		if ( relationship=="many-to-many" ) {
			return { type="array", items={ type="string", format="Foreign Key (UUID)" } };
		} else if ( relationship=="many-to-one" ) {
			return { type="string", format="Foreign Key (UUID)" };
		}

		switch ( arguments.type ) {
			case "boolean":
				return { type=arguments.type };

			case "numeric":
				switch( arguments.dbtype ) {
					case "int":
					case "smallint":
					case "bigint":
					case "integer":
						return { type="integer", format="int64" };
					default:
						return { type="number" };
				}
			break;

			case "date":
				switch( arguments.dbtype ) {
					case "date":
						return { type="string", format="date" }
					default:
						return { type="string", format="datetime" }
				}
			break;
		}

		if ( Len( Trim( arguments.enum ) ) ) {
			var enumIds = $getColdbox().getSetting( name="enum.#arguments.enum#", defaultValue=[] );
			if ( IsArray( enumIds ) && enumIds.len() ) {
				return { type="string", enum=enumIds };
			}
		}


		return { type="string" };
	}

	private struct function _getFieldSchema( required string entity, required string field ) {
		var configService = _getConfigService();
		var objectName    = configService.getEntityObject( arguments.entity );
		var props         = $getPresideObjectService().getObjectProperties( objectName );
		var propName      = configService.getPropertyNameFromFieldAlias( arguments.entity, arguments.field );

		return _mapFieldType( argumentCollection=props[ propName ] ?: {} );
	}



// GETTERS AND SETTERS
	private any function _getConfigService() {
		return _configService;
	}
	private void function _setConfigService( required any configService ) {
		_configService = arguments.configService;
	}

	private any function _getDataApiService() {
		return _dataApiService;
	}
	private void function _setDataApiService( required any dataApiService ) {
		_dataApiService = arguments.dataApiService;
	}
}