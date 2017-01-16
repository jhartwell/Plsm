defprotocol Plsm.Database do
    def create(db, configs)
    def connect(db)
    def get_tables(db)
    def get_columns(db, table)
end
