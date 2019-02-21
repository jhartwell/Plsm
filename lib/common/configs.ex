defmodule Plsm.Common.Configs do
  def load() do
    load_from_config_exs()
  end

  defp load_from_config_exs() do
    database_config = %Plsm.Configs.Database{
      server: Application.get_env(:plsm, :server, "localhost"),
      port: Application.get_env(:plsm, :port, "5432"),
      database_name: Application.get_env(:plsm, :database_name, "db"),
      username: Application.get_env(:plsm, :username, "postgres"),
      password: Application.get_env(:plsm, :password, "postgres"),
      type: Application.get_env(:plsm, :type, :postgres)
    }

    project_config = %Plsm.Configs.Project{
      name: Application.get_env(:plsm, :module_name, "Default"),
      destination: Application.get_env(:plsm, :destination, File.cwd!()),
      table_filters: load_table_filters(Application.get_env(:plsm, :table_filters, %{}))
    }

    %Plsm.Configs{database: database_config, project: project_config}
  end

  defp load_table_filters(table_filters) do
    case table_filters do
      %{include: file_name, exclude: _ex_file_name} ->
        %{include: table_file_to_list(file_name)}

      %{include: file_name} ->
        %{include: table_file_to_list(file_name)}

      %{exclude: file_name} ->
        %{exclude: table_file_to_list(file_name)}

      _ ->
        %{}
    end
  end

  defp table_file_to_list(filename) do
    filename
    |> File.read!()
    |> String.split("\n", trim: true)
  end
end
