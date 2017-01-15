defmodule Plasm.Database.MySql do
    defstruct server: "localhost", port: "3306", username: "username", password: "password", database_name: "db", connection: nil
end


defimpl Plsm.Database, for: Plsm.Database.MySql do
    
    @spec create(Plsm.Database.MySql, Plsm.Common.Configs) :: Plsm.Database.MySql
    def create(db, configs) do
         %Plsm.Database.MySql{
            server: configs.database[:server],
            port: configs.database[:port],
            username: configs.database[:username],
            password: configs.database[:password],
            database_name: configs.database[:database_name]
        }     
    end

    @spec connect(Plsm.Database.MySql) :: Plsm.Database.MySql
    def connect(db) do
        {_, conn} = Mariaex.start_link(username: db.username, port: db.port, password: db.password, database: db.database_name) 
        db.connection = conn
        db
    end

    # pass in a database and then get the tables using the mariaex query then turn the rows into a table
    @spec get_tables(Plsm.Database.MySql) :: [Plsm.Database.Table]
    def get_tables(db) do
        {_,_,_,rows} = Mariaex.query(db.connection, "SHOW TABLES")
        Enum.unzip(rows) 
        |> Enum.map(fn(x) -> %Plsm.Database.Table { database: db, name: elem(x,1) } end)
    end

    @spec get_columns(Plsm.Database.Table) :: [Plsm.Database.Column]
    # Row: Field, Type, Null, Key, Default, Extra
    #        0     1     2     3      4       5   
    def get_columns(table) do
        {_,_,_,rows} = Mariaex.query(db.connection, "show columns from #{table.name}")
        Enum.unzip(rows)
        |> Enum.map(fn(x) -> %Plsm.Database.Column {name: elem(x,0), type: elem(x,1), primary_key: String.upcase(elem(x,3)) == "PRI"} end)
    end

end