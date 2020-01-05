defmodule PlsmTest do
  use ExUnit.Case

  @schema_dir "lib/test_temp/schemas/"

  describe "plsm task using postgres" do
    setup do
      Application.put_env(:plsm, :server, "localhost")
      Application.put_env(:plsm, :port, "5432")
      Application.put_env(:plsm, :database_name, "postgres")
      Application.put_env(:plsm, :username, "postgres")
      Application.put_env(:plsm, :password, "postgres")
      Application.put_env(:plsm, :type, :postgres)
      Application.put_env(:plsm, :module_name, "PlsmTest")
      Application.put_env(:plsm, :destination, @schema_dir)

      File.ls!("#{@schema_dir}")
      |> Enum.filter(!(&String.starts_with(&1, ".")))
      |> Enum.each(fn file -> File.rm!(file) end)

      :ok
    end

    test "schema files are generated and can compile" do
      Mix.Tasks.Plsm.run([])

      assert :ok == IEx.Helpers.recompile()
    end
  end
end
