defmodule Plasm.Export do
    @doc "Create the module for this model"
    def module_declaration(project_name \\ "Project") do
        "defmodule #{project_name} do\n"
    end

    @doc "Use the Ecto Schema"
    def model_inclusion do
        four_space "use Ecto.Schema\n"
    end

    @doc "Create a schema text based on the table name"
    def schema_declaration(table_name) do
        four_space "schema \"#{table_name}\" do\n"
    end

    @doc "Helper method to generate an end declaration"
    defp end_declaration do
        "end\n"
    end

    @doc "Helper method to generate 4 spaces"
    defp four_space(text) do
        "    " <> text
    end

    @doc "Helper method to generate 8 spaces"
    defp eight_space(text) do
        "        " <> text
    end

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

    defp try_varchar(name, type) do
        type_name =
            case type do
                {:sql_wlongvarchar, _} when is_tuple(type)-> :varchar
                {:sql_wvarchar,_} -> :varchar
                t -> :other
            end |> to_string
      
        is_string = String.starts_with?(type_name, "varchar") or String.starts_with?(type_name, "w_var")
        case is_string do
            true   -> eight_space "field :#{name}, :string\n"
            _ -> "# type not supported for column #{name}\n"
        end
    end
    @doc "Format the text of a specific table with the fields that are passed in. This is strictly formatting and will not verify the fields with the database"
    def output_table(table,fields) do
        output = module_declaration <> model_inclusion <> schema_declaration table
        
        field_output = Enum.reduce(fields, "", fn(x,acc) -> acc <> type_output x end) 
        output = output <> field_output
        output = output <> four_space end_declaration
        output <> end_declaration
    end

    
end