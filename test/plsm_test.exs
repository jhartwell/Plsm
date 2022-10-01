defmodule PlsmTest do
  use ExUnit.Case

  describe "plsm task using postgres" do
    setup do
      Application.get_env(:plsm, :destination)
      |> Path.join("*.ex")
      |> Path.wildcard()
      |> Enum.each(fn file -> File.rm!(file) end)

      :ok = :filelib.ensure_path(Application.get_env(:plsm, :destination))
    end

    test "schema files are generated and can compile" do
      Mix.Tasks.Plsm.run([])

      assert :ok == IEx.Helpers.recompile()
    end
  end
end
