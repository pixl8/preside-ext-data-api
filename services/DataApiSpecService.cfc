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
		var spec = StructNew( "linked" );

		_addGeneralSpec( spec );
		_addCommonHeaderSpecs( spec );
		_addCommonSchemas( spec );
		_addQueueSpec( spec );
		_addEntitySpecs( spec );


		return spec;
	}

// PRIVATE HELPERS
	private void function _addGeneralSpec( required struct spec ) {
		var event    = $getRequestContext();
		var site     = event.getSite();
		var domain   = site.domain ?: event.getServerName()
		var protocol = site.protocol ?: event.getProtocol();

		spec.openapi = "3.0.1";
		spec.info    = {
				title       = $translateResource( "dataapi:api.title" )
			  , description = $translateResource( "dataapi:api.description", "" )
			  , version     = $translateResource( "dataapi:api.version" )
		};
		spec.servers    = [ { url="#protocol#://#domain#/api/data/v1" } ]
		spec.security   = [ { basic=[] } ]
		spec.components = {
			  securitySchemes = { basic={ type="http", scheme="Basic", description=$translateResource( "dataapi:basic.auth.description" ) } }
			, schemas         = {}
			, headers         = {}
		};
		spec.tags  = [];
		spec.paths = StructNew( "linked" );
	}

	private void function _addCommonHeaderSpecs( required struct spec ) {
		spec.components.headers.XTotalRecords = {
			  description = $translateResource( "dataapi:headers.XTotalRecords.description" )
			, schema      = { type="integer" }
		};
		spec.components.headers.XTotalPages = {
			  description = $translateResource( "dataapi:headers.XTotalPages.description" )
			, schema      = { type="integer" }
		};
		spec.components.headers.Link = {
			  description = $translateResource( "dataapi:headers.Link.description" )
			, schema      = { type="string" }
		};
	}

	private void function _addCommonSchemas( required struct spec ) {
		spec.components.schemas.validationMessage = {
			  required = [ "field", "message" ]
			, properties = {
				  field   = { type="string", description=$translateResource( "dataapi:schemas.validationMessage.field" ) }
				, message = { type="string", description=$translateResource( "dataapi:schemas.validationMessage.message" ) }
			  }
		};

	}

	private void function _addQueueSpec( required struct spec ) {
		spec.tags.append( {
			  name        = $translateResource( "dataapi:tags.queue.title" )
			, description = $translateResource( "dataapi:tags.queue.description" )
		} );

		spec.components.schemas.QueueItem = {
			  required = [ "operation", "entity", "recordId", "queueId" ]
			, properties = {
				  operation = { type="string", description=$translateResource( "dataapi:schemas.queueItem.operation" ) }
				, entity    = { type="string", description=$translateResource( "dataapi:schemas.queueItem.entity"    ) }
				, recordId  = { type="string", description=$translateResource( "dataapi:schemas.queueItem.recordId"  ) }
				, queueId   = { type="string", description=$translateResource( "dataapi:schemas.queueItem.queueId"   ) }
				, record    = { type="object", description=$translateResource( "dataapi:schemas.queueItem.record"    ) }
			}
		};


		spec.paths[ "/queue/" ] = {
			get = {
				  summary = $translateResource( "dataapi:operation.queue.get" )
				, tags = [ $translateResource( "dataapi:tags.queue.title" ) ]
				, responses = { "200" = {
					  description = $translateResource( "dataapi:operation.queue.get.200.description" )
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
				  summary = $translateResource( "dataapi:operation.queue.delete" )
				, tags = [ $translateResource( "dataapi:tags.queue.title" ) ]
				, responses = { "200" = {
					  description = $translateResource( "dataapi:operation.queue.delete.200.description" )
					, content     = { "application/json" = { schema={ required=[ "removed" ], properties={ removed={ type="integer", description=$translateResource( "dataapi:operation.queue.delete.schema.removed") } } } } }
				  } }
			},
			parameters = [{name="queueId", in="path", required=true, description=$translateResource( "dataapi:operation.queue.delete.params.queueId" ), schema={ type="string" } } ]
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
			var entityTag  = $translateResource( uri="dataapi:entity.#entityName#.name", defaultValue=$translateResource( uri=basei18n & "title.singular", defaultValue=entityName ) )

			spec.tags.append( {
				  name        = entityTag
				, description = $translateResource( uri="dataapi:entity.#entityName#.description", defaultValue=$translateResource( uri=basei18n & "description", defaultValue="" ) )
			} );
			spec.paths[ "/entity/#entityName#/" ] = StructNew( "linked" );
			spec.paths[ "/entity/#entityName#/{recordId}/" ] = StructNew( "linked" );
			spec.components.schemas[ entityName ] = _getEntitySchema( entityName );

			if ( configService.entityVerbIsSupported( entityName, "get" ) ) {
				var selectFieldList = configService.getSelectFields( entityName ).toList( ", " );
				spec.paths[ "/entity/#entityName#/" ].get = {
					  tags = [ entityTag ]
					, description = $translateResource( uri="dataapi:operation.#entityName#.get.description", defaultValue=$translateResource( uri="dataapi:operation.get.description", defaultValue="", data=[ entityTag ] ) )
					, parameters = [ {
							name        = "page"
						  , in          = "query"
						  , required    = false
						  , description = $translateResource( uri="dataapi:operation.get.params.page", defaultValue="", data=[ entityTag ] )
						  , schema      = { type="integer" }
					  },{
							name        = "pageSize"
						  , in          = "query"
						  , required    = false
						  , description = $translateResource( uri="dataapi:operation.get.params.pageSize", defaultValue="", data=[ entityTag ] )
						  , schema      = { type="integer" }
					  },{
							name        = "fields"
						  , in          = "query"
						  , required    = false
						  , description = $translateResource( uri="dataapi:operation.get.params.fields", defaultValue="", data=[ entityTag, selectFieldList ] )
						  , schema      = { type="string" }
					  } ]
					, responses = { "200" = {
						  description = $translateResource( uri="dataapi:operation.#entityName#.get.200.description", defaultValue=$translateResource( uri="dataapi:operation.get.200.description", defaultValue="", data=[ entityTag ] ) )
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
					, description = $translateResource( uri="dataapi:operation.#entityName#.get.by.id.description", defaultValue=$translateResource( uri="dataapi:operation.get.by.id.description", defaultValue="", data=[ entityTag ] ) )
					, responses = {
						  "200" = {
							  description = $translateResource( uri="dataapi:operation.#entityName#.get.by.id.200.description", defaultValue=$translateResource( uri="dataapi:operation.get.by.id.200.description", defaultValue="" ) )
							, content     = { "application/json" = { schema={ "$ref"="##/components/schemas/#entityName#" } } }
						  }
						, "404" = {
							  description = $translateResource( uri="dataapi:operation.#entityName#.get.by.id.404.description", defaultValue=$translateResource( uri="dataapi:operation.get.by.id.404.description", defaultValue="" ) )
						  }
					  }
					, parameters = [ {
							name        = "recordId"
						  , in          = "path"
						  , required    = true
						  , description = $translateResource( uri="dataapi:operation.#entityName#.get.by.id.params.queueId", defaultValue=$translateResource( uri="dataapi:operation.get.by.id.params.recordId", defaultValue="", data=[ entityTag ] ) )
						  , schema      = { type="string" }
					  } ]
				};
			}

			if ( configService.entityVerbIsSupported( entityName, "put" ) || configService.entityVerbIsSupported( entityName, "post" ) ) {
				spec.components.schemas[ "validationFailureMultiple#entityName#" ] = {
					  required = [ "record", "valid", "errorMessages" ]
					, title    = $translateResource( uri="dataapi:schemas.validationFailureMultiple.title", data=[ entityTag ] )
					, properties = {
						  record         = { "$ref"="##/components/schemas/#entityName#" }
						, valid          = { type="boolean", description=$translateResource( uri="dataapi:schemas.validationFailure.valid"         , data=[ entityTag ] ) }
						, errorMessages  = { type="array"  , description=$translateResource( uri="dataapi:schemas.validationFailure.errorMessages" , data=[ entityTag ] ), items={ "$ref"="##/components/schemas/validationMessage" } }
					}
				};
			}

			if ( configService.entityVerbIsSupported( entityName, "put" ) ) {
				spec.paths[ "/entity/#entityName#/" ].put = {
					  tags = [ entityTag ]
					, description = $translateResource( uri="dataapi:operation.#entityName#.put.description", defaultValue=$translateResource( uri="dataapi:operation.put.description", defaultValue="", data=[ entityTag ] ) )
					, requestBody = {
						  description = $translateResource( uri="dataapi:operation.#entityName#.put.body.description", defaultValue=$translateResource( uri="dataapi:operation.put.body.description", defaultValue="", data=[ entityTag ] ) )
						, required    = true
						, content     = { "application/json" = {
							schema={ type="array", items={"$ref"="##/components/schemas/#entityName#" } }
						  } }
					  }
					, responses = {
						  "200" = {
							  description = $translateResource( uri="dataapi:operation.#entityName#.put.200.description", defaultValue=$translateResource( uri="dataapi:operation.put.200.description", defaultValue="", data=[ entityTag ] ) )
							, content     = { "application/json" = { schema={ type="array", items={"$ref"="##/components/schemas/#entityName#" } } } }
						  }
						, "422" = {
							  description = $translateResource( uri="dataapi:operation.#entityName#.put.422.description", defaultValue=$translateResource( uri="dataapi:operation.put.422.description", defaultValue="", data=[ entityTag ] ) )
							, content     = { "application/json" = { schema={ type="array", items={ "$ref"="##/components/schemas/validationFailureMultiple#entityName#" } } } }
						  }
					  }
				};

				spec.paths[ "/entity/#entityName#/{recordId}/" ].put = {
					  tags = [ entityTag ]
					, description = $translateResource( uri="dataapi:operation.#entityName#.put.by.id.description", defaultValue=$translateResource( uri="dataapi:operation.put.by.id.description", defaultValue="", data=[ entityTag ] ) )
					, requestBody = {
						  description = $translateResource( uri="dataapi:operation.#entityName#.put.by.id.body.description", defaultValue=$translateResource( uri="dataapi:operation.put.by.id.body.description", defaultValue="", data=[ entityTag ] ) )
						, required    = true
						, content     = { "application/json" = {
							schema = { "$ref"="##/components/schemas/#entityName#" }
						  } }
					  }
					, responses = {
						  "200" = {
							  description = $translateResource( uri="dataapi:operation.#entityName#.put.by.id.200.description", defaultValue=$translateResource( uri="dataapi:operation.put.by.id.200.description", defaultValue="" ) )
							, content     = { "application/json" = { schema={ "$ref"="##/components/schemas/#entityName#" } } }
						  }
						, "404" = {
							  description = $translateResource( uri="dataapi:operation.#entityName#.put.by.id.404.description", defaultValue=$translateResource( uri="dataapi:operation.put.by.id.404.description", defaultValue="" ) )
						  }
						, "422" = {
							  description = $translateResource( uri="dataapi:operation.#entityName#.put.by.id.422.description", defaultValue=$translateResource( uri="dataapi:operation.put.by.id.422.description", defaultValue="", data=[ entityTag ] ) )
							, content     = { "application/json" = { schema={ type="array", items={ "$ref"="##/components/schemas/validationMessage" } } } }
						  }
					  }
					, parameters = [ {
							name        = "recordId"
						  , in          = "path"
						  , required    = true
						  , description = $translateResource( uri="dataapi:operation.#entityName#.put.by.id.params.queueId", defaultValue=$translateResource( uri="dataapi:operation.put.by.id.params.recordId", defaultValue="", data=[ entityTag ] ) )
						  , schema      = { type="string" }
					  } ]
				};
			}

			if ( configService.entityVerbIsSupported( entityName, "post" ) ) {
				spec.paths[ "/entity/#entityName#/" ].post = {
					  tags = [ entityTag ]
					, description = $translateResource( uri="dataapi:operation.#entityName#.post.description", defaultValue=$translateResource( uri="dataapi:operation.post.description", defaultValue="", data=[ entityTag ] ) )
					, requestBody = {
						  description = $translateResource( uri="dataapi:operation.#entityName#.post.body.description", defaultValue=$translateResource( uri="dataapi:operation.post.body.description", defaultValue="", data=[ entityTag ] ) )
						, required    = true
						, content     = { "application/json" = {
							schema={ type="array", items={"$ref"="##/components/schemas/#entityName#" } }
						  } }
					  }
					, responses = {
						  "200" = {
							  description = $translateResource( uri="dataapi:operation.#entityName#.post.200.description", defaultValue=$translateResource( uri="dataapi:operation.post.200.description", defaultValue="", data=[ entityTag ] ) )
							, content     = { "application/json" = { schema={ type="array", items={"$ref"="##/components/schemas/#entityName#" } } } }
						  }
						, "422" = {
							  description = $translateResource( uri="dataapi:operation.#entityName#.post.422.description", defaultValue=$translateResource( uri="dataapi:operation.post.422.description", defaultValue="", data=[ entityTag ] ) )
							, content     = { "application/json" = { schema={ type="array", items={ "$ref"="##/components/schemas/validationFailureMultiple#entityName#" } } } }
						  }
					  }
				};
			}

			if ( configService.entityVerbIsSupported( entityName, "delete" ) ) {
				spec.paths[ "/entity/#entityName#/{recordId}/" ].delete = {
					  tags = [ entityTag ]
					, description = $translateResource( uri="dataapi:operation.#entityName#.delete.description", defaultValue=$translateResource( uri="dataapi:operation.delete.description", defaultValue="", data=[ entityTag ] ) )
					, responses = { "200" = {
						  description = $translateResource( uri="dataapi:operation.#entityName#.delete.200.description", defaultValue=$translateResource( uri="dataapi:operation.delete.200.description", defaultValue="" ) )
						, content     = { "application/json" = { schema={ required=[ "deleted" ], properties={ deleted={ type="integer", description=$translateResource( uri="dataapi:operation.delete.schema.removed" ) } } } } }
					  } }
					, parameters = [ {
							name        = "recordId"
						  , in          = "path"
						  , required    = true
						  , description = $translateResource( uri="dataapi:operation.#entityName#.delete.params.queueId", defaultValue=$translateResource( uri="dataapi:operation.delete.params.recordId", defaultValue="", data=[ entityTag ] ) )
						  , schema      = { type="string" }
					  } ]
				};
			}

		}
	}

	private struct function _getEntitySchema( required string entityName ) {
		return { required=[ "test" ], properties={ test={ type="string", description="test description" } } };
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