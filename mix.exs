defmodule ClickhouseEcto.Mixfile do
  use Mix.Project

  def project do
    [
      app: :clickhouse_ecto,
      version: "0.2.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/appodeal/clickhouse_ecto/tree/feature/odbc"
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
      {:clickhousex_odbc, "~> 0.2.0"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp package do
    [
      name: "clickhouse_ecto_odbc",
      maintainers: maintainers(),
      licenses: ["Apache 2.0"],
      files: ["lib", "test", "config", "mix.exs", "README*", "LICENSE*"],
      links: %{"GitHub" => "https://github.com/appodeal/clickhouse_ecto/tree/feature/odbc"}
    ]
  end

  defp description do
    "ClickHouse driver for Elixir which uses ODBC driver for connection"
  end

  defp maintainers do
    ["Roman Chudov", "Konstantin Grabar", "Evgeniy Shurmin", "Alexey Lukyanov"]
  end
end
