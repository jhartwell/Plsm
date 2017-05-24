## New in 2.0.0

* Updated config generation. We now use config/config.exs as the default location for the configs. You can pass in the flag --config-file with a file name to use a different file (such as the dev.exs in Phoenix)

* Foreign key support in PostgeSQL 

## Minor Changes

* Added TINYINT() and BIT() fields from MySQL and mapped them to :integer (this was in 1.1.3 but that is a short-lived release so it is documented here)

## Bugfixes

* None