defmodule Plsm.Database.Common do
  @doc """
    Create a struct that implements the Plsm.Database protocol based on the type of database that is passed in
  """
  @spec create(Plsm.Common.Configs) :: Plsm.Database
  def create(configs) do
    case configs.database.type do
      :mysql ->
        IO.puts("Using MySql...")
        Plsm.Database.create(%Plsm.Database.MySql{}, configs)

      :postgres ->
        IO.puts("Using PostgreSQL...")
        Plsm.Database.create(%Plsm.Database.PostgreSQL{}, configs)

      _ ->
        IO.puts("Using default database MySql...")
        Plsm.Database.create(%Plsm.Database.MySql{}, configs)
    end
  end
end
