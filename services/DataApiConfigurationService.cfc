/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @presideFieldRuleGenerator.inject presideFieldRuleGenerator
	 *
	 */
	public any function init( required any presideFieldRuleGenerator ) {
		_localCache = {};

		_setPresideFieldRuleGenerator( arguments.presideFieldRuleGenerator );

		return this;
	}

// PUBLIC API METHODS
	public boolean function entityIsEnabled( required string entity ) {
		var args     = arguments;
		var cacheKey = "entityIsEnabled" & args.entity;

		return _simpleLocalCache( cacheKey, function(){
			var entities = getEntities();

			return entities.keyExists( args.entity );
		} );
	}

	public boolean function entityVerbIsSupported( required string entity, required string verb ) {
		var args     = arguments;
		var cacheKey = "entityVerbIsSupported" & args.entity & args.verb;

		return _simpleLocalCache( cacheKey, function(){
			var entities = getEntities();
			var verbs    = entities[ args.entity ].verbs ?: [];

			return !verbs.len() || verbs.find( lcase( args.verb ) );
		} );
	}

	public string function getEntityObject( required string entity ) {
		var args     = arguments;
		var cacheKey = "getEntityObject" & args.entity;

		return _simpleLocalCache( cacheKey, function(){
			var entities = getEntities();
			return entities[ args.entity ].objectName ?: "";
		} );
	}

	public string function getSelectSortOrder( required string entity ) {
		var args     = arguments;
		var cacheKey = "getSelectSortOrder" & args.entity;

		return _simpleLocalCache( cacheKey, function(){
			var objectName = getEntityObject( args.entity );
			var poService  = $getPresideObjectService();
			var sortOrder  = poService.getObjectAttribute( objectName, "dataApiSortOrder" );

			if ( !Len( Trim( sortOrder ) ) ) {
				sortOrder = poService.getDateModifiedField( objectName );

				if ( !Len( Trim( sortOrder ) ) ) {
					sortOrder = poService.getDateCreatedField( objectName );
				}
			}

			return sortOrder;
		} );
	}

	public array function getSelectFields( required string entity ) {
		var args     = arguments;
		var cacheKey = "getSelectFields" & args.entity;

		return _simpleLocalCache( cacheKey, function(){
			var entities = getEntities();
			return entities[ args.entity ].selectFields ?: [];
		} );
	}

	public array function getUpsertFields( required string entity ) {
		var args     = arguments;
		var cacheKey = "getUpsertFields" & args.entity;

		return _simpleLocalCache( cacheKey, function(){
			var entities = getEntities();
			return entities[ args.entity ].upsertFields ?: [];
		} );
	}

	public struct function getFieldSettings( required string entity ) {
		var args     = arguments;
		var cacheKey = "getFieldSettings" & args.entity;

		return _simpleLocalCache( cacheKey, function(){
			var objectName    = getEntityObject( args.entity );
			var props         = $getPresideObjectService().getObjectProperties( objectName );
			var fieldSettings = {};

			for( var field in props ) {
				fieldSettings[ field ] = {
					  alias    = props[ field ].dataApiAlias    ?: field
					, renderer = props[ field ].dataApiRenderer ?: _getDefaultRendererForField( props[ field ] ?: {} )
				};
			}

			return fieldSettings;
		} );
	}

	public struct function getEntities() {
		var cacheKey = "getEntities";

		return _simpleLocalCache( cacheKey, function(){
			var poService = $getPresideObjectService();
			var objects  = poService.listObjects();
			var entities = {};

			for( var objectName in objects ) {
				var isEnabled = poService.getObjectAttribute( objectName, "dataApiEnabled" );
				if ( IsBoolean( isEnabled ) && isEnabled ) {
					var entityName     = poService.getObjectAttribute( objectName, "dataApiEntityName", objectName );
					var supportedVerbs = poService.getObjectAttribute( objectName, "dataApiVerbs", "" );
					var selectFields   = poService.getObjectAttribute( objectName, "dataApiFields", "" );
					var upsertFields   = poService.getObjectAttribute( objectName, "dataApiUpsertFields", "" );

					entities[ entityName ] = {
						  objectName   = objectName
						, verbs        = ListToArray( LCase( supportedVerbs ) )
						, selectFields = ListToArray( LCase( selectFields ) )
						, upsertFields = ListToArray( LCase( upsertFields ) )
					};

					if ( !entities[ entityName ].selectFields.len() ) {
						entities[ entityName ].selectFields = _defaultSelectFields( objectName );
					}
					if ( !entities[ entityName ].upsertFields.len() ) {
						entities[ entityName ].upsertFields = entities[ entityName ].selectFields;
					}

					entities[ entityName ].upsertFields = _cleanupUpsertFields( objectName, entities[ entityName ].upsertFields );
				}
			}

			return entities;
		} );
	}

	public string function getValidationRulesetForEntity( required string entity ) {
		var args     = arguments;
		var cacheKey = "getValidationRulesetForEntity" & args.entity;

		return _simpleLocalCache( cacheKey, function(){
			var validationEngine = $getValidationEngine();
			var rulesetName      = "data-api-#args.entity#";

			if ( !validationEngine.rulesetExists( rulesetName ) ) {
				var objectName = getEntityObject( args.entity );
				var props      = $getPresideObjectService().getObjectProperties( objectName );
				var fields     = getUpsertFields( args.entity );
				var rules      = [];
				var generator  = _getPresideFieldRuleGenerator();

				for( var fieldName in fields ) {
					rules.append( generator.getRulesForField(
						  objectName      = objectName
						, fieldName       = fieldName
						, fieldAttributes = props[ fieldName ] ?: {}
					), true );
				}

				validationEngine.newRuleset(
					  name  = rulesetName
					, rules = rules
				);
			}

			return rulesetName;
		} );
	}

