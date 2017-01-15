defmodule Plasm.Mixfile do
  use Mix.Project

  def project do
    [app: :plasm,
     version: "0.2.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    []
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:mariaex, "~> 0.7.3"} 
    ]
  end

  defp description do
    """
      Plasm generates Ecto models based on existing database tables and populates the fields of the model.
    """
  end

  defp package do
    [
     name: :plasm_ecto,
     files: ["lib","mix.exs", "README.md", "LICENSE"],
     maintainers: ["Jon Hartwell"],
     licenses: ["MIT License"],
     links: %{"GitHub" => "https://github.com/jhartwell/Plasm"}
    ]
  end
end
