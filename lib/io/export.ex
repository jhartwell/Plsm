defmodule Plsm.IO.Export do
   

    @doc """
        Generate the schema field based on the database type
    """
    def type_output (field) do
        case field do
            {name, type} when type == :integer -> four_space "field :#{name}, :integer\n"
            {name, type} when type == :decimal -> four_space "field :#{name}, :decimal\n"
            {name, type} when type == :float -> four_space  "field :#{name}, :float\n"
            {name, type} when type == :string -> four_space "field :#{name}, :string\n"
            {name,type} when type == :date -> four_space "field :#{name}, :utc_datetime\n"
            _ -> ""
        end
    end

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
        output = module_declaration(project_name,table.header.name) <> model_inclusion <> primary_key_declaration(table.columns) <> schema_declaration(table.header.name)
        column_output = table.columns |> Enum.reduce("",fn(x,a) -> a <> type_output({x.name, x.type}) end)
        output = output <> column_output
        output = output <> four_space end_declaration
        output = output <> changeset table.columns
        output <> end_declaration
    end

    @spec primary_key_declaration([Plsm.Database.Column]) :: String.t
    defp primary_key_declaration(columns) do
        Enum.reduce(columns, "", fn(x,acc) -> case x.primary_key do 
            true -> acc <> two_space "@primary_key {:#{x.name}, :#{x.type}, []}\n"
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

    defp model_inclusion do
        two_space "use Ecto.Schema\n\n"
    end

    defp schema_declaration(table_name) do
        two_space "schema \"#{table_name}\" do\n"
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
        output = two_space "def changeset(struct, params \\\\ %{}) do\n"
        output = output <> four_space "struct\n"
        output = output <> four_space "|> cast(params, " <> changeset_list(columns) <> ")\n"
        output <> two_space "end\n"
    end

    defp changeset_list(columns) do
        changelist = Enum.reduce(columns,"", fn(x,acc) -> acc <> ":#{x.name}, " end)
        String.slice(changelist,0,String.length(changelist) - 2)
    end
end