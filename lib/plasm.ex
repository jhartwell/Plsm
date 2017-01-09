defmodule Mix.Tasks.Plasm do
    use Mix.Task
    alias Plasm.Export
    alias Plasm.Database.Common
    def run(_) do
        {_,configs} = Code.eval_file("plasm.configs")
        
        project = configs[:project]
        database = configs[:database]
        database_name = database[:database_name]
        database_type = database[:type]
        db = case database_type do
                :mysql ->  IO.puts "MySql database selected";
                        %Plasm.Database.MySql{server: database[:server],
                            port: database[:port],
                            username: database[:username], 
                            password: database[:password],
                            version: database[:driver_version],
                            database_name: database_name}
                _ -> IO.puts "No database type passed in. Defaulting to MySql";
                        %Plasm.Database.MySql{server: database[:server],
                            port: database[:port],
                            username: database[:username], 
                            password: database[:password],
                            version: database[:driver_version],
                            database_name: database_name}
            end
        conn_str = Plasm.Database.create_connection_string(db)

        case Common.connect(conn_str) do
            {:ok, conn} -> create_output(conn,db,project[:name])
            {_, msg} -> IO.puts "Error: #{msg}"
        end
    end

    @doc "Top level function that starts the export process. This will call all the functions necessary to create the model output"
    def create_output(conn, db,project_name) do
        case  Plasm.Database.tables(db,conn) do
            {:ok, tables} -> iterate_tables(db, tables, conn, project_name)
            {_, msg} -> {:error, msg}
        end
    end

    @doc "Iterate on each table that is provided and create the model based on that table"
    def iterate_tables(db,tables, conn, project_name) do
        for table <- tables do
            case Plasm.Database.table_fields(db,conn,table) do
                {:ok, fields} -> write_file(table,fields, project_name)
                {_, msg} -> {:error, msg}
            end
        end       
    end

    @doc "Write the fields from the given table to an elixir source file"
    def write_file(table, fields, project_name) do
        case File.open "#{table}.ex", [:write] do
            {:ok, file} -> output = Export.output_table(table, fields, project_name); IO.binwrite(file, output)
            {_,msg} -> IO.puts msg
        end
    end
end

defmodule Mix.Tasks.Plasm.Config do
    use Mix.Task

    @doc "Generate the basic config file for a plasm run"
    def run(_) do       
        case File.open("plasm.configs", [:write]) do
            {:ok, file} -> 
                case IO.binwrite file, output_doc do
                    {:ok} -> "Created plasm.configs"
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
        <> format_item("driver_version","5.3",",")
        <> format_item("username","username",",")
        <> format_item("password", "password")
        <> "\t\t  ]"
    end

    defp format_item(name, value, comma \\ "") do
        "\t\t\t#{name}: \"#{value}\"#{comma}\n"
    end
end