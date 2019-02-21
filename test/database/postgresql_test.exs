defmodule Plsm.Database.PostgreSQLTest do
  use ExUnit.Case

  test("create/2") do
    Protocol.assert_impl!(Plsm.Database, Plsm.Database.PostgreSQL)
  end

  test "get_tables/2 with whitelist" do
    table_filters = %{
      include: [
        "test_whitelisted_table_name_1",
        "test_whitelisted_table_name_2",
        "test_whitelisted_table_name_3",
        "test_whitelisted_table_name_4"
      ]
    }

    results =
      Plsm.Database.connect(%Plsm.Database.PostgreSQL{})
      |> Plsm.Database.get_tables(table_filters)

    assert Enum.all?(results, fn res ->
             res = %Plsm.Database.TableHeader{
               database: %Plsm.Database.PostgreSQL{},
               name: res.name
             }

             res.name in table_filters.include
           end)
  end
end
