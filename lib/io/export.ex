defmodule Plsm.IO.Export do
  alias Plsm.Database.Column

  @doc """
    Generate the schema field based on the database type
  """
  def type_output(col, known_enums, max_name_wid, max_type_wid) do
    %Column{name: name, type: type, primary_key: is_pk, auto_inc: auto_inc} = col
    escaped_name = escaped_name(name)
    {col_type, vals} = map_type(type, known_enums, auto_inc)

    type_output_with_source(escaped_name, name, col_type, is_pk, vals, max_name_wid, max_type_wid)
    |> four_space()
  end

  defp map_type(:boolean, _), do: ":boolean"
  defp map_type(:decimal, _), do: ":decimal"
  defp map_type(:float, _), do: ":float"
  defp map_type(:string, _), do: ":string"
  defp map_type(:text, _), do: ":string"
  defp map_type(:map, _), do: ":map"
  defp map_type(:date, _), do: ":date"
  defp map_type(:time, _), do: ":time"
  defp map_type(:timestamp, _), do: ":naive_datetime"
  defp map_type(:integer, true), do: ":id"
  defp map_type(:integer, _), do: ":integer"
  defp map_type(:uuid, _), do: "Ecto.UUID"

  defp map_type(type, _) when is_atom(type), do: to_string(type)

  defp map_type({:none, type}, known_enums, _auto_inc) do
    case Map.get(known_enums, type) do
      nil -> raise RuntimeError, message: "Unknown column type: #{type}"
      vals -> {"Ecto.Enum", Enum.map(vals, &(":" <> to_string(&1)))}
    end
  end

  defp map_type(type, _known_enums, auto_inc), do: {map_type(type, auto_inc), []}

  ## When escaped name and name are different, add a source option poitning to
  ## the original field name as an atom
  defp type_output_with_source(
         escaped_name,
         name,
         mapped_type,
         is_primary_key?,
         vals,
         max_name_wid,
         max_type_wid
       ) do
    str = "field :#{nm(escaped_name, max_name_wid)} #{nm(mapped_type, max_type_wid, false)}"
    str = (is_primary_key? && str <> ", primary_key: #{is_primary_key?}") || str
    str = (name != escaped_name && str <> ", source: :\"#{name}\"") || str
    str <> add_vals(vals) <> "\n"
  end

  defp nm(s, wid, add_comma \\ true) when is_binary(s),
    do:
      s <>
        ((add_comma && ",") || "") <>
        String.duplicate(" ", (wid >= byte_size(s) && wid - byte_size(s)) || byte_size(s))

  defp add_vals([]), do: ""
  defp add_vals(vals), do: ", values: [" <> Enum.join(vals, ", ") <> "]"

  @doc "Write the given schema to file."
  @spec write(String.t(), String.t(), String.t()) :: any
  def write(schema, name, path \\ "") do
    filename = Path.join(path, "#{name}.ex")
    exists = File.exists?(filename)
    path != "" && (:ok = :filelib.ensure_path(path))

    overwrite =
      not exists ||
        case :erlang.get(:overwrite) do
          :undefined -> Application.get_env(:plsm, :overwrite, nil)
          val -> val
        end

    ok =
      if overwrite != nil do
        overwrite
      else
        res =
          read_line(
            "File #{filename} exists. Overwrite [(N)o / (y)es / (a)ll / (s)kip all]: ",
            ["y", "n", "a", "s"],
            "n"
          )

        case res do
          "y" ->
            true

          "n" ->
            false

          "s" ->
            :erlang.put(:overwrite, false)
            false

          "a" ->
            :erlang.put(:overwrite, true)
            true
        end
      end

    if ok do
      case File.open(filename, [:write]) do
        {:ok, file} ->
          IO.puts("#{(exists && "Overwriting") || "Writing"} #{filename}")
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
  @spec prepare(Plsm.Database.Table.t(), String.t(), %{String.t() => [String.t()]}) ::
          {Plsm.Database.TableHeader.t(), String.t()}
  def prepare(table, project_name, enums \\ %{}) do
    output = [
      module_declaration(project_name, table.header.name),
      model_inclusion(),
      primary_key_disable(),
      schema_prefix_declaration(),
      schema_declaration(table.header.name)
    ]

    trimmed_columns = remove_foreign_keys(table.columns, table.header.name)

    max_name_wid = Enum.map(trimmed_columns, &byte_size(str(&1.name))) |> Enum.max()
    max_type_wid = Enum.map(trimmed_columns, &byte_size(str(&1.type))) |> Enum.max()

    column_output =
      trimmed_columns
      |> Enum.reduce("", fn column, a ->
        a <> type_output(column, enums, max_name_wid, max_type_wid)
      end)

    belongs_to =
      table.columns
      |> Enum.filter(
        &(&1.foreign_table != nil and &1.foreign_field != nil and
            (&1.foreign_table != table.header.name or &1.foreign_field != &1.name))
      )
      |> Enum.reduce([], &[&2, belongs_to_output(project_name, &1)])

    output =
      :erlang.iolist_to_binary([
        output,
        column_output,
        belongs_to,
        (belongs_to == [] && []) || "\n",
        two_space(end_declaration()),
        "\n",
        changeset(table.columns),
        end_declaration()
      ])

    {table.header, output}
  end

  defp str(s) when is_binary(s), do: s
  defp str({:none, _}), do: "Ecto.Enum"
  defp str(s), do: to_string(s)

  defp module_declaration(project_name, table_name) do
    namespace = Plsm.Database.TableHeader.table_name(table_name)
    "defmodule " <> to_string(project_name) <> ".#{namespace} do\n"
  end

  defp model_inclusion do
    module = (Application.get_env(:plsm, :typed_schema) && "TypedEctoSchema") || "Ecto.Schema"
    two_space("use    #{module}\n" <> two_space("import Ecto.Changeset\n\n"))
  end

  defp primary_key_disable do
    two_space("@primary_key false\n")
  end

  defp schema_prefix_declaration do
    configs = Plsm.Config.load_config()

    case configs.database.schema do
      "public" -> ""
      prefix -> two_space("@schema_prefix \"#{prefix}\"\n")
    end
  end

  defp schema_declaration(table_name) do
    pfx = (Application.get_env(:plsm, :typed_schema) && "typed_") || ""
    two_space("#{pfx}schema #{inspect(table_name)} do\n")
  end

  defp end_declaration do
    "end\n"
  end

  defp space(text, n), do: String.duplicate(" ", n) <> text
  defp four_space(text), do: "    " <> text
  defp two_space(text), do: "  " <> text

  defp changeset(columns) do
    output = two_space("def changeset(struct, params \\\\ %{}) do\n")
    output = output <> four_space("struct\n")

    cols =
      Enum.map(columns, &":#{escaped_name(&1.name)}")
      |> wrap(80, ", ")
      |> Enum.map(&space(&1, 6))
      |> Enum.join("\n")

    output =
      output <>
        four_space("|> cast(params, [\n") <>
        cols <> "\n" <> four_space("])\n")

    req =
      Enum.filter(columns, fn c ->
        not c.nullable and (not (c.primary_key || false) or not (c.auto_inc || false))
      end)
      |> Enum.map(& &1.name)

    output =
      if req == [] do
        output
      else
        req =
          Enum.map(req, &":#{escaped_name(&1)}")
          |> wrap(80, ", ")
          |> Enum.map(&space(&1, 6))
          |> Enum.join("\n")

        output <>
          four_space("|> validate_required([\n") <>
          req <> "\n" <> four_space("])\n")
      end

    output <> two_space("end\n")
  end

  @spec belongs_to_output(String.t(), Plsm.Database.Column) :: String.t()
  defp belongs_to_output(proj_name, col) do
    col_name = col.name |> String.trim_trailing("_id")
    tab_name = Plsm.Database.TableHeader.table_name(col.foreign_table)

    fk_info =
      ((col.foreign_field != col.name or
          (col.foreign_field not in [nil, ""] and col.foreign_field != "id")) &&
         ", references: :" <> col.foreign_field) || ""

    ["\n", four_space("belongs_to :#{col_name}, #{proj_name}.#{tab_name}#{fk_info}")]
  end

  defp remove_foreign_keys(columns, table_name) do
    Enum.filter(columns, fn col ->
      (col.foreign_table == nil and col.foreign_field == nil) or
        (col.foreign_table == table_name && col.foreign_field == col.name)
    end)
  end

  defp escaped_name(name) do
    name
    |> String.replace(" ", "_")
  end

  defp read_line(prompt, valid, def) do
    IO.binwrite(prompt)
    res = IO.read(:stdio, :line) |> String.trim() |> String.downcase()

    cond do
      res in valid -> res
      res == "" and def != nil -> def
      true -> read_line(prompt, valid, def)
    end
  end

  @doc """
  For the given list of words wrap them to lines so that they fit the margin

  ## Example
    iex> wrap(["abc", "efg", "hij"], 8 )
  """

  @spec wrap([String.t()], integer, String.t()) :: [String.t()]
  def wrap(words, margin, delim), do: words |> wrap([""], margin, delim) |> :lists.reverse()

  def wrap([], result, _margin, _delim), do: result

  # Adding a word to an empty line
  def wrap([word], ["" | prev_lines], margin, delim),
    do: wrap([], [word | prev_lines], margin, delim)

  def wrap([word | rest], ["" | prev_lines], margin, delim),
    do: wrap(rest, [word <> delim | prev_lines], margin, delim)

  # Or to a line that's already partially full. There are two cases:
  # 1. The word fits
  def wrap([word], [curr_line | prev_lines], margin, delim)
      when byte_size(word) + byte_size(curr_line) + byte_size(delim) <= margin,
      do: wrap([], ["#{curr_line}#{word}" | prev_lines], margin, delim)

  def wrap([word | rest], [curr_line | prev_lines], margin, delim)
      when byte_size(word) + byte_size(curr_line) + byte_size(delim) <= margin,
      do: wrap(rest, ["#{curr_line}#{word}#{delim}" | prev_lines], margin, delim)

  # 2. The word doesn't fit, so we create a new line
  def wrap([word], [curr_line | prev_lines], margin, delim),
    do: wrap([], [word, curr_line | prev_lines], margin, delim)

  def wrap([word | rest], [curr_line | prev_lines], margin, delim),
    do: wrap(rest, [word <> delim, curr_line | prev_lines], margin, delim)
end
