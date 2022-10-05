# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

config :plsm,
  module_name: "PlsmTest",
  destination: "test/schemas",
  server: "localhost",
  port: 5432,
  database: System.get_env("DB_NAME", "db"),
  username: System.get_env("DB_USER", "postgres"),
  password: System.get_env("DB_PASS", "postgres"),
  type: :postgres,
  typed_schema: true

# overwrite:     false
