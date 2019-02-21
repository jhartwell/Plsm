defmodule Plsm.Common.ConfigsTest do
  use ExUnit.Case
  alias Plsm.Common

  test "load returns defaults" do
    Application.delete_env(:plsm, :table_filters)

    %Plsm.Configs{database: database_config, project: project_config} = Common.Configs.load()

    assert %Plsm.Configs.Database{} = database_config
    assert %Plsm.Configs.Project{} = project_config

    assert database_config.server == "localhost"
    assert database_config.port == "5432"
    assert database_config.username == "postgres"
    assert database_config.password == "postgres"
    assert database_config.database_name == "db"
    assert project_config.name == "Default"
    assert project_config.table_filters == %{}
    assert Regex.match?(~r/#{System.user_home()}.*plsm/i, project_config.destination)
  end

  test "load using a table whitelist or blacklist " do
    Application.put_env(:plsm, :table_filters, %{include: "test/support/whitelist.txt"})

    %Plsm.Configs{database: _database_config, project: project_config} = Common.Configs.load()

    %{include: list} = project_config.table_filters

    assert is_list(list)

    Application.put_env(:plsm, :table_filters, %{exclude: "test/support/blacklist.txt"})

    %Plsm.Configs{database: _database_config, project: project_config} = Common.Configs.load()

    %{exclude: list} = project_config.table_filters

    assert is_list(list)
  end

  test "load with both a whitelist and blacklist respects only whitelist" do
    Application.put_env(:plsm, :table_filters, %{
      include: "test/support/whitelist.txt",
      exclude: "test/support/blacklist.txt"
    })

    %Plsm.Configs{database: _database_config, project: project_config} = Common.Configs.load()

    assert [:include] = Map.keys(project_config.table_filters)
  end
end
