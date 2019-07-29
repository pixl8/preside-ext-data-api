# Preside Data API Extension

The Data API extension provides developers with the power to rapidly develop APIs against their Preside data models. With a few simple object annotations and optional i18n resource keys, developers are able to provide full CRUD APIs to the data model with beautifully rendered API documentation.

**Note**: Version **3.0.0** requires Preside version **10.11.0** and above.

## Accessing the API

The **default** root URI of the API is `/api/data/v1/` (see _Namespaces and multiple APIs_, further below). OpenAPI v3 specification can be browsed at `/api/data/v1/docs/spec/` and HTML documentation based on the spec can be found at `/api/data/v1/docs/html/` (or `/api/data/v1/docs/swagger/`, if you prefer).

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
* `dataApiCategory`: For the HTML documentation. Allows sub-groups of entities. Especially useful for large APIs.
* `dataApiQueueEnabled`: Whether or not the change queue is enabled for this object
* `dataApiQueue`: Specific queue name for this object
* `dataApiSortOrder`: Sort order for paginated results. Default is date last modified ascending.
* `dataApiSavedFilters`: Comma-separated list of saved filters to apply to all requests to this object (e.g. only return active records)
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
* `dataApiType`: For the documentation. The data type of the property, e.g. 'string'.
* `dataApiFormat`: For the documentation. The format for the property, e.g. 'Email address'.
* `dataApiEnabled`: Whether or not this property should be included in the API
* `dataApiUpsertEnabled`: Whether or not this property should be included in the POST/PUT operations.

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
api.favicon=data:image/x-icon;base64,iVBOR...
```

### Categories

If you annotate your objects with a `@dataApiCategory` property, your categories can be documented with:

```
category.my_category.name=My Category
category.my_category.description=Markdown enabled description of my category.
category.my_category.sort.order=20
```

### Object and field level customizations

The following set of `.properties` file keys can be added _per_ object in your own `dataapi.properties` files to customize the documentation per entity/field:


```
# OBJECT LEVEL:

dataapi:entity.my_entity.name=My entities
dataapi:entity.my_entity.name.singular=My entity
dataapi:entity.my_entity.description=Description of my entity (or API description for this section of the docs)
dataapi:entity.my_entity.sort.order=10

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

## Data Change Queue(s)

By default, they system enables a queue feature: `settings.features.dataApiQueue`. When enabled, API users can be subscribed, through the admin UI, to listen for data changes to all, or a number, of entities in the system.

### Configuring the queue system

As of **v3.0.0**, you have the ability to configure multiple queue endpoints per API (see also, _Namespaces and multiple APIs_, below). This can be used to group entities into queues so that multiple different services can process the queues independently. The available settings per queue are:

* `pageSize`: Number of records returned with each call to queue. Default is **1**
* `atomicChanges`: Whether or not the queue should return atomic changes. If true, each item in the queue will contain only the fields that have changed. If false, default, each item in the queue will contain the latest state of the record. Default is **false**.

#### Defining queues

Queues are defined in the Preside rest API configuration in `Config.cfc`. To add a queue definition to the default API:

```cfc
settings.rest.apis[ "/data/v1" ].dataApiQueueEnabled = true;
settings.rest.apis[ "/data/v1" ].dataApiQueues = {
	  default    = { pageSize=100, atomicChanges=true } // the default queue
	, highvolume = { pageSize=1000, atomicChanges=false }
};
```

#### Per object queue settings:

Annotate your preside object CFC with `@dataApiQueueEnabled` (default is **true**) and `@dataApiQueue` (default is **default**) properties. For example:


```cfc
/**
 * @dataApiQueueEnabled false
 */
```

or

```cfc
/**
 * @dataApiQueue highvolume
 */
```


## Namespaces and multiple APIs

*Introduced in v2.0.0*

By default, the API is exposed at `/api/data/v1/`. However, there will be occasions when you want to expose your data in different ways for different purposes. Or, if you are writing an extension, you may want to namespace your API so that it does not clash with any existing default API implementation. You can also use this feature to host multiple versions of your API concurrently.

With just a small amount of configuration, you can use all of the Data API's functionality in a separate, namespaced instance. First, configure the endpoints in your `Config.cfc`:

```
settings.rest.apis[ "/myGroovyApi/v1" ] = {
	  authProvider     = "dataApi"
	, description      = "REST API to expose data with an alternate structure"
	, dataApiNamespace = "myGroovyApi"
	, dataApiQueueEnabled = true
	, dataApiQueues       = {
		default = { pageSize=100, atomicChanges=true }
	  }
};
settings.rest.apis[ "/myGroovyApi/v1/docs" ] = {
	  description      = "Documentation for myGroovyApi REST API (no authentication required)"
	, dataApiNamespace = "myGroovyApi"
	, dataApiDocs      = true
};
```

A few things to note here:

* The key within `settings.rest.apis` (e.g. `/myGroovyApi/v1`) is the base URI for the API. This will have `/api` prepended to it in the full URL.
* `dataApiNamespace` is the namespace for the alternate API, and will be used when configuring objects. This will usually be the first part of the URI, but does not need to be.
* `dataApiDocs` marks that this is the endpoint for the Swagger documentation. This whole endpoint could be omitted if you do not require the automatic document generation.
* Use `authProvider` to mark an endpoint as needing authentication. If you omit this, the resource will not require authentication. In the API Manager in Preside, you can allow users to have access to individual APIs - so a user could have access to `/api/myGroovyApi/v1` but not to the default `/api/data/v1`, if you wish.

### Annotations

You can annotate your objects using exactly the same annotations as described above, but with `:{namespace}` appended. For example:

```
/**
 * @dataApiEnabled             true
 * @dataApiEnabled:myGroovyApi true
 * @dataApiVerbs:myGroovyApi   GET
 *
 */
component {
	property name="label" dataApiAlias:myGroovyApi="some_other_label";
}
```

This would enable this object both for the default `/data/v1` API, and for your custom `/myGroovyApi/v1` API. However, for `myGroovyApi` the object would only allow `GET` access, and the label field would be called `some_other_label` instead of `label`.

You could also use this to specify an alternate renderer for a property, e.g. `dataApiRenderer:myGroovyApi="alternateRenderer"`.

Note that namespaces do not inherit any annotations from the default API. Any annotations must be made explicitly with the `:{namespace}` suffix.

### Labelling and text

You can use all the same label and description customisations in your `/i18n/dataapi.properties` file as above; simply prefix the key name with `{namespace}.`. For example:

```
myGroovyApi.api.title=My Second API
myGroovyApi.api.description=This is an alternate API to my application

myGroovyApi.entity.my_entity.name=My alternate entity
```

Unlike annotations, i18n properties _will_ cascade up to the defaults. So if you do not make any customisations, you will see all the default text.

### Interceptors

All the same interceptors will run when actions are taken in a namespaced API. However, the interception point name will have `_{namespace}` as a suffix. Again, there is no fallback to the default interceptor, so any interceptors will need to be explicitly defined for your namespace. For example:

```
public void function preDataApiSelectData( event, interceptData ) {
	// action to take for preDataApiSelectData on the default API
}
public void function preDataApiSelectData_myGroovyApi( event, interceptData ) {
	// action to take for preDataApiSelectData on the myGroovyApi API
}
```

## Configuring individual user access

Provided that your APIs use the 'dataApi' auth provider (default), you will be able to manage user access to the APIs through the admin interface.

1. Navigate to: **System** > **API Manager**
2. Find the API you want to manage & click 'Data API authentication'
3. Click Add user
4. Enter a user name (can lookup existing users also) and configure access to individual entities, their verbs and optionally queue access