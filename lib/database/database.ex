defprotocol Plsm.Database do
    
    @doc """
        Create a database struct that implements the Plsm.Database protocol.
    """
    def create(db, configs)

    @doc """
        Connect to the given database
    """
    def connect(db)

    @doc """
        Get all of the tables that are in the database that was selected
    """
    def get_tables(db)

    @doc """
        Get the columns for the table that is passed in
    """
    def get_columns(db, table)
end
