defmodule Plsm.IO.Export do
  @doc """
    Generate the schema field based on the database type
  """
  def type_output(field) do
    case field do
      {name, type, is_primary_key?} when type == :decimal ->
        four_space("field :#{name}, :decimal, :primary_key #{is_primary_key?}\n")

      {name, type, is_primary_key?} when type == :float ->
        four_space("field :#{name}, :float, :primary_key #{is_primary_key?}\n")

      {name, type, is_primary_key?} when type == :string ->
        four_space("field :#{name}, :string, :primary_key #{is_primary_key?}\n")

      {name, type, is_primary_key?} when type == :text ->
        four_space("field :#{name}, :string, :primary_key #{is_primary_key?}\n")

      {name, type, is_primary_key?} when type == :map ->
        four_space("field :#{name}, :map, :primary_key #{is_primary_key?}\n")

      {name, type, is_primary_key?} when type == :date ->
        four_space("field :#{name}, :naive_datetime, :primary_key #{is_primary_key?}\n")

      _ ->
        ""
    end
  end

  @doc """
    Write the given schema to file.
  """
  @spec write(String.t(), String.t(), String.t()) :: Any
  def write(schema, name, path \\ "") do
    case File.open("#{path}#{name}.ex", [:write]) do
      {:ok, file} ->
        IO.puts("#{path}#{name}.ex")
        IO.binwrite(file, schema)

      {_, msg} ->
        IO.puts("Could not write #{name} to file: #{msg}")
    end
  end

  @doc """
  Format the text of a specific table with the fields that are passed in. This is strictly formatting and will not verify the fields with the database
  """
  @spec prepare(Plsm.Database.Table, String.t()) :: {Plsm.Database.TableHeader, String.t()}
  def prepare(table, project_name) do
    output =
      module_declaration(project_name, table.header.name) <>
        model_inclusion() <> schema_declaration(table.header.name)

    trimmed_columns = remove_foreign_keys(table.columns)

    column_output =
      trimmed_columns
      |> Enum.reduce("", fn x, a -> a <> type_output({x.name, x.type, x.primary_key}) end)

    output = output <> column_output

    belongs_to_output =
      Enum.filter(table.columns, fn column ->
        column.foreign_table != nil and column.foreign_table != nil
      end)
      |> Enum.reduce("", fn column, a ->
        a <> belongs_to_output(project_name, column)
      end)

    output = output <> belongs_to_output <> "\n"

    output = output <> two_space(end_declaration())
    output = output <> changeset(table.columns) <> end_declaration()
    output <> end_declaration()
    {table.header, output}
  end

  defp module_declaration(project_name, table_name) do
    namespace = Plsm.Database.TableHeader.table_name(table_name)
    "defmodule #{project_name}.#{namespace} do\n"
  end

  defp model_inclusion do
    two_space("use Ecto.Schema\n" <> two_space("import Ecto.Changeset\n\n"))
  end

  defp schema_declaration(table_name) do
    two_space("schema \"#{table_name}\" do\n")
  end

  defp end_declaration do
    "end\n"
  end

  defp four_space(text) do
    "    " <> text
  end

  defp two_space(text) do
    "  " <> text
  end

  defp changeset(columns) do
    output = two_space("def changeset(struct, params \\\\ %{}) do\n")
    output = output <> four_space("struct\n")
    output = output <> four_space("|> cast(params, [" <> changeset_list(columns) <> "])\n")
    output <> two_space("end\n")
  end

  defp changeset_list(columns) do
    columns
    |> Enum.map(fn c -> ":#{c.name}" end)
    |> Enum.join(", ")
  end

  @spec prepare(String.t(), Plsm.Database.Column) :: String.t()
  defp belongs_to_output(project_name, column) do
    column_name = column.name |> String.trim_trailing("_id")
    table_name = Plsm.Database.TableHeader.table_name(column.foreign_table)
    "\n" <> four_space("belongs_to :#{column_name}, #{project_name}.#{table_name}")
  end

  defp remove_foreign_keys(columns) do
    Enum.filter(columns, fn column ->
      column.foreign_table == nil and column.foreign_field == nil
    end)
  end
end
