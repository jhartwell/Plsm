defmodule Plsm.IO.Export do
   

    @doc "Generate the schema field based on the database type"
    def type_output (field) do
        case field do
            {name, type} when type == :integer -> eight_space "field :#{name}, :integer\n"
            {name, type} when type == :decimal -> eight_space "field :#{name}, :decimal\n"
            {name, type} when type == :float -> eight_space  "field :#{name}, :float\n"
            {name, type} when type == :string -> eight_space "field :#{name}, :string\n"
            {name,type} when type == :date -> eight_space "field :#{name}, :utc_datetime\n"
            _ -> ""
        end
    end

    def write(schema, name, path \\ "") do
        case File.open "#{path}#{name}.ex", [:write] do
            {:ok, file} -> IO.binwrite file, schema
            _ -> IO.puts "Could not write #{name} to file"
        end
    end
    
    @spec prepare(Plsm.Database.Table, String.t) :: String.t
    @doc "Format the text of a specific table with the fields that are passed in. This is strictly formatting and will not verify the fields with the database"
    def prepare(table, project_name) do
        output = module_declaration(project_name) <> model_inclusion <> primary_key_declaration(table.columns) <> schema_declaration(table.header.name)
        column_output = table.columns |> Enum.reduce("",fn(x,a) -> a <> type_output({x.name, x.type}) end)
        output = output <> column_output
        output = output <> four_space end_declaration
        output <> end_declaration
    end

    @spec primary_key_declaration([Plsm.Database.Column]) :: String.t
    defp primary_key_declaration(columns) do
        Enum.reduce(columns, "", fn(x,acc) -> case x.primary_key do 
            true -> acc <> four_space "@primary_key {:#{x.name}, :#{x.type}, []}\n"
            _ -> acc
            end
         end)
    end

    defp module_declaration(project_name) do
        "defmodule #{project_name} do\n"
    end

    defp model_inclusion do
        four_space "use Ecto.Schema\n\n"
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
end