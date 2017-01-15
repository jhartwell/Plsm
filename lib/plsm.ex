defmodule Mix.Tasks.Plsm do
    use Mix.Task
    alias Plsm.Export
    alias Plsm.Database.Common
    def run(_) do
        {_,config_file} = Code.eval_file("Plsm.configs")
        configs = %Plsm.Common.Configs { database: config_file[:database], project: config_file[:project] }
        
        tables = configs
                |> Plsm.Database.Common.create
                |> Plsm.Database.connect
                |> Plsm.Database.get_tables
        ## TODO: Write columns to file -> pass configs into process?
        for table <- tables do
            get_columns(table.db, table)
        end
    end
end

defmodule Mix.Tasks.Plsm.Config do
use Mix.Task

    @doc "Generate the basic config file for a Plsm run"
    def run(_) do       
        case File.open("Plsm.configs", [:write]) do
            {:ok, file} -> 
                case IO.binwrite file, output_doc do
                    {:ok} -> "Created Plsm.configs"
                    _ -> "Could not create the configs. Please ensure you have write access to this folder before trying again."
                end
            {_, msg} -> IO.puts msg
        end
    end

    defp output_doc do
        output_project <> "\n\n" <> output_database
    end

    defp output_project do
        # get nice formatting for the project node
        "###################################################################################################################################################\n"
        <> "# Describes information about the project you are working on. The name will determine what the module name is for each file. Spaces will be removed\n"
        <> "###################################################################################################################################################\n\n"
        <> "project = [\n#{format_item "name", "Module name"}\t\t  ]"
    end

    defp output_database do
        "#######################################################################################################################################################\n"
        <> "# Enter the database information for the DB you're connecting to. The driver version has to correspond to the ODBC driver version for your MySQL driver\n"
        <> "#######################################################################################################################################################\n\n"
        <> "database = [\n" 
        <> format_item("server", "localhost",",")
        <> format_item("port", "3306",",")
        <> format_item("database_name", "Name of database",",")
        <> format_item("username","username",",")
        <> format_item("password", "password")
        <> "\t\t  ]"
    end

    defp format_item(name, value, comma \\ "") do
        "\t\t\t#{name}: \"#{value}\"#{comma}\n"
    end
end
defmodule Mix.Tasks.Plasm.Config do
    use Mix.Task
    def run(_) do
        Mix.Tasks.Plsm.Config.run
    end
end

defmodule Mix.Tasks.Plasm do
    use Mix.Task

    def run(_) do
        Mix.Tasks.Plsm.run
    end
end