defmodule Plasm.Database do
    defmacro __using__(_) do
        quote do
            @doc "Connect to the database"
            def connect(conn_string,opts \\ []) do
                :odbc.start
                to_char_list(conn_string) |> :odbc.connect(opts)
            end

            @doc "Get all of the columns and their types from the database"
            def get_table_fields(conn,table ) do
                case :odbc.describe_table(conn, table |> to_charlist) do
                    {:ok, lst} -> {:ok, lst}
                    {_, msg} -> {:error, msg}
                end
            end

            @doc "Get all of the tables from the given database"
            def get_tables(conn, query) do
                erlang_formatted_query = to_char_list(query)
                case :odbc.sql_query(conn,erlang_formatted_query) do
                    {_,_,rows} -> {:ok, rows}
                    {_,msg} -> {:error, msg}
                end
                
            end

            def convert_to_utf8(raw) do
                :unicode.characters_to_binary(raw, {:utf16, :little})
            end
        end
    end
end

defmodule Plasm.Database.Adapter do
    @type server :: String.t
    @type server_port :: integer
    @type user_name :: String.t
    @type password :: String.t
    @type version :: String.t
    @type database_name :: String.t

    @callback create_connection_string(server,server_port,user_name, password,version,database_name) :: {database_name, String.t}
    @callback tables(:Ref, database_name) :: [String.t]
end

