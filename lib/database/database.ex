defprotocol Plsm.Database do
  alias Plsm.Database.{TableHeader, Column}

  defstruct server:       "",
            port:         "",
            database:     "",
            username:     "",
            password:     "",
            type:         :mysql,
            schema:       "",
            typed_schema: false,
            overwrite:    false,
            app:          nil

  @type t :: %__MODULE__{
    server:       String.t,
    port:         String.t | integer,
    database:     String.t,
    username:     String.t,
    password:     String.t,
    type:         :mysql | :postgres,
    schema:       String.t,
    typed_schema: boolean,
    overwrite:    boolean,
    app:          atom
  }

  @doc "Connect to the given database"
  @spec connect(map) :: Plsm.Database.t
  def   connect(db)

  @doc "Get all of the tables that are in the database that was selected"
  @spec get_tables(map) :: [TableHeader.t]
  def   get_tables(db)

  @doc "Get the columns for the table that is passed in"
  @spec get_columns(map, TableHeader.t) :: [Column.t]
  def   get_columns(db, table)

  @doc "Get all known enum types with their values"
  @spec get_enums(map) :: %{String.t => [String.t]}
  def   get_enums(db)
end
