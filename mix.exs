defmodule Neo4jSipsModels.Mixfile do
  use Mix.Project

  @version "0.1.1"

  def project do
    [app: :neo4j_sips_models,
     version: @version,
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     package: package,

     description: "Add Models support to the Neo4J Elixir driver",
     name: "Neo4j.Sips.Models",
     docs: [extras: ["README.md", "LICENSE"],
            source_ref: "v#{@version}",
            source_url: "https://github.com/florinpatrascu/neo4j_sips_models"]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :neo4j_sips]]
  end

  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:neo4j_sips, "~> 0.1"},
      {:timex, "~> 1.0"},
      {:inflex, "~> 1.5"},
      {:chronos, "~> 1.5"},
      {:ex_doc, "~> 0.11", only: :docs},
      {:earmark, "~> 0.2", only: :docs},
      {:inch_ex, "~> 0.5", only: :docs},
      {:meck, "~> 0.8", only: :test},
      {:mix_test_watch, "~> 0.2", only: :test}
    ]
  end

  defp package do
    %{licenses: ["MIT"],
      maintainers: ["Florin T. Patrascu"],
      links: %{"GitHub" => "https://github.com/florinpatrascu/neo4j_sips_models"}}
  end
end
