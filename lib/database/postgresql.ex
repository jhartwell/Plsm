defmodule Plsm.Database.PostgreSQL do
  defstruct server:     "localhost",
            port:       5432,
            username:   "postgres",
            password:   "postgres",
            database:   "db",
            schema:     "public",
            connection: nil,
            app:        :postgrex
end

defimpl Plsm.Database, for: Plsm.Database.PostgreSQL do
  alias Plsm.Database.{PostgreSQL, TableHeader, Column}

  @spec connect(%PostgreSQL{}) :: Plsm.Database.t
  def connect(db) do
    {_, conn} =
      Postgrex.start_link(
        hostname: db.server,
        username: db.username,
        port:     db.port,
        password: db.password,
        database: db.database
      )

    Postgrex.query!(conn, "SET search_path TO '#{db.schema}';", [])

    struct(db, connection: conn)
  end

  # pass in a database and then get the tables using the Postgrex query then turn the rows into a table
  @spec get_tables(%PostgreSQL{}) :: [TableHeader.t]
  def get_tables(db) do
    {_, result} =
      Postgrex.query(
        db.connection,
        "SELECT table_name FROM information_schema.tables WHERE table_schema = '#{db.schema}' and table_name != 'schema_migrations';",
        []
      )

    result.rows
    |> List.flatten()
    |> Enum.map(fn x -> %TableHeader{database: db, name: x} end)
  end

  @spec get_columns(%PostgreSQL{}, TableHeader.t) :: [Column.t]
  def get_columns(db, table) do
    {_, result} = Postgrex.query(db.connection, """
      SELECT DISTINCT
        a.attname as column_name,
        UPPER(format_type(a.atttypid, a.atttypmod)) as data_type,
        coalesce(i.indisprimary,false) as primary_key,
        f.references_table as foreign_table,
        LOWER(f.references_field) as foreign_field,
        a.attnotnull as not_null,
        REGEXP_REPLACE(pg_get_expr(d.adbin, d.adrelid), '::[^)]+', '') AS def_value,
        a.attnum as num
      FROM pg_attribute a
      LEFT JOIN pg_class pgc ON pgc.oid = a.attrelid
      LEFT JOIN pg_catalog.pg_attrdef d ON (a.attrelid, a.attnum) = (d.adrelid, d.adnum)
      LEFT JOIN (
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
      AND     a.attnum   > 0
      AND pgc.relname = '#{table.name}'
      ORDER BY a.attnum
      """, [])

    result.rows
    |> Enum.map(&to_column/1)
  end

  defp to_column([name, data_type, is_pk, fk_table, fk_field, required, def, _num]) do
    {auto_inc, len, type} = get_type(data_type)

    auto_inc = auto_inc || (def && String.downcase(def) =~ "nextval(")

    %Column{
      name:          name,
      type:          type,
      nullable:      not required,
      primary_key:   is_pk,
      foreign_table: fk_table,
      foreign_field: fk_field,
      default:       def,
      auto_inc:      auto_inc,
      size:          len
    }
  end

  defp get_type(type) do
    custom_types = Application.get_env(:plsm, :custom_types, %{})

    case type do
      "BIGINT"      <> _ -> {false, nil, :integer}
      "BIGSERIAL"   <> _ -> {true,  nil, :integer}
      "BYTEA"            -> {false, nil, :string}
      "BINARY"           -> {false, nil, :string}
      "BINARY_ID"        -> {false, nil, :string}
      "BOOLEAN"     <> _ -> {false, nil, :boolean}
      "CHAR"        <> _ -> {false, len(type), :string}
      "DATE"        <> _ -> {false, nil, :date}
      "DATETIME"    <> _ -> {false, nil, :utc_timestamp}
      "DECIMAL"     <> _ -> {false, nil, :decimal}
      "DOUBLE"      <> _ -> {false, nil, :float}
      "FLOAT"       <> _ -> {false, nil, :float}
      "ID"               -> {false, nil, :integer}
      "INT"         <> _ -> {false, nil, :integer}
      "INTEGER"     <> _ -> {false, nil, :integer}
      "JSON"        <> _ -> {false, nil, :map}
      "JSONB"       <> _ -> {false, nil, :map}
      "MONEY"       <> _ -> {false, nil, :decimal}
      "NUMERIC"     <> _ -> {false, nil, :decimal}
      "REAL"        <> _ -> {false, nil, :float}
      "SERIAL"      <> _ -> {true,  nil, :integer}
      "SMALLINT"    <> _ -> {false, nil, :integer}
      "SMALLSERIAL" <> _ -> {true,  nil, :integer}
      "STRING"           -> {false, nil, :string}
      "TEXT"        <> _ -> {false, nil, :string}
      "TIME"        <> _ -> {false, nil, :time}
      "TIMESTAMP"   <> _ -> {false, nil, type =~ "WITH TIME ZONE" && :utc_datetime || :naive_datetime}
      "UUID"        <> _ -> {false, nil, :uuid}
      "XML"              -> {false, nil, :string}
      val                -> {false, nil, Map.get(custom_types, val, {:none, val})}
    end
  end

  @doc """
  Returns a map of all known custom types, each containing a list of supported values

  ## Example:
    iex> get_enums(db)
    %{
      "contract_type" => ["technical", "billing", "partner", "owner"],
      "inquiry_type"  => ["seller", "buyer"]
    }
  """
  @spec get_enums(%PostgreSQL{}) :: %{String.t => [String.t]}
  def get_enums(db) do
    {_, %{rows: rows}} =
      Postgrex.query(db.connection, "
        SELECT
          UPPER(t.typname) AS enum_name,
          e.enumlabel      AS enum_value
        FROM pg_type t
          JOIN pg_enum e ON t.oid = e.enumtypid
          JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace;
      ", [])
    Enum.group_by(rows, fn ([type, _val]) -> type end, fn ([_type, val]) -> val end)
  end

  defp len(str) do
    case Regex.run(~r/[^\d]+\((\d+)\).*/, str) do
      [_, val] -> String.to_integer(val)
      nil      -> nil
    end
  end

end
