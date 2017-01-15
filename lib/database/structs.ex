defmodule Plsm.Database.Column do
    defstruct name: String, type: String, primary_key: false
end

defmodule Plsm.Database.Table do
    defstruct name: String, columns: [Plsm.Database.Column], db: Plsm.Database
end