defmodule Plsm.Database.PostgreSQL do
  defstruct server: "localhost",
            port: "5432",
            username: "postgres",
            password: "postgres",
            database_name: "db",
            connection: nil
end

defimpl Plsm.Database, for: Plsm.Database.PostgreSQL do
  @spec create(Plsm.Database.PostgreSQL, Plsm.Configs) :: Plsm.Database.PostgreSQL
  def create(_db, configs) do
    %Plsm.Database.PostgreSQL{
      server: configs.database.server,
      port: configs.database.port,
      username: configs.database.username,
      password: configs.database.password,
      database_name: configs.database.database_name
    }
  end

  @spec connect(Plsm.Database.PostgreSQL) :: Plsm.Database.PostgreSQL
  def connect(db) do
    {_, conn} =
      Postgrex.start_link(
        hostname: db.server,
        username: db.username,
        port: db.port,
        password: db.password,
        database: db.database_name
      )

    %Plsm.Database.PostgreSQL{
      connection: conn,
      server: db.server,
      port: db.port,
      username: db.username,
      password: db.password,
      database_name: db.database_name
    }
  end

  # pass in a database and then get the tables using the Postgrex query then turn the rows into a table
  @spec get_tables(Plsm.Database.PostgreSQL) :: [Plsm.Database.TableHeader]
  def get_tables(db) do
    {_, result} =
      Postgrex.query(
        db.connection,
        "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';",
        []
      )

    result.rows
    |> List.flatten()
    |> Enum.map(fn x -> %Plsm.Database.TableHeader{database: db, name: x} end)
  end

  @spec get_columns(Plsm.Database.PostgreSQL, Plsm.Database.Table) :: [Plsm.Database.Column]
  def get_columns(db, table) do
    {_, result} = Postgrex.query(db.connection, "
          SELECT DISTINCT
            a.attname as column_name,
            format_type(a.atttypid, a.atttypmod) as data_type,
            coalesce(i.indisprimary,false) as primary_key,
            f.references_table as foreign_table,
            f.references_field as foreign_field,
            a.attnum as num
         FROM pg_attribute a
         JOIN pg_class pgc ON pgc.oid = a.attrelid
         left JOIN (
      	SELECT
      	tc.table_name as table,
      	kcu.column_name as field,
      	ccu.table_name AS references_table,
      	ccu.column_name AS references_field
      	FROM information_schema.table_constraints tc

      	LEFT JOIN information_schema.key_column_usage kcu
      	ON tc.constraint_catalog = kcu.constraint_catalog
      	AND tc.constraint_schema = kcu.constraint_schema
      	AND tc.constraint_name = kcu.constraint_name

      	LEFT JOIN information_schema.referential_constraints rc
      	ON tc.constraint_catalog = rc.constraint_catalog
      	AND tc.constraint_schema = rc.constraint_schema
      	AND tc.constraint_name = rc.constraint_name

      	LEFT JOIN information_schema.constraint_column_usage ccu
      	ON rc.unique_constraint_catalog = ccu.constraint_catalog
      	AND rc.unique_constraint_schema = ccu.constraint_schema
      	AND rc.unique_constraint_name = ccu.constraint_name

      	WHERE lower(tc.constraint_type) in ('foreign key')
        ) as f on a.attname = f.field
        LEFT JOIN pg_index i ON
            (pgc.oid = i.indrelid AND i.indkey[0] = a.attnum)
        WHERE a.attnum > 0 AND pgc.oid = a.attrelid
        AND pg_table_is_visible(pgc.oid)
        AND NOT a.attisdropped
        AND pgc.relname = '#{table.name}'
        ORDER BY a.attname;", [])

    result.rows
    |> Enum.map(&to_column/1)
  end

  defp to_column(row) do
    {_, name} = Enum.fetch(row, 0)
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
    {_, type} = start_type
    upcase = String.upcase(type)

    custom_types = Application.get_env(:plsm, :custom_types, %{})

    cond do
      String.starts_with?(upcase, "INTEGER") ->
        :integer

      String.starts_with?(upcase, "INT") ->
        :integer

      String.starts_with?(upcase, "SMALLINT") ->
        :integer

      String.starts_with?(upcase, "BIGINT") ->
        :integer

      String.starts_with?(upcase, "CHAR") ->
        :string

      String.starts_with?(upcase, "TEXT") ->
        :string

      String.starts_with?(upcase, "FLOAT") ->
        :float

      String.starts_with?(upcase, "DOUBLE") ->
        :float

      String.starts_with?(upcase, "DECIMAL") ->
        :decimal

      String.starts_with?(upcase, "NUMERIC") ->
        :decimal

      String.starts_with?(upcase, "JSON") ->
        :map

      String.starts_with?(upcase, "JSONB") ->
        :map

      String.starts_with?(upcase, "DATE") ->
        :date

      String.starts_with?(upcase, "DATETIME") ->
        :timestamp

      String.starts_with?(upcase, "TIMESTAMP") ->
        :timestamp

      String.starts_with?(upcase, "TIME") ->
        :time

      String.starts_with?(upcase, "BOOLEAN") ->
        :boolean

      String.starts_with?(upcase, "UUID") ->
        :uuid4

      true ->
        Map.get(custom_types, upcase, {:none, upcase})
    end
  end
end
