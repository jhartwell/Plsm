defmodule Plsm.Mixfile do
  use Mix.Project

  def project do
    [
      app: :plsm,
      version: "2.4.0",
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [applications: [:postgrex, :myxql, :exqlite]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.23.0", only: :dev, runtime: false},
      {:myxql, "~> 0.4.4"},
      {:postgrex, "~> 0.15"},
      {:exqlite, "~> 0.8.4"},
      {:ecto_sql, "~> 3.5.3", only: :test},
      {:mock, "~> 0.2.0", only: :test}
    ]
  end

  defp description do
    """
      Plsm generates Ecto models based on existing database tables and populates the fields of the model.
    """
  end

  defp package do
    [
      name: "plsm",
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Jon Hartwell"],
      licenses: ["MIT License"],
      source_url: "https://github.com/jhartwell/Plsm",
      homepage_url: "https://github.com/jhartwell/Plsm",
      links: %{"Github" => "https://github.com/jhartwell/Plsm"},
      docs: [main: "Plsm",
	     extras: ["README.md"]]
    ]
  end
end
