defmodule Plsm.Database.Column do
  defstruct name: nil, type: :none, primary_key: false, foreign_table: nil, foreign_field: nil, db_type: nil
end

defmodule Plsm.Database.Table do
  defstruct columns: [Plsm.Database.Column], header: Plsm.Database.TableHeader
end

defmodule Plsm.Database.TableHeader do
  defstruct name: String, database: nil

  def table_name(table_name) do
    table_name
    |> String.split("_")
    |> Enum.map(fn x -> String.capitalize(x) end)
    |> Enum.reduce(fn x, acc -> acc <> x end)
  end
end
