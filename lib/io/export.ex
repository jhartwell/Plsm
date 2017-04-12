defmodule Plsm.IO.Export do
  @doc """
  Write the given schema to file.
  """
  @spec write(String.t, String.t, String.t) :: Any
  def write(schema, name, path \\ "") do
    case File.open "#{path}#{name}.ex", [:write] do
      {:ok, file} -> IO.binwrite file, schema
      {_, msg} -> IO.puts "Could not write #{name} to file: #{msg}"
    end
  end

  @doc """
  Format the text of a specific table with the fields that are passed in. This is strictly formatting and will not verify the fields with the database
  """
  @spec prepare(Plsm.Database.Table, String.t) :: String.t
  def prepare(table, project_name) do
    output = module_declaration(project_name,table.header.name)
    <> model_inclusion()
    <> required_columns()
    <> optional_columns(table.columns)
    <> primary_key_declaration(table.columns)
    <> schema_declaration(table.header.name)
    <> column_output(table.columns)
    <> two_space end_declaration()
    <> "\n"
    <> changeset()
    output <> end_declaration()
  end

  defp column_output(columns) do
    columns
    |> remove_default_keys()
    |> Enum.reduce("",fn(x,a) -> a <> type_output({x.name, x.type}) end)
  end

  @spec primary_key_declaration([Plsm.Database.Column]) :: String.t
  defp primary_key_declaration(columns) do
    Enum.reduce(columns, "", fn(x,acc) -> case x.primary_key do
      true ->
        # As id is a default field, don't add it as the primary_key
        acc <> if x.name == "id" do
          ""
        else
          two_space "@primary_key {:#{x.name}, :#{x.type}, []}\n"
        end
      _ -> acc
      end
    end)
  end

  defp module_declaration(project_name, table_name) do
    namespace = table_name
    |> String.split("_")
    |> Enum.map(fn x -> String.capitalize x end)
    |> Enum.reduce(fn x, acc -> acc <> x end)

    "defmodule #{project_name}.#{namespace} do\n"
  end

  def optional_columns(columns) do
    two_space "@optional_fields [" <> changeset_list(columns) <> "]\n\n"
  end

  def required_columns() do
    two_space "@required_fields []\n"
  end

  defp model_inclusion do
    two_space "use Ecto.Schema\n\n"
  end

  defp schema_declaration(table_name) do
    two_space "schema \"#{table_name}\" do\n"
  end

  defp end_declaration do
    "end\n"
  end

  defp changeset() do
    two_space "def changeset(struct, params \\\\ %{}) do\n"
    <> four_space "struct\n"
    <> four_space "|> cast(params, @required_fields ++ @optional_fields)\n"
    <> four_space "|> validate_required(params, @required_fields)\n"
    <> two_space "end\n"
  end

  defp changeset_list(columns) do
    columns
    |> remove_default_keys()
    |> Enum.reduce("",fn(x,a) -> a <> ":#{x.name}, " end)
    |> String.trim_trailing(", ")
  end

  """
  Generate the schema field based on the database type
  """
  defp type_output(field) do
    case field do
      {name, type} when type == :integer -> four_space "field :#{name}, :integer\n"
      {name, type} when type == :decimal -> four_space "field :#{name}, :decimal\n"
      {name, type} when type == :float -> four_space "field :#{name}, :float\n"
      {name, type} when type == :string -> four_space "field :#{name}, :string\n"
      {name,type} when type == :date -> four_space "field :#{name}, Ecto.DateTime\n"
      _ -> ""
    end
  end

  defp four_space(text) do
    "    " <> text
  end

  defp two_space(text) do
    "  " <> text
  end

  defp remove_default_keys(columns) do
    columns
    |> List.delete(%Plsm.Database.Column{name: "id", primary_key: true, type: :integer})
    |> List.delete(%Plsm.Database.Column{name: "created_at", primary_key: false, type: :date})
    |> List.delete(%Plsm.Database.Column{name: "updated_at", primary_key: false, type: :date})
  end
end