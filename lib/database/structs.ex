defmodule Plsm.Database.Column do
    defstruct name: String, type: :none, primary_key: false
end

defmodule Plsm.Database.Table do
    defstruct columns: [Plsm.Database.Column], header: Plsm.Database.TableHeader
end

defmodule Plsm.Database.TableHeader do
    defstruct name: String, database: nil
end