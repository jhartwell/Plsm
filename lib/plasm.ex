defmodule Mix.Tasks.Plasm do
    use Mix.Task
    alias Plasm.Database.MySql
    alias Plasm.Export

    def run(_) do
  
        configs = Code.eval_file("plasm.configs")
        IO.inspect configs
        {db,conn_str} = MySql.create_connection_string("localhost",3306,"root", "ashley#23","5.3","upr_api")
        case MySql.connect(conn_str) do 
            {:ok, conn} -> create_output conn, db
            {_, msg} -> IO.puts msg
        end
    end

    def create_output(conn, db) do
        tables = MySql.tables(conn, db)
        for table <- tables do
            fields = MySql.get_table_fields(conn,table)
            write_file(table,fields)
        end       
    end

    def write_file(table, fields) do
        case File.open "#{table}.ex", [:write] do
            {:ok, file} -> output = Export.output_table(table, fields); IO.binwrite(file, output)
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
        <> format_item("driver_version","5.3",",")
        <> format_item("username","username",",")
        <> format_item("password", "password")
        <> "\t\t  ]"
    end

    defp format_item(name, value, comma \\ "") do
        "\t\t\t#{name}: \"#{value}\"#{comma}\n"
    end
end