// PRIVATE HELPERS
	private any function _simpleLocalCache( required string cacheKey, required any generator ) {
		if ( !_localCache.keyExists( arguments.cacheKey ) ) {
			_localCache[ cacheKey ] = generator();
		}

		return _localCache[ cacheKey ];
	}

	private string function _getDefaultRendererForField( required struct field ) {
		switch( field.relationship ?: "" ) {
			case "many-to-many": return "array";
		}

		switch( field.type ?: "" ) {
			case "date":
				if ( ( field.dbtype ?: "" ) == "date" ) {
					return "date";
				}
				return "datetime";
			break;
			case "boolean":
				if ( IsBoolean( field.required ?: "" ) && field.required ) {
					return "strictboolean";
				}

				return "nullableboolean";
			break;
			case "string":
				return $getContentRendererService().getRendererForField( field );
			break;
		}

		return "none";
	}

	private array function _defaultSelectFields( required string objectName ) {
		var dbFields            = $getPresideObjectService().getObjectAttribute( objectName, "dbFieldlist" );
		var props               = $getPresideObjectService().getObjectProperties( objectName );
		var defaultSelectFields = ListToArray( LCase( dbFields ) );

		for( var fieldName in props ) {
			if ( defaultSelectFields.find( LCase( fieldName ) ) ) {
				continue;
			}

			if ( Len( Trim( props[ fieldName ].formula ?: "" ) ) ) {
				defaultSelectFields.append( fieldName );
			}
		}

		return defaultSelectFields;
	}

	private array function _cleanupUpsertFields( required string objectName, required array fields ) {
		var props    = $getPresideObjectService().getObjectProperties( objectName );
		var idField  = $getPresideObjectService().getIdField( objectName );
		var cleaned  = [];

		for( var field in arguments.fields ) {
			if ( field == idField || field == "id" ) {
				continue;
			}

			if ( ( props[ field ].relationship ?: "" ) == "one-to-many" ) {
				continue;
			}

			if ( Len( Trim( props[ field ].formula ?: "" ) ) ) {
				continue;
			}

			cleaned.append( field );
		}

		return cleaned;
	}

// GETTERS AND SETTERS
	private any function _getPresideFieldRuleGenerator() {
		return _presideFieldRuleGenerator;
	}
	private void function _setPresideFieldRuleGenerator( required any presideFieldRuleGenerator ) {
		_presideFieldRuleGenerator = arguments.presideFieldRuleGenerator;
	}
}