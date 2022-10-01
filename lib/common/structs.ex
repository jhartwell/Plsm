defmodule Plsm.Configs do
  defstruct database: Plsm.Configs.Database, project: Plsm.Configs.Project
end

defmodule Plsm.Configs.Database do
  defstruct server: "",
            port: "",
            database_name: "",
            username: "",
            password: "",
            type: :mysql,
            schema: "",
            typed_schema: false,
            overwrite: false
end

defmodule Plsm.Configs.Project do
  defstruct name: "", destination: ""
end
