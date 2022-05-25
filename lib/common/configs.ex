defmodule Plsm.Common.Configs do
  def load_configs() do
    load_from_config_exs()
  end

  defp load_from_config_exs() do
    database_config = %Plsm.Configs.Database{
      server: Application.get_env(:plsm, :server, ""),
      port: Application.get_env(:plsm, :port, ""),
      database_name: Application.get_env(:plsm, :database_name, ""),
      username: Application.get_env(:plsm, :username, ""),
      password: Application.get_env(:plsm, :password, ""),
      type: Application.get_env(:plsm, :type, :mysql),
      schema: Application.get_env(:plsm, :schema, "public")
    }

    project_config = %Plsm.Configs.Project{
      name: Application.get_env(:plsm, :module_name, "Default"),
      destination: Application.get_env(:plsm, :destination, "")
    }

    %Plsm.Configs{database: database_config, project: project_config}
  end
end
