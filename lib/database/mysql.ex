defmodule Plasm.Database.MySql do
    use Plasm.Database
    @behaviour Plasm.Database.Adapter

    
    @doc "Create the connection string specific for this version of MySql. This will require the MySql ODBC driver to be installed on the computer in order to run"
    def create_connection_string(server, port \\ 3306, user_name, password,version, database_name) do
        {database_name,"Driver={MySQL ODBC #{version} UNICODE Driver};Server=#{server};Port=#{port};Database=#{database_name};User=#{user_name};Password=#{password};Option=3;"}
    end

    @doc "Get the tables from the specific database. We get a list of tuple/1 so we need to get the first element of that tuple then convert it to UTF-8 from UTF-16 in order
    to be able to actual retreive the file name. Elixir uses UTF8 strings so if we don't do the conversion that means we will have errors.'"
    def tables(conn, db_name) do
        get_tables(conn, "show tables from #{db_name}")  |> Enum.map(fn(x) -> elem(x,0) |> convert_to_utf8 end)
    end


end