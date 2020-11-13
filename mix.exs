defmodule ClickhouseEcto.Mixfile do
  use Mix.Project

  def project do
    [
      app: :clickhouse_ecto,
      version: "0.3.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/clickhouse-elixir/clickhouse_ecto"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:clickhousex, "~> 0.5.0"},
      {:ex_doc, "~> 0.19", only: :dev},
      {:db_connection, "~> 2.0"},
      {:credo, "~> 1.5", only: :dev},
      # {:nicene, "~> 0.4.0", only: :dev}
    ]
  end

  defp package do
    [
      name: "clickhouse_ecto",
      maintainers: maintainers(),
      licenses: ["Apache 2.0"],
      files: ["lib", "test", "config", "mix.exs", "README*", "LICENSE*"],
      links: %{"GitHub" => "https://github.com/clickhouse-elixir/clickhouse_ecto"}
    ]
  end

  defp description do
    "Ecto adapter for ClickHouse database (uses clickhousex driver)"
  end

  defp maintainers do
    ["Roman Chudov",
     "Konstantin Grabar",
     "Evgeniy Shurmin",
     "Alexey Lukyanov",
     "Yaroslav Rogov",
     "Ivan Sokolov",
     "Georgy Sychev"]
  end
end
