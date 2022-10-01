defmodule Plsm.Config.Project do
  defstruct name: "", destination: ""

  @type t :: %__MODULE__{name: String.t, destination: String.t}
end

defmodule Plsm.Config do
  defstruct database: nil,
            project:  nil

  @type t :: %__MODULE__{
    database: Plsm.Database.t,
    project:  Plsm.Configs.Project.t
  }

  def load_config() do
    database_config = %Plsm.Database{
      server:        Application.get_env(:plsm, :server, ""),
      port:          Application.get_env(:plsm, :port, ""),
      database:      Application.get_env(:plsm, :database,
                     Application.get_env(:plsm, :database_name, "")),
      username:      Application.get_env(:plsm, :username, ""),
      password:      Application.get_env(:plsm, :password, ""),
      type:          Application.get_env(:plsm, :type, :mysql),
      schema:        Application.get_env(:plsm, :schema, "public"),
      typed_schema:  Application.get_env(:plsm, :typed_schema, false),
      overwrite:     Application.get_env(:plsm, :overwrite, false),
    }

    project_config = %Plsm.Config.Project{
      name:          Application.get_env(:plsm, :module_name, "Default"),
      destination:   Application.get_env(:plsm, :destination, "")
    }

    %__MODULE__{database: database_config, project: project_config}
  end

  def config?() do
    case Application.get_env(:plsm, :database) do
      nil -> Application.get_env(:plsm, :database_name, false)
      _   -> true
    end
  end

  def write(filename) do
    config_exists? = File.exists?(filename)

    case File.open(filename, [:append]) do
      {:ok, file} -> IO.binwrite(file, output_config(config_exists?))
      _ -> {:error, "Could not open file #{filename}. Please ensure that it exists."}
    end
  end

  defp output_config(config_exists?) do
    case config_exists? do
      true  -> "\n"
      false -> "import Config\n\n"
    end <> """
    #  Plsm configs are used to drive the extraction process. Below are what each field means:
    #    * module_name  -> This is the name of the module that the models will be placed under.
    #    * destination  -> The output location for the generated models.
    #    * server       -> this is the name of the server that you are connecting to. It can be
    #                      a DNS name or an IP Address. This needs to be filled in as there are
    #                      no defaults.
    #    * port         -> The port that the database server is listening on. This needs to be
    #                      provided as there may not be a default for your server.
    #    * database     -> the name of the database that you are connecting to. This is required.
    #    * username     -> The username that is used to connect. Make sure that there is
    #                      sufficient privileges to be able to connect, query tables as well as
    #                      query information schemas on the database. The schema information is
    #                      used to find the index/keys on each table.
    #    * password     -> This is necessary as there is no default nor is there any handling
    #                      of a blank password currently.
    #    * type         -> This dictates which database vendor you are using. We currently
    #                      support PostgreSQL and MySQL. If no value is entered then it will
    #                      default to MySQL. Do note that this is an atom and not a string.
    #    * schema       -> The database schema namespace for the target tables.
    #    * typed_schema -> If true will use 'TypedEctoSchema' from the 'typed_ecto_schema' project.
    #    * overwrite    -> If true files will be overwritten, otherwise the user is prompted for
    #                      action.
    config :plsm,
      module_name:  "module name",
      destinatoin:  "output path",
      server:       "localhost",
      port:         5432,
      database:     "db name",
      username:     "postgres",
      password:     "postgres",
      type:         :postgres,
      schema:       "public",
      typed_schema: true,
      overwrite:    false
    """
  end
end
