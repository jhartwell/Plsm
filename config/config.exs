# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :plasm, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:plasm, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

#  Plsm configs are used to drive the extraction process. Below are what each field means:
#    * module_name -> This is the name of the module that the models will be placed under
#    * destination -> The output location for the generated models
#    * server -> this is the name of the server that you are connecting to. It can be a DNS name or an IP Address. This needs to be filled in as there are no defaults
#    * port -> The port that the database server is listening on. This needs to be provided as there may not be a default for your server
#    * database -> the name of the database that you are connecting to. This is required.
#    * username -> The username that is used to connect. Make sure that there is sufficient privileges to be able to connect, query tables as well as query information schemas on the database. The schema information is used to find the index/keys on each table
#    * password -> This is necessary as there is no default nor is there any handling of a blank password currently.
#    * type -> This dictates which database vendor you are using. We currently support PostgreSQL and MySQL. If no value is entered then it will default to MySQL. Accepted values: :mysql or :postgres. Do note that this is an atom and not a string

config :plsm,
  module_name: "module name",
  destination: "output path",
  server:      "localhost",
  port:        5432,
  database:    "name of database",
  username:    "username",
  password:    "password",
  type:        :postgres

File.exists?("config/#{config_env()}.exs") && import_config "#{config_env()}.exs"
