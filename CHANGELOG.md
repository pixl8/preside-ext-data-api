# Changelog

## v2.0.0

* Add support for multiple configured APIs via namespacing

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