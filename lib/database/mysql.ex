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
    Create a MySql database struct for use in connecting to the MySql database. We pass in the configs in order to 
    properly connect
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
      Mariaex.start_link(
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

  # pass in a database and then get the tables using the mariaex query then turn the rows into a table
  @spec get_tables(Plsm.Database.MySql) :: [Plsm.Database.TableHeader]
  def get_tables(db) do
    {_, result} = Mariaex.query(db.connection, "SHOW TABLES")

    result.rows
    |> List.flatten()
    |> Enum.map(fn x -> %Plsm.Database.TableHeader{database: db, name: x} end)
  end

  @spec get_columns(Plsm.Database.MySql, Plsm.Database.Table) :: [Plsm.Database.Column]
  def get_columns(db, table) do
    {_, result} = Mariaex.query(db.connection, "show columns from #{table.name}")

    result.rows
    |> Enum.map(&to_column/1)
  end

  defp to_column(row) do
    {_, name} = Enum.fetch(row, 0)
    type = Enum.fetch(row, 1) |> get_type
    {_, pk} = Enum.fetch(row, 3)
    primary_key? = pk == "PRI"
    %Plsm.Database.Column{name: name, type: type, primary_key: primary_key?}
  end

  defp get_type(start_type) do
    {_, type} = start_type
    downcase = String.downcase(type)

    cond do
      String.starts_with?(downcase, "int") -> :integer
      String.starts_with?(downcase, "bigint") -> :integer
      String.starts_with?(downcase, "tinyint(1)") -> :boolean
      String.starts_with?(downcase, "tinyint") -> :integer
      String.starts_with?(downcase, "bit") -> :integer
      String.contains?(downcase, "char") -> :text
      String.starts_with?(downcase, "text") -> :string
      String.starts_with?(downcase, "float") -> :float
      String.starts_with?(downcase, "double") -> :float
      String.starts_with?(downcase, "decimal") -> :decimal
      String.starts_with?(downcase, "date") -> :date
      String.starts_with?(downcase, "datetime") -> :date
      String.starts_with?(downcase, "timestamp") -> :date
      true -> :none
    end
  end
end
