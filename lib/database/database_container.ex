defmodule Plsm.Database.Container do
    defstruct database: Plsm.Database, connection: pid()
end