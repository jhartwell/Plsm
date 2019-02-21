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

      # TBD: Remove defaults and return error message ?
      _ ->
        IO.puts("Using default database MySql...")
        Plsm.Database.create(%Plsm.Database.MySql{}, configs)
    end
  end

  @spec list_to_sql([String.t()]) :: [String.t()]
  def list_to_sql(table_names) do
    table_names
    |> Enum.map(&String.replace(&1, ~r/\W+/, "", global: true))
    |> Enum.map(&"'#{&1}'")
    |> Enum.join(",")
    |> List.wrap()
  end
end
