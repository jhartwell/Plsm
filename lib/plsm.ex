defmodule Mix.Tasks.Ecto.Gen.Schema do
  use Mix.Task

  @shortdoc "Creates Ecto schemas from the existing DB repository"

  @moduledoc """
  Create Ecto schemas from the existing DB repository.

  ## Examples

    $ mix ecto.gen.schema

  ## Command line options

    * `-t|--table Table` - process this table only (multiple `-t` arguments are allowed)
    * `-h|--help`        - this help screen
  """

  @impl true
  def run(params) do
    {opts, _, errors} =
      OptionParser.parse(params,
        aliases: [t: :table, h: :help],
        strict: [table: [:string, :keep], help: :boolean]
      )

    opts[:help] && help()

    tables =
      opts
      |> Enum.filter(&(elem(&1, 0) == :table))
      |> Enum.map(&(elem(&1, 1) |> String.downcase()))

    errors != [] && raise ArgumentError, message: "Invalid command-line options"

    :ok = Mix.Task.run("app.config")

    config = Plsm.Config.load_config()

    db = Plsm.Database.Factory.create(config)

    {:ok, _started} = Application.ensure_all_started(db.app)

    db = Plsm.Database.connect(db)
    enums = Plsm.Database.get_enums(db)

    db
    |> Plsm.Database.get_tables()
    |> Enum.filter(&(tables == [] or &1.name in tables))
    |> Enum.map(fn x ->
      columns = Plsm.Database.get_columns(x.database, x)
      table = %Plsm.Database.Table{header: x, columns: columns}
      {hdr, out} = Plsm.IO.Export.prepare(table, config.project.name, enums)
      filename = singularize(hdr.name)
      Plsm.IO.Export.write(out, filename, config.project.destination)
    end)
  end

  defp singularize(filename) when is_binary(filename) do
    filename
    |> String.split("_")
    |> singularize()
    |> Enum.join("_")
  end

  defp singularize([word]), do: [Inflex.singularize(word)]
  defp singularize([first | rest]), do: [first | singularize(rest)]

  defp help() do
    IO.puts("""
    Usage: mix ecto.gen.schema Options

    Options:
    ========
      -t|--table Table    - limit scema generation to this table only
      -h|--help           - this help screen
    """)

    System.halt(1)
  end
end

defmodule Mix.Tasks.Plsm.Config do
  use Mix.Task

  @doc "Generate the basic config file for a Plsm run"
  def run(params) do
    {opts, _, _} = OptionParser.parse(params, strict: [config_file: :string])
    file_name = Keyword.get(opts, :config_file, "config/config.exs")

    case config_exists?(file_name) do
      false ->
        case Plsm.Config.write(file_name) do
          {:error, msg} -> IO.puts(msg)
          _ -> IO.puts("Config written to #{file_name}\n")
        end

      true ->
        IO.puts("Config file #{file_name} already exists, please change the current config.")
    end
  end

  defp config_exists?(filename) do
    try do
      Config.Reader.read!(filename)[:plsm] != nil
    rescue
      _ ->
        false
    end
  end
end

defmodule Mix.Tasks.Plasm.Config do
  use Mix.Task
  def run(params), do: Mix.Tasks.Plsm.Config.run(params)
end

defmodule Mix.Tasks.Plasm do
  use Mix.Task

  def run(_), do: Mix.Tasks.Ecto.Gen.Schema.run(nil)
end
