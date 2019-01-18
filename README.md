# Preside Data API Extension

The Data API extension provides developers with the power to rapidly develop APIs against their Preside data models. With a few simple object annotations and optional i18n resource keys, developers are able to provide full CRUD APIs to the data model with beautifully rendered API documentation.

## Accessing the API

The root URI of the API is `/api/data/v1/`. OpenAPI v3 specification can be browsed at `/api/data/v1/docs/spec/` and HTML documentation based on the spec can be found at `/api/data/v1/docs/swagger/`.

## Configuring your entities

### Object annotations

The _bare minimum_ configuration to enable an object for the API is to set `@dataApiEnabled true`:

```
/**
 * @dataApiEnabled true
 *
 */
component {
	// ...
}
```

Additional _optional_ annotation options at the _object_ level are:

* `dataApiEntityName`: Alternative entity name to use in API urls, e.g. instead of `crm_contact`, you may wish to use `contact`.
* `dataApiSortOrder`: Sort order for paginated results. Default is date last modified ascending.
* `dataApiVerbs`: Supported REST HTTP Verbs. If not supplied, all verbs and operations are supported (i.e. GET, POST, PUT and DELETE)
* `dataApiFields`: Fields to return in GET requests (defaults to all non-excluded fields)
* `dataApiUpsertFields`: Fields to accept in POST/PUT request (defaults to `dataApiFields`)
* `dataApiExcludeFields`: Fields to exclude from GET API calls
* `dataApiUpsertExcludeFields`: Fields **not** to accept in POST/PUT requests (defaults to `dataApiExcludeFields`)
* `dataApiFilterFields`: Fields to allow as simple filters for paginated GET requests (defaults to foreign keys, boolean and enum fields)
* `dataApiAllowIdInsert`: Whether or not to allow the ID field to be set during a POST operation to create a new record

### Property annotations

Object properties support the following _optional_ annotations:

* `dataApiAlias`: An alternative name to use for the property in the API. i.e. instead of `contact_status` you may wish to just use `status` through the API.
* `dataApiRenderer`: A non-default renderer to use when returning data through the API. See custom renderers, below.

## Custom renderers

If you specify a non-default renderer for an object property, it will be rendered using Preside's content rendering system. For example, the following property definition specifies a `myCustomRenderer` renderer:

```
property name="my_prop" dataApiAlias="myProp" dataApiRenderer="myCustomRenderer";
```

To implement this, you will need a corresponding _viewlet_ at `renderers.content.myCustomRenderer.dataapi` **or** `renderers.content.myCustomRenderer.default` (a renderer _context_ of `dataapi` will be used and the system will fallback to the default renderer if that context is not implemented). 

For example:


```
// /handlers/renderers/content/MyCustomRenderer.cfc
component {

	private string function dataApi( event, rc, prc, args={} ){
		var value = args.data ?: "";

		return renderView( view="/renderers/content/myCustomRenderer/dataApi", args={ value=value } );
	}

}
```

## Customizing documentation labels and descriptions

All of the labelling and text in the generated documentation can be found at `/i18n/dataapi.properties` and you should refer to that when customizing the default text. A bare minimum override might look like:


```
api.title=My Application's API
api.description=This is my awesome application's API and here is some general information about it.\n\
\n\
Team awesome xxx.
api.version=v2.0
```

### Object and field level customizations

The following set of `.properties` file keys can be added _per_ object in your own `dataapi.properties` files to customize the documentation per entity/field:


```
# OBJECT LEVEL:

dataapi:entity.my_entity.name=My entity
dataapi:entity.my_entity.description=Description of my entity (or API description for this section of the docs)

dataapi:operation.my_entity.get.description=Description for the paginated GET operation for your entity
dataapi:operation.my_entity.get.200.description=Description for the successful (200) response documentation for paginated GET requests for your entity

dataapi:operation.my_entity.get.by.id.description=Description for the GET /{recordId}/ operation for your entity
dataapi:operation.my_entity.get.by.id.200.description=Description for the successful (200) response documentation for GET /{recordId}/ requests for your entity
dataapi:operation.my_entity.get.by.id.404.description=Description for the not found (404) response documentation for GET /{recordId}/ requests for your entity

dataapi:operation.my_entity.put.description=Description for the PUT / (batch update) operation for your entity
dataapi:operation.my_entity.put.body.description=Description for the http json body for the PUT / (batch update) operation for your entity
dataapi:operation.my_entity.put.200.description=Description for the successful (200) response documentation for PUT / requests for your entity
dataapi:operation.my_entity.put.422.description=Description for the validation failed (422) response documentation for PUT / requests for your entity
dataapi:operation.my_entity.put.by.id.description=Description for the PUT /{recordid}/ (single record update) operation for your entity
dataapi:operation.my_entity.put.by.id.body.description=Description for the http json body for the PUT /{recordid}/ (single record update) operation for your entity
dataapi:operation.my_entity.put.by.id.200.description=Description for the successful (200) response documentation for PUT /{recordid}/ requests for your entity
dataapi:operation.my_entity.put.by.id.422.description=Description for the validation failed (422) response documentation for PUT /{recordid}/ requests for your entity
dataapi:operation.my_entity.put.by.id.404.description=Description for the record not found (404) response documentation for PUT /{recordid}/ requests for your entity

dataapi:operation.my_entity.post.description=Description of the POST / (batch insert) operation for your entity
dataapi:operation.my_entity.post.body.description=Description for the http json body for the POST / (batch insert) operation for your entity
dataapi:operation.my_entity.post.200.description=Description for the successful (200) response documentation for POST / requests for your entity
dataapi:operation.my_entity.post.422.description=Description for the validation failed (422) response documentation for POST / requests for your entity

dataapi:operation.my_entity.delete.description=Description of the DELETE /{recordid}/ operation for your entity
dataapi:operation.my_entity.delete.200.description=Description of the successful (200) response documentation for DELETE /{recordId}/ operations for your entity

# Field level
dataapi:operation.my_entity.get.params.fields.my_field.description=Description for *filter* field
dataapi:entity.my_entity.field.my_field.description=Description of field
```

