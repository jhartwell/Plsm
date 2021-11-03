defmodule Plsm.Database.MySql do
  defstruct server: "localhost",
            port: "3306",
            username: "username",
            password: "password",
            database_name: "db",
            connection: nil
end

defimpl Plsm.Database, for: Plsm.Database.MySql do
  @doc """
    Create a MySql database struct for use in connecting to the MySql database.
    We pass in the configs in order to properly connect
  """
  @spec create(Plsm.Database.MySql, Plsm.Configs) :: Plsm.Database.MySql
  def create(_db, configs) do
    %Plsm.Database.MySql{
      server: configs.database.server,
      port: configs.database.port,
      username: configs.database.username,
      password: configs.database.password,
      database_name: configs.database.database_name
    }
  end

  @spec connect(Plsm.Database.MySql) :: Plsm.Database.MySql
  def connect(db) do
    {_, conn} =
      MyXQL.start_link(
	protocol: :tcp,
        hostname: db.server,
        username: db.username,
        port: db.port,
        password: db.password,
        database: db.database_name
      )

    %Plsm.Database.MySql{
      connection: conn,
      server: db.server,
      port: db.port,
      username: db.username,
      password: db.password,
      database_name: db.database_name
    }
  end

  # Pass in a database and then get the tables using the `SHOW TABLES` query,
  # then turn the rows into a table.
  @spec get_tables(Plsm.Database.MySql) :: [Plsm.Database.TableHeader]
  def get_tables(db) do
    {_, result} = MyXQL.query(db.connection, "SHOW TABLES")

    result.rows
    |> List.flatten()
    |> Enum.map(fn x -> %Plsm.Database.TableHeader{database: db, name: x} end)
  end

  @spec get_columns(Plsm.Database.MySql, Plsm.Database.Table) :: [Plsm.Database.Column]
  def get_columns(db, table) do
    {_, result} = MyXQL.query(db.connection, "show columns from `#{table.name}`")

    result.rows
    |> Enum.map(&to_column/1)
  end

  defp to_column(row) do
    {_, name} = Enum.fetch(row, 0)
    {_, type} = Enum.fetch(row, 1)
    {_, prik} = Enum.fetch(row, 3)

    pkey = (prik == "PRI")

    %Plsm.Database.Column{name: name, type: trans_type(type), primary_key: pkey, db_type: type}
  end

  # Intermediate type designation. The Export module determines the final ecto type.
  defp trans_type(db_type) do
    downcase = String.downcase(db_type)

    cond do
      String.starts_with?(downcase, "tinyint(1)") -> :boolean
      String.starts_with?(downcase, "tinyint")    -> :integer
      String.starts_with?(downcase, "smallint")   -> :integer
      String.starts_with?(downcase, "mediumint")  -> :integer
      String.starts_with?(downcase, "int")        -> :integer
      String.starts_with?(downcase, "bigint")     -> :integer
      String.starts_with?(downcase, "float")      -> :float
      String.starts_with?(downcase, "double")     -> :float
      String.starts_with?(downcase, "decimal")    -> :decimal
      String.starts_with?(downcase, "numeric")    -> :decimal
      String.starts_with?(downcase, "date")       -> :date
      String.starts_with?(downcase, "time")       -> :time
      String.starts_with?(downcase, "year")       -> :date  # integer?
      String.starts_with?(downcase, "datetime")   -> :datetime
      String.starts_with?(downcase, "timestamp")  -> :timestamp
      String.starts_with?(downcase, "bit(1)")     -> :boolean
      String.starts_with?(downcase, "bit")        -> :binary
      String.starts_with?(downcase, "binary")     -> :binary      
      String.starts_with?(downcase, "varbinary")  -> :binary
      String.starts_with?(downcase, "tinyblob")   -> :binary
      String.starts_with?(downcase, "blob")       -> :binary
      String.starts_with?(downcase, "mediumblob") -> :binary
      String.starts_with?(downcase, "longblob")   -> :binary
      String.starts_with?(downcase, "char")       -> :string
      String.starts_with?(downcase, "varchar")    -> :string
      String.starts_with?(downcase, "tinytext")   -> :string
      String.starts_with?(downcase, "text")       -> :string
      String.starts_with?(downcase, "mediumtext") -> :string
      String.starts_with?(downcase, "longtext")   -> :string
      true -> :none
    end
  end
end
