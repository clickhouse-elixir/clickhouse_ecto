defmodule ClickhouseEcto.Mixfile do
  use Mix.Project

  def project do
    [
      app: :clickhouse_ecto,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/appodeal/clickhouse_ecto"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:logger, :ecto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 2.1"},
      {:clickhousex, "~> 0.1.0"}
    ]
  end

  defp package do
    [
      name: "ClickhouseEcto",
      maintainers: maintainers(),
      licenses: ["Apache 2.0"],
      files: ["lib", "test", "config", "mix.exs", "README*", "LICENSE*"],
      links: %{"GitHub" => "https://github.com/appodeal/clickhouse_ecto"}
    ]
  end

  defp description do
    "ClickHouse driver for Elixir (uses ODB)."
  end

  defp maintainers do
    ["Roman Chudov", "Konstantin Grabar", "Evgeniy Shurmin", "Alexey Lukyanov"]
  end
end