## Further customizations using interceptors

The following interception points are used to allow you to more deeply customize the integration.

### `onOpenApiSpecGeneration`

Fired when generating OpenApi v3 specification for the API. A `spec` struct will be present in the `interceptorArgs` that you can use to augment the specification.

### `preDataApiSelectData`

Fired before selecting data through the API. Receives the following keys in the `interceptData`:

* `selectDataArgs`: Arguments that will be passed to the `selectData()` call
* `entity`: Name of the entity being operated on

### `postDataApiSelectData`

Fired after selecting data through the API. Receives the following keys in the `interceptData`:

* `selectDataArgs`: Arguments that were passed to the `selectData()` call
* `entity`: Name of the entity being operated on
* `data`: Rendered and prepared data that will be returned to the API caller

### `preDataApiInsertData`

Fires before inserting data through the API. Receives the following keys in the `interceptData`:

* `insertDataArgs`: Arguments that will be passed to the `insertData()` call
* `entity`: Name of the entity being operated on
* `record`: The data that will be inserted (struct)


### `postDataApiInsertData`

Fires after inserting data through the API. Receives the following keys in the `interceptData`:

* `insertDataArgs`: Arguments that were passed to the `insertData()` call
* `entity`: Name of the entity being operated on
* `record`: The data that will be inserted (struct)
* `newId`: Newly created record ID


### `preDataApiUpdateData`

Fires before updating data through the API. Receives the following keys in the `interceptData`:

* `updateDataArgs`: Arguments that will be passed to the `updateData()` call
* `entity`: Name of the entity being operated on
* `recordId`: ID of the record to be updated
* `data`: The data that will be inserted (struct)

### `postDataApiUpdateData`

Fires after updating data through the API. Receives the following keys in the `interceptData`:

* `updateDataArgs`: Arguments that were passed to the `updateData()` call
* `entity`: Name of the entity being operated on
* `recordId`: ID of the record to be updated
* `data`: The data that will be inserted (struct)

### `preDataApiDeleteData`

Fires before deleting data through the API. Receives the following keys in the `interceptData`:

* `deleteDataArgs`: Arguments that will be passed to the `deleteData()` call
* `entity`: Name of the entity being operated on
* `recordId`: ID of the record to be deleted

### `postDataApiDeleteData`

Fires after deleting data through the API. Receives the following keys in the `interceptData`:

* `deleteDataArgs`: Arguments that were passed to the `deleteData()` call
* `entity`: Name of the entity being operated on
* `recordId`: ID of the record to be deleted

## The Data Queue and per user/object permissioning

In addition to simple CRUD operations for entities, the system also provides a data change queue for API users to subscribe to. **There is currently no user interface for this!**. To enable the queue for an API user (API users can be found and managed in Preside admin -> System -> API Manager), you will need to run the following SQL:

```
insert into pobj_data_api_user_settings (
	  user
	, object_name
	, subscribe_to_deletes
	, subscribe_to_updates
	, subscribe_to_inserts
	, access_allowed
	, get_allowed
	, put_allowed
	, delete_allowed
	, post_allowed
) values (
	   '{id of user}' /* user                 */
	,  null           /* object_name          */
	,  1              /* subscribe_to_deletes */
	,  1              /* subscribe_to_updates */
	,  1              /* subscribe_to_inserts */
	,  1              /* access_allowed       */
	,  1              /* get_allowed          */
	,  1              /* put_allowed          */
	,  1              /* delete_allowed       */
	,  1              /* post_allowed         */
)
```
