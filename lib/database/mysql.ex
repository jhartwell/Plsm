defmodule Plsm.Database.MySql do
  defstruct server:     "localhost",
            port:       "3306",
            username:   "username",
            password:   "password",
            database:   "db",
            connection: nil,
            app:        :myxql
end

defimpl Plsm.Database, for: Plsm.Database.MySql do
  alias Plsm.Database.{MySql, TableHeader, Column}

  @spec connect(%MySql{}) :: Plsm.Database.t
  def connect(db) do
    {_, conn} =
      MyXQL.start_link(
       protocol: :tcp,
        hostname: db.server,
        username: db.username,
        port:     db.port,
        password: db.password,
        database: db.database
      )

    struct(db, connection: conn)
  end

  # pass in a database and then get the tables using the mariaex query then turn the rows into a table
  @spec get_tables(%MySql{}) :: [TableHeader.t]
  def get_tables(db) do
    {_, result} = MyXQL.query(db.connection, "SHOW TABLES")

    result.rows
    |> List.flatten()
    |> Enum.map(fn x -> %TableHeader{database: db, name: x} end)
  end

  @spec get_columns(%MySql{}, TableHeader.t) :: [Column.t]
  def get_columns(db, table) do
    {_, result} = MyXQL.query(db.connection, "show columns from `#{table.name}`")

    result.rows
    |> Enum.map(&to_column/1)
  end

  @doc "Not implemented"
  @spec get_enums(%MySql{}) :: %{String.t => [String.t]}
  def get_enums(_db), do: %{}

  defp to_column(row) do
    {_, name} = Enum.fetch(row, 0)
    type = Enum.fetch(row, 1) |> get_type
    {_, pk} = Enum.fetch(row, 3)
    primary_key? = pk == "PRI"
    %Column{name: name, type: type, primary_key: primary_key?}
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
      String.contains?(downcase,    "char") -> :string
      String.starts_with?(downcase, "text") -> :string
      String.starts_with?(downcase, "float") -> :float
      String.starts_with?(downcase, "double") -> :float
      String.starts_with?(downcase, "decimal") -> :decimal
      String.starts_with?(downcase, "date") -> :date
      String.starts_with?(downcase, "datetime") -> :date
      String.starts_with?(downcase, "timestamp") -> :date
      String.starts_with?(downcase, "smallint") -> :integer
      true -> :none
    end
  end
end
