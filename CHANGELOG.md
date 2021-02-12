# Changelog

## v3.1.0

* Introduce new annotation for objects to limit which fields will be watched for pushing changes into a change queue

## v3.0.22

* Explicitly pass args through to documentation view (Preside 10.14 compatibility)

## v3.0.21

* Ensure assets are compiled in build

## v3.0.20

* Move build and deploy to GitHub actions
* Fix: include filters in pagination links

## v3.0.19

* Fix: If object name and the api entity name are different within one entity, no rights can be assigned in the API Manager

## v3.0.18

* Fix missed merge conflict

## v3.0.17

* Add some safety checking for non-existant entities when building permissions forms (fixes potential errors with custom namespace configurations)

## v3.0.16

* Building on `v3.0.15`, `skipApiQueueWhenSkipSyncQueue` now considered for all CRUD data api changes. **Default value is now true**

## v3.0.15

* `skipApiQueueWhenSkipSyncQueue` object decoration to use syncSynQueue intercept data to determine whether to skip the api change queue or not. You can sync object data without it being added to the api change queue.

## v3.0.14

* Fix for issue where there may be custom API configuration for objects that do not exist. Just ignore the configuration rather than raise errors.

## v3.0.13

* Fix for Queue Record Count not being returned for the default queue

## v3.0.12

* Fix for [#43](https://github.com/pixl8/preside-ext-data-api/issues/43). PUT operations could fail when providing an unchanged field that had a unique index.

## v3.0.11

* Reapply accidentally removed code from v3.0.10 pull request.

## v3.0.10

* Add ability to bypass queuing a record in insertData() with `skipDataApiQueue` argument.

## v3.0.9

* [#39](https://github.com/pixl8/preside-ext-data-api/issues/39) Add configuration option for disabling X-Total-Records on queue fetches

## v3.0.8

* Ensure DELETE from queue works in all different queue scenarios

## v3.0.7

* [#38](https://github.com/pixl8/preside-ext-data-api/issues/38) Specifying fields in request should respect property alias

## v3.0.6

* [#37](https://github.com/pixl8/preside-ext-data-api/issues/37) Add `dataApiDerivative` argument to properties for rendering image asset URLs

## v3.0.5

* [#36](https://github.com/pixl8/preside-ext-data-api/issues/36) Fix error where DELETE /queue fails for batch delete on default queue (array of IDs in JSON body)
* [#35](https://github.com/pixl8/preside-ext-data-api/issues/34) Ensure that 404 is shown when API resource URI not found (was throwing 500 error)

## v3.0.4

* [#34](https://github.com/pixl8/preside-ext-data-api/issues/34) Ensure deleting entries from the queue works with all default queues in all namespaces

## v3.0.3

* [#33](https://github.com/pixl8/preside-ext-data-api/issues/33) Ensure all queue items are picked up for default queues

## v3.0.2

* [#29](https://github.com/pixl8/preside-ext-data-api/issues/29) Apply saved filters when queueing changes to data

## v3.0.1

* [#27](https://github.com/pixl8/preside-ext-data-api/issues/27) Use field aliases when documenting and using filter fields in paginated GET requests
* [#26](https://github.com/pixl8/preside-ext-data-api/issues/26) Fix for errors raised when calling API for entity whose primary key is numeric

## v3.0.0

### Administration

* Add admin UI for managing individual user access to entities, verbs and queues

### Queue enhancements

* Ability to turn off the queue feature entirely
* Ability to turn off the queue feature per object
* Allow queue to contain atomic data changes
* Allow queue to return configurable number of records, rather than always 1
* Allow multiple queues for different groups of objects and with individual queue settings

### Documentation enhancements

* Add new plain HTML documentation endpoint
* Object properties should be able to specify type and format for their spec definitions
* Ability to categorize entities (applies to HTML documentation only)
* Ability to set sort order on entities
* Ability to set favicon for an API
* Use plural name of entity for default entity tag name

### Miscellaneous

* Automatically convert foreign keys to assets, links and pages to URLs.
* Ability to exclude/include properties in the API through annotations on the properties

### Bug fixes

* Documentation of foreign keys: only use 'Foreign Key UUID' format when it really is a UUID (i.e., not for int)
* Do not show authentication description when API does not use authentication


## v2.0.2

* Fix path to docs

## v2.0.1

* Better handling of namespaced routes and handler paths
* Update queues to allow namespacing

## v2.0.0

* Add support for multiple configured APIs via namespacing
* Add `dataApiSavedFilters` annotation

## v1.0.19

* Total record count should return filtered count if filter is applied

## v1.0.18

* Prevent stack overflow with recursive loading of services on application startup

## v1.0.17

* [#2](https://github.com/pixl8/preside-ext-data-api/issues/2): Add preValidate interception point for upsert operations

## v1.0.16

* Fixes [#1](https://github.com/pixl8/preside-ext-data-api/issues/1): ensure that booleans are rendered as 'true' or 'false', not '1' or '0'

## v1.0.15

* Add general error message documentation
* When POSTing (creating records), do not ignore missing fields

## v1.0.14

* Add option for specifying whether or not ID field creation is supported

## v1.0.5-1.0.13

* Refactoring build system

## v1.0.4

* Change queue logic so that fetching next item from queue always returns the same item *until* the API user manually removes it from the queue

## v1.0.3

* Fix interceptor logic to not break deletes that use a filter other than record IDs

## v1.0.2

* Improve documentation of queue system API
* Fix the possible field list for the 'fields' REST API param
* Allow for default descriptions of commonly named fields

## v1.0.1

* Initial release
