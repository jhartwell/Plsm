## Changes in 2.3.2

## Bug fix

* Removed `@primary_key` as a means to indicate primary key and now use `field/3`
* Changed :text to :string based on latest version of Ecto

## Changes in 2.3.1

## Bug fix

* Fix casting calls in the generated schema files

## Changes in 2.3.0

## Update

* Updated database dependencies to work with the latest version of Phoenix

## Changes in 2.2.0

## Feature

* Removed Ecto.DateTime from the type output and replaced it with naive_datetime
* For MySql, tinyint(1) now maps to boolean type rather than an integer
* Changed MySql and PostgresSQL to use :text rather than :string in order to accommodate char values that are longer than 255 characters

## Other Changes

* Updated the required version of Elixir from 1.3 to 1.5
* Started using Travis CI

## Changes in 2.0.1

## Bugfixes

* Fixed issue with generating output when there are no foreign keys. Previously was erroring out and the new fix will ignore foreign key generation if there are no foreign keys



## New in 2.0.0

* Updated config generation. We now use config/config.exs as the default location for the configs. You can pass in the flag --config-file with a file name to use a different file (such as the dev.exs in Phoenix)

* Foreign key support in PostgeSQL 

## Minor Changes

* Added TINYINT() and BIT() fields from MySQL and mapped them to :integer (this was in 1.1.3 but that is a short-lived release so it is documented here)

## Bugfixes

* None
