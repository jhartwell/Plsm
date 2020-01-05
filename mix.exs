defmodule Plsm.Mixfile do
  use Mix.Project

  def project do
    [
      app: :plsm,
      version: "2.3.2",
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [applications: [:postgrex, :mariaex]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.21.0", only: :dev},
      {:mariaex, "~> 0.9.1"},
      {:postgrex, "~> 0.15"},
      {:ecto_sql, "~> 3.0", only: :test},
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
      name: :plsm,
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Jon Hartwell"],
      licenses: ["MIT License"],
      links: %{"GitHub" => "https://github.com/jhartwell/Plsm"}
    ]
  end
end
