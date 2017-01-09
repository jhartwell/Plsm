defmodule Plasm.Database.MySql do
    defstruct server: "localhost", port: "3306", username: "username", password: "password", database_name: "db", version: "5.3"
end


defimpl Plasm.Database, for: Plasm.Database.MySql do
    
    @doc "Create the ODBC connection string for the MySql database"
    def create_connection_string(db) do
        "Driver={MySQL ODBC #{db.version} UNICODE Driver};Server=#{db.server};Port=#{db.port};Database=#{db.database_name};User=#{db.username};Password=#{db.password};Option=3;"
    end

    @doc "Get the tables from the given database"
    def tables(db, conn) do
        case tables(db,conn, "show tables from #{db.database_name}") do
            {:ok, tables} -> {:ok, tables |> Enum.map(fn(x) -> elem(x,0) |> Plasm.Common.convert_utf16_to_utf8 end) }
            {_, msg} -> {:error, msg}
        end
    end   

    @doc "Get the columns from the given table"
    def table_fields(db,conn,table) do
        case :odbc.describe_table(conn, table |> to_charlist) do
            {:ok, lst} -> {:ok, lst}
            {_, msg} -> {:error, msg}
        end
    end

    defp tables(db, conn,query) do
        erlang_formatted_query = to_char_list(query)
        case :odbc.sql_query(conn,erlang_formatted_query) do
            {_,_,rows} -> {:ok, rows}
            {_,msg} -> {:error, msg}
        end
    end
end