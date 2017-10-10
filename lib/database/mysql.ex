defmodule Plsm.Database.MySql do
  defstruct server: "localhost", port: "3306", username: "username", password: "password", database_name: "db", connection: nil
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
    {_, conn} = Mariaex.start_link(hostname: db.server, username: db.username, port: db.port, password: db.password, database: db.database_name) 
    %Plsm.Database.MySql {
      connection: conn,
      server: db.server,
      port: db.port,
      username: db.username,
      password: db.password,
      database_name: db.database_name,
    }
  end

    # pass in a database and then get the tables using the mariaex query then turn the rows into a table
  @spec get_tables(Plsm.Database.MySql) :: [Plsm.Database.TableHeader]
  def get_tables(db) do
    {_,result} = Mariaex.query(db.connection, "SHOW TABLES")
    result.rows
      |> List.flatten
      |> Enum.map(fn(x) -> %Plsm.Database.TableHeader { database: db, name: x } end)
  end

  @spec get_columns(Plsm.Database.MySql, Plsm.Database.Table) :: [Plsm.Database.Column]
  def get_columns(db, table) do
    {_,result} = Mariaex.query(db.connection, "
      SELECT DISTINCT
        isc.COLUMN_NAME as column_name,
        MAX(isc.DATA_TYPE) as data_type,
        IF(MAX(isc.COLUMN_KEY)='PRI', 'TRUE', 'FALSE') as primary_key,
        COALESCE(MAX(REFERENCED_TABLE_NAME), '') as foreign_table,
        COALESCE(MAX(REFERENCED_COLUMN_NAME), '') as foreigh_field,
        MAX(isc.ORDINAL_POSITION) as num
      FROM INFORMATION_SCHEMA.COLUMNS isc
      LEFT JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
      ON
          isc.TABLE_NAME=kcu.TABLE_NAME
          AND isc.TABLE_SCHEMA = kcu.CONSTRAINT_SCHEMA
          AND isc.COLUMN_NAME = kcu.COLUMN_NAME
      WHERE
          isc.`TABLE_SCHEMA` ='#{db.database_name}'
          AND isc.`TABLE_NAME` = '#{table.name}'
      GROUP BY ISC.COLUMN_NAME
      ORDER BY MAX(isc.ORDINAL_POSITION)
    ")
    IO.inspect result.rows
    result.rows
      |> Enum.map(&to_column/1)
  end

  defp to_column(row) do
    {_,name} = Enum.fetch(row, 0)
    type = Enum.fetch(row, 1) |> get_type
    {_, foreign_table} = Enum.fetch(row, 3)
    {_, foreign_field} = Enum.fetch(row, 4)
    {_, is_pk} = Enum.fetch(row, 2)

    %Plsm.Database.Column{
      name: name,
      type: type,
      primary_key: is_pk,
      foreign_table: foreign_table,
      foreign_field: foreign_field
    }
  end

  defp get_type(start_type) do
    {_,type} = start_type
    upcase = String.upcase type
    cond do 
      String.starts_with?(upcase, "INT") == true -> :integer
      String.starts_with?(upcase, "BIGINT") == true -> :integer
      String.starts_with?(upcase, "TINYINT") == true -> :integer
      String.starts_with?(upcase, "BIT") == true -> :integer
      String.contains?(upcase, "CHAR") == true -> :string
      String.starts_with?(upcase, "TEXT") == true -> :string
      String.starts_with?(upcase, "FLOAT") == true -> :float
      String.starts_with?(upcase, "DOUBLE") == true -> :float
      String.starts_with?(upcase, "DECIMAL") == true -> :decimal
      String.starts_with?(upcase, "DATE") == true -> :date
      String.starts_with?(upcase, "DATETIME") == true -> :date
      String.starts_with?(upcase, "TIMESTAMP") == true -> :date
      true -> :none
    end
  end
end