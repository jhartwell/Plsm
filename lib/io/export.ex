defmodule Plsm.IO.Export do
   

    @doc "Generate the schema field based on the database type"
    def type_output (field) do
        case field do
            {name, type} when type == :sql_integer or type == :sql_smallint or type == :sql_tinyint -> eight_space "field :#{name}, :integer\n"
            {name, type} when type == :sql_decimal or type == :sql_numeric -> eight_space "field :#{name}, :decimal\n"
            {name, type} when type == :sql_float -> eight_space  "field :#{name}, :float\n"
            {name, type} when type == :sql_char or type == :sql_wchar or type == :sql_varchar or type == :sql_wvarchar or type == :sql_wlongvarchar -> eight_space "field :#{name}, :string\n"
            {name,type} when type == :sql_timestamp or type == :sql_time or type == :sql_date -> eight_space "field :#{name}, :utc_datetime\n"
            {name, type} -> try_varchar name, type
        end
    end

    def write(schema, name) do
        case File.open "#{name}.ex", [:write] do
            {:ok, file} -> IO.binwrite file, schema
            _ -> IO.puts "Could not write #{name} to file"
        end
    end
    
    @spec prepare(Plsm.Database.Table, String.t) :: String.t
    @doc "Format the text of a specific table with the fields that are passed in. This is strictly formatting and will not verify the fields with the database"
    def prepare(table, project_name) do
        table.columns |> inspect |> IO.puts
        output = module_declaration(project_name) <> model_inclusion <> schema_declaration table.header.name
        column_output = ""
        for column <- table.columns do
            column_output = column_output <> type_output {column.name, column.type}
        end
        output = output <> column_output
        output = output <> four_space end_declaration
        output <> end_declaration
    end

     defp module_declaration(project_name) do
        "defmodule #{String.replace(project_name," ", "_")} do\n"
    end

    defp model_inclusion do
        four_space "use Ecto.Schema\n"
    end

    defp schema_declaration(table_name) do
        four_space "schema \"#{table_name}\" do\n"
    end

    defp end_declaration do
        "end\n"
    end

    defp four_space(text) do
        "    " <> text
    end

    defp eight_space(text) do
        "        " <> text
    end

    defp try_varchar(name, type) do
        type_name =
            case type do
                {:sql_wlongvarchar, _} when is_tuple(type)-> :varchar
                {:sql_wvarchar,_} -> :varchar
                _ -> :other
            end |> to_string
      
        is_string = String.starts_with?(type_name, "varchar") or String.starts_with?(type_name, "w_var")
        case is_string do
            true   -> eight_space "field :#{name}, :string\n"
            _ -> "# type not supported for column #{name}\n"
        end
    end
end