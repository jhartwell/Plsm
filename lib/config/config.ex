defmodule Plsm.Config.Config do
  def config?() do
    case Application.get_env(:plsm, :database) do
      nil -> false
      _ -> true
    end
  end

  def write(file_name) do
    config_exists? = File.exists?(file_name)
    case File.open(file_name, [:append]) do
      {:ok, file} -> IO.binwrite(file, output_config(config_exists?))
      _ -> {:error, "Could not open file #{file_name}. Please ensure that it exists."}
    end
  end

  defp output_config(config_exists?) do
    case config_exists? do
      true -> "\n\n"
      false -> "use Mix.Config\n\n"
    end
    |> config_header()
    |> append_next_item()
    |> project_config()
    |> append_next_item()
    |> database_config()
  end

  defp database_config(current) do
    current
    |> append_config_item_string("server", "localhost")
    |> append_next_item()
    |> append_config_item_string("port", "3306")
    |> append_next_item()
    |> append_config_item_string("database_name", "name of database")
    |> append_next_item()
    |> append_config_item_string("username", "username")
    |> append_next_item()
    |> append_config_item_string("password", "password")
    |> append_next_item()
    |> append_config_item_string("filename", "filename")
    |> append_next_item()
    |> append_config_item_atom("type", "mysql")
  end

  defp project_config(current) do
    current
    |> append_config_item_string("module_name", "module name")
    |> append_next_item()
    |> append_config_item_string("destination", "output path")
  end

  defp append_config_item_string(current, key, value) do
    current <> "#{key}: \"#{value}\""
  end

  defp append_next_item(current) do
    current <> ",\n"
  end

  defp append_config_item_atom(current, key, value) do
    current <> "#{key}: :#{value}"
  end

  defp docs() do
    """
     #  Plsm configs are used to drive the extraction process. Below are what each field means:
     #    * module_name -> This is the name of the module that the models will be placed under
     #    * destination -> The output location for the generated models
     #    * server -> this is the name of the server that you are connecting to. It can be a DNS name or an IP Address. This needs to be filled in for PostgreSQL and MySQL as there are no defaults
     #    * port -> The port that the database server is listening on. This needs to be provided for PostgreSQL and MySQL as there may not be a default for your server
     #    * database_name -> the name of the database that you are connecting to. This is required.
     #    * username -> The username that is used to connect. Make sure that there is sufficient privileges to be able to connect, query tables as well as query information schemas on the database. The schema information is used to find the index/keys on each table
     #    * password -> This is necessary for PostgreSQL and MySQL as there is no default nor is there any handling of a blank password currently.
     #    * filename -> Database file full path. This is required for SQLite
     #    * type -> This dictates which database vendor you are using. We currently support PostgreSQL, MySQL and SQLite. If no value is entered then it will default to MySQL. Do note that this is an atom and not a string
    """
  end

  defp config_header(current) do
    current <> docs() <> "\n\nconfig :plsm"
  end
end
