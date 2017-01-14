defmodule Plsm.Database.Common do
    @doc "Connect to the database with the given connection string"
    def connect(conn_string) do
        :odbc.start
        to_char_list(conn_string) |> :odbc.connect([])
    end
end