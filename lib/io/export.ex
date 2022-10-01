defmodule Plsm.IO.Export do
  @doc """
    Generate the schema field based on the database type
  """
  def type_output({name, type, is_primary_key?}, known_enums, max_name_wid, max_type_wid) do
    escaped_name    = escaped_name(name)
    {col_type,vals} = map_type(type, known_enums)

    type_output_with_source(escaped_name, name, col_type, is_primary_key?, vals, max_name_wid, max_type_wid)
    |> four_space()
  end

  defp map_type(:boolean),   do: ":boolean"
  defp map_type(:decimal),   do: ":decimal"
  defp map_type(:float),     do: ":float"
  defp map_type(:string),    do: ":string"
  defp map_type(:text),      do: ":string"
  defp map_type(:map),       do: ":map"
  defp map_type(:date),      do: ":date"
  defp map_type(:time),      do: ":time"
  defp map_type(:timestamp), do: ":naive_datetime"
  defp map_type(:integer),   do: ":integer"
  defp map_type(:uuid),      do: "Ecto.UUID"

  defp map_type(type) when is_atom(type), do: to_string(type)

  defp map_type({:none, type}, known_enums) do
    case Map.get(known_enums, type) do
      nil  -> raise RuntimeError, message: "Unknown column type: #{type}"
      vals -> {"Ecto.Enum",  Enum.map(vals, & ":"<>to_string(&1))}
    end
  end
  defp map_type(type, _known_enums), do: {map_type(type), []}

  ## When escaped name and name are the same, source option is not needed
  defp type_output_with_source(escaped_name, escaped_name, mapped_type, is_primary_key?, vals, max_name_wid, max_type_wid) do
    if is_primary_key? do
      "field :#{nm(escaped_name, max_name_wid)} #{nm(mapped_type, max_type_wid)} primary_key: true#{add_vals(vals)}\n"
    else
      "field :#{nm(escaped_name, max_name_wid)} #{nm(mapped_type, max_type_wid, false)}#{add_vals(vals)}\n"
    end
  end

  ## When escaped name and name are different, add a source option poitning to
  ## the original field name as an atom
  defp type_output_with_source(escaped_name, name, mapped_type, is_primary_key?, vals, max_name_wid, max_type_wid) do
    if is_primary_key? do
      "field :#{nm(escaped_name, max_name_wid)} #{nm(mapped_type, max_type_wid)}, primary_key: true, source: :\"#{name}\"#{add_vals(vals)}\n"
    else
      "field :#{nm(escaped_name, max_name_wid)} #{nm(mapped_type, max_type_wid, false)}, source: :\"#{name}\"#{add_vals(vals)}\n"
    end
  end

  defp nm(s, wid, add_comma \\ true) when is_binary(s), do:
    s <> (add_comma && "," || "")
      <> String.duplicate(" ", wid >= byte_size(s) && wid - byte_size(s) || byte_size(s))

  defp add_vals([]),   do: ""
  defp add_vals(vals), do: ", values: [" <> Enum.join(vals, ", ") <> "]"

  @doc "Write the given schema to file."
  @spec write(String.t(), String.t(), String.t()) :: any
  def write(schema, name, path \\ "") do
    filename  = Path.join(path, "#{name}.ex")
    exists    = File.exists?(filename)
    overwrite = case :erlang.get(:overwrite) do
                  nil -> Application.get_env(:plsm, :overwrite)
                  val -> val
                end
    ok =
      if overwrite == true or not exists do
        true
      else
        res = read_line("File #{filename} exists. Overwrite [N/y/a]: ", ["y","n","a"], "n")
        case res do
          "y" -> true
          "n" -> false
          "a" ->
            :erlang.put(:overwrite, true)
            true
        end
      end

    if ok do
      case File.open("#{path}#{name}.ex", [:write]) do
        {:ok, file} ->
          IO.puts("#{exists && "Overwriting" || "Writing"} #{filename}")
          IO.binwrite(file, schema)
          File.close(file)

        {_, msg} ->
          IO.puts("Could not write #{name} to file #{filename}: #{msg}")
      end
    else
      IO.puts("File #{filename} already exists, skipping...")
    end
  end

  @doc """
  Format the text of a specific table with the fields that are passed in. This is strictly formatting and will not verify the fields with the database
  """
  @spec prepare(Plsm.Database.Table, String.t(), %{String.t => [String.t]})
          :: {Plsm.Database.TableHeader, String.t()}
  def prepare(table, project_name, enums \\ %{}) do
    output =
      module_declaration(project_name, table.header.name) <>
        model_inclusion() <>
        primary_key_disable() <>
        schema_prefix_declaration() <>
        schema_declaration(table.header.name)

    trimmed_columns = remove_foreign_keys(table.columns)

    max_name_wid  = Enum.map(trimmed_columns, &byte_size(str(&1.name))) |> Enum.max()
    max_type_wid  = Enum.map(trimmed_columns, &byte_size(str(&1.type))) |> Enum.max()
    column_output =
      trimmed_columns
      |> Enum.reduce("", fn column, a ->
        a <> type_output({column.name, column.type, column.primary_key}, enums, max_name_wid, max_type_wid)
      end)

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
    output = output <> "\n" <> changeset(table.columns) <> end_declaration()
    output <> end_declaration()
    {table.header, output}
  end

  defp str(s) when is_binary(s), do: s
  defp str({:none,s}),           do: to_string(s)
  defp str(s),                   do: to_string(s)

  defp module_declaration(project_name, table_name) do
    namespace = Plsm.Database.TableHeader.table_name(table_name)
    "defmodule " <> to_string(project_name) <> ".#{namespace} do\n"
  end

  defp model_inclusion do
    module = Application.get_env(:plsm, :typed_schema) && "TypedEctoSchema" || "Ecto.Schema"
    two_space("use    #{module}\n" <> two_space("import Ecto.Changeset\n\n"))
  end

  defp primary_key_disable do
    two_space("@primary_key false\n")
  end

  defp schema_prefix_declaration do
    configs = Plsm.Common.Configs.load_configs()

    case configs.database.schema do
      "public" -> ""
      prefix -> two_space("@schema_prefix \"#{prefix}\"\n")
    end
  end

  defp schema_declaration(table_name) do
    pfx = Application.get_env(:plsm, :typed_schema) && "typed_" || ""
    two_space("#{pfx}schema #{inspect(table_name)} do\n")
  end

  defp end_declaration do
    "end\n"
  end

  defp space(text, n),   do: String.duplicate(" ", n) <> text
  defp four_space(text), do: "    " <> text
  defp two_space(text),  do: "  "   <> text

  defp changeset(columns) do
    output = two_space("def changeset(struct, params \\\\ %{}) do\n")
    output = output <> four_space("struct\n")
    cols   = Enum.map(columns, &":#{escaped_name(&1.name)}")
           |> wrap(80, ", ")
           |> Enum.map(&space(&1, 6))
           |> Enum.join("\n")
    output <> four_space("|> cast(params, [\n")
           <> cols <> "\n" <> four_space("])\n")
           <> two_space("end\n")
  end

  @spec belongs_to_output(String.t(), Plsm.Database.Column) :: String.t()
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

  defp escaped_name(name) do
    name
    |> String.replace(" ", "_")
  end

  defp read_line(prompt, valid, def) do
    IO.binwrite(prompt)
    res = IO.read(:stdio, :line) |> String.downcase()
    cond do
      res in valid -> res
      def != nil   -> def
      true         -> read_line(prompt, valid, def)
    end
  end

  # This is the exported function: it passes the initial
  # result set to the internal versions
  def wrap(words, margin, delim), do:
    words |> wrap([""], margin, delim) |> :lists.reverse

  def wrap([], result, _margin, _delim), do: result

  # Adding a word to an empty line
  def wrap([word], ["" | prev_lines], margin, delim), do:
    wrap([], [word | prev_lines], margin, delim)
  def wrap([word | rest], ["" | prev_lines], margin, delim), do:
    wrap(rest, [word<>delim | prev_lines], margin, delim)

  # Or to a line that's already partially full. There are two cases:
  # 1. The word fits
  def wrap([word], [curr_line | prev_lines], margin, delim)
    when byte_size(word) + byte_size(curr_line) <= margin, do:
      wrap([], ["#{curr_line}#{word}" | prev_lines], margin, delim)
  def wrap([word | rest], [curr_line | prev_lines], margin, delim)
    when byte_size(word) + byte_size(curr_line) <= margin, do:
      wrap(rest, ["#{curr_line}#{word}#{delim}" | prev_lines], margin, delim)

  # 2. The word doesn't fit, so we create a new line
  def wrap([word], [curr_line | prev_lines], margin, delim), do:
    wrap([], [word, curr_line | prev_lines], margin, delim)
  def wrap([word | rest], [curr_line | prev_lines], margin, delim), do:
    wrap(rest, [word <> delim, curr_line | prev_lines], margin, delim)
end
