/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	public any function init() {
		_localCache = {};

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

	public struct function getEntities() {
		var cacheKey = "getEntities";

		return _simpleLocalCache( cacheKey, function(){
			var poService = $getPresideObjectService();
			var objects  = poService.listObjects();
			var entities = {};

			for( var object in objects ) {
				var isEnabled = poService.getObjectAttribute( object, "dataApiEnabled" );
				if ( IsBoolean( isEnabled ) && isEnabled ) {
					var entityName     = poService.getObjectAttribute( object, "dataApiEntityName", object );
					var supportedVerbs = poService.getObjectAttribute( object, "dataApiVerbs", "" );
					entities[ entityName ] = { verbs = ListToArray( LCase( supportedVerbs ) ) };
				}
			}

			return entities;
		} );
	}

// PRIVATE HELPERS
	private any function _simpleLocalCache( required string cacheKey, required any generator ) {
		if ( !_localCache.keyExists( arguments.cacheKey ) ) {
			_localCache[ cacheKey ] = generator();
		}

		return _localCache[ cacheKey ];
	}
}