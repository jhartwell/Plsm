# Plsm

*Instant Ecto Schemas from your database definitions*

If you have an existing project for which you want to add Ecto support, transcribing your database definitions into the necessary Ecto files can be tedious, especially for tables with many columns.

Plsm provides a generator mix task to scaffold these files for you.

**Note:** Currently only Postgres and MySQL are supported

### Installation

The package can be installed by adding `plsm` to your list of dependencies in your `mix.exs`, and running `mix deps.get`

```elixir
def deps do
  [
  # ...
    {:plsm, "~> 2.2.0"},
  # ...
  ]
end
```

### Running Plsm

In order to run plsm, first generate a config file (if you are using Phoenix, it is recommended to to pass in your `config/dev.exs`, as Plsm is a dev-only process):

`mix plsm.config --config-file <name>`


This will create a skeleton config in `<name>`. If none is specified, the config is appended to your `config/config.exs`.


You will also need to make changes to the generated Plsm configs in the config file in order to allow Plsm to function correctly.


#### Options

You can blacklist or whitelist database tables using the `:tables_filters` option in your config.

Add a map whose a key is either `exclude` or `include`, and whose value points to a plaintext file with newline seperated table names. The filename will default to the root of your git directory.

```elixir
config :plsm,
# ...
  table_filters: %{exclude: "blacklist.txt"},
# ...
```

Note if both are included, `plsm` will default to the include.


### Configuration Options

  - `module_name`:  The name of the module under which the schemas will be namespaced
  - `destination`: The output location for the generated schemas. (Defaults to the directory in which you invoked `mix plsm`)
  - `server`: The desired DB server that you are connecting to. Defaults to `localhost`.
  - `port`: The port that the database server is listening on. This needs to be provided as there may not be a default for your server
  - `database_name`: The name of the database that you are connecting to.  Defaults to `postgres`.
  - `username`: The username that is used to connect. You must ensure the user has sufficient privileges to connect, query tables, and query information schemas on the database, or `plsm` will fail.
  - `password`: Name of your database password. Defaults to `postgres`.
  - `type`: The type of database being used; defaults to `postgres`


### Supported Databases

Currently only the following databases are supported:

  - MySQL (5.x)
  - PostgreSQL

If you desire broader DB support, please open a GitHub issue. You are also encouraged to contribute!

If you have any questions you can reach me via email at jon@dontbreakthebuild.com
