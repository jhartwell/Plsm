defmodule Plsm.Common.Configs do

  def load_configs() do
    case File.exists?("Plsm.configs") do
      True -> load_old_method()
      False -> load_from_config_exs()
    end
  end

  defp load_from_config_exs() do
    database_config = %Plsm.Configs.Database {
                        server: Application.get_env(:plsm, :server, ""),
                        port: Application.get_env(:plsm, :port, ""),
                        database_name: Application.get_env(:plsm, :database_name, ""),
                        username: Application.get_env(:plsm, :username, ""),
                        password: Application.get_env(:plsm, :password, ""),
                        type: Application.get_env(:plsm, :type, :mysql),
                      }
    project_config =  %Plsm.Configs.Project {
                        name: Application.get_env(:plsm, :project_name, ""),
                        destination: Application.get_env(:plsm, :destination, ""),
                      }   
    %Plsm.Configs { database: database_config,  project: project_config}
  end

  defp load_old_method() do
    {_,config_file} = Code.eval_file("Plsm.configs")
    database = config_file[:database]
    database_config = %Plsm.Configs.Database {
                        server: Keyword.get(database, "server", ""),
                        port: Keyword.get(database, "port", ""),
                        database_name: Keyword.get(database, "database_name", ""),
                        username: Keyword.get(database, "username", ""),
                        password: Keyword.get(database, "password", ""),
                        type: Keyword.get(database, "type", :mysql)
                      }
    project = config_file[:project]
    project_config =  %Plsm.Configs.Project {
                        name: Keyword.get(project, "name", ""), 
                        destination: Keyword.get(project, "destination", "")
                      }                     
    %Plsm.Configs { database: database_config,  project: project_config}
  end
end