defmodule Plsm.Database.Common do
    @spec create(Plsm.Common.Configs) :: Plsm.Database
    def create(configs) do
       case configs.database[:type] do
        :mysql -> IO.puts "Using MySql..."; Plsm.Database.create Plsm.Database.MySql, configs  
        _ -> IO.puts "Using default database MySql..."; Plsm.Database.create Plsm.Database.MySql, configs  
       end 
    end
end