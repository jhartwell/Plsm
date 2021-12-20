defmodule Plsm.Database.SQLite do
  defstruct filename: "filename.sqlite",
            connection: nil
end

defimpl Plsm.Database, for: Plsm.Database.SQLite do
  @doc """
    Create a SQLite database struct. We pass in the configs in order to
    properly open the SQLite database
  """
  @spec create(Plsm.Database.SQLite, Plsm.Configs) :: Plsm.Database.SQLite
  def create(_db, configs) do
    %Plsm.Database.SQLite{
      filename: configs.database.filename,
    }
  end

  @spec connect(Plsm.Database.SQLite) :: Plsm.Database.SQLite
  def connect(db) do
    {_, conn} = Exqlite.Sqlite3.open(db.filename)

    %Plsm.Database.SQLite{
      connection: conn,
      filename: db.filename,
    }
  end

  @spec get_tables(Plsm.Database.SQLite) :: [Plsm.Database.TableHeader]
  def get_tables(db) do
    {_, statement} = Exqlite.Sqlite3.prepare(db.connection, "
      SELECT
        name
      FROM
        sqlite_schema
      WHERE
        type = 'table'
        AND name NOT LIKE 'sqlite_%'"
    )

    {_, result} = Exqlite.Sqlite3.fetch_all(db.connection, statement)

    result
    |> List.flatten()
    |> Enum.map(fn x -> %Plsm.Database.TableHeader{database: db, name: x} end)
  end

  @spec get_columns(Plsm.Database.SQLite, Plsm.Database.Table) :: [Plsm.Database.Column]
  def get_columns(db, table) do
    {_, statement} = Exqlite.Sqlite3.prepare(db.connection, "PRAGMA table_info(#{table.name})")
    {_, result} = Exqlite.Sqlite3.fetch_all(db.connection, statement)

    result
    |> Enum.map(&to_column/1)
  end

  defp to_column(row) do
    {_, name} = Enum.fetch(row, 1)
    type = Enum.fetch(row, 2) |> get_type
    {_, pk} = Enum.fetch(row, 5)
    primary_key? = pk == 1
    %Plsm.Database.Column{name: name, type: type, primary_key: primary_key?}
  end

  defp get_type(start_type) do
    {_, type} = start_type
    downcase = String.downcase(type)

    cond do
      # Determines types using the rules under paragraph 3.1 in SQLite docs:
      # https://www.sqlite.org/datatype3.html
      String.contains?(downcase, "int") -> :integer
      String.contains?(downcase, "char") -> :string
      String.contains?(downcase, "clob") -> :string
      String.contains?(downcase, "text") -> :string
      String.contains?(downcase, "real") -> :float
      String.contains?(downcase, "floa") -> :float
      String.contains?(downcase, "doub") -> :float

      # Useful use cases
      String.starts_with?(downcase, "boolean") -> :boolean
      String.starts_with?(downcase, "text_datetime") -> :date
      String.starts_with?(downcase, "int_datetime") -> :date

      true -> :none
    end
  end
end
