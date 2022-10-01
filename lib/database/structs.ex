defmodule Plsm.Database.Factory do
  @doc """
  Create a struct that implements the Plsm.Database protocol based on the type
  of database that is passed in
  """
  @spec create(Plsm.Config.t) :: Plsm.Database.t
  def create(config) do
    {db_type, db_app, out} =
      case config.database.type do
        :mysql    -> {Plsm.Database.MySql,      :myxql,    "MySql"}
        :postgres -> {Plsm.Database.PostgreSQL, :postgrex, "PostgreSQL"}
        _         -> {Plsm.Database.PostgreSQL, :postgrex, "default database PostgreSQL"}
      end
    IO.puts("Using #{out}...")

    struct(db_type,
      server:   config.database.server,
      port:     config.database.port,
      username: config.database.username,
      password: config.database.password,
      database: config.database.database,
      schema:   config.database.schema,
      app:      db_app
    )
  end
end

defmodule Plsm.Database.Column do
  defstruct name: nil, type: :none, primary_key: false, nullable: true,
            foreign_table: nil, foreign_field: nil, default: nil,
            auto_inc: false, size: nil

  @type t :: %__MODULE__{
    name:           String.t,
    type:           atom,
    primary_key:    boolean,
    nullable:       boolean,
    foreign_table:  String.t,
    foreign_field:  String.t,
    default:        String.t,
    auto_inc:       boolean,
    size:           integer
  }
end

defmodule Plsm.Database.Table do
  defstruct columns: nil, header: nil

  @type t :: %__MODULE__{
    columns: [Plsm.Database.Column.t],
    header:  Plsm.Database.TableHeader.t
  }
end

defmodule Plsm.Database.TableHeader do
  defstruct name: nil, database: nil

  @type t :: %__MODULE__{name: String.t, database: Plsm.Database.t}

  def table_name(table_name) do
    table_name
    |> String.split("_")
    |> singularize()
    |> Enum.map(fn x -> String.capitalize(x) end)
    |> Enum.reduce(fn x, acc -> acc <> x end)
  end

  def singularize([word]), do: [Inflex.singularize(word)]

  def singularize([first | rest]) do
    [first | singularize(rest)]
  end
end
