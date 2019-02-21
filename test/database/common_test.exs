defmodule Plsm.Database.CommonTest do
  use ExUnit.Case

  test("list_to_sql/1 with alphanumeric input") do
    sanitized_table_names = Plsm.Database.Common.list_to_sql(["safe_table_name_1"])
    assert sanitized_table_names == ["'safe_table_name_1'"]
  end

  test("list_to_sql/1 with multiple inputs") do
    sanitized_table_names = Plsm.Database.Common.list_to_sql(["safe_1", "safe_2"])
    assert sanitized_table_names == ["'safe_1','safe_2'"]
  end

  test("list_to_sql/1 with SQLi input") do
    sanitized_table_names = Plsm.Database.Common.list_to_sql(["Robert'; DROP TABLE Students;--"])
    assert sanitized_table_names == ["'RobertDROPTABLEStudents'"]
  end
end
