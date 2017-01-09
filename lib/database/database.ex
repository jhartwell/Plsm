defprotocol Plasm.Database do
    def create_connection_string(db)
    def tables(db,conn)
    def table_fields(db,conn,table)
end
