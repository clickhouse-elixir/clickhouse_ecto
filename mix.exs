defmodule ClickhouseEcto.Mixfile do
  use Mix.Project

  def project do
    [
      app: :clickhouse_ecto,
      version: "0.2.8",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      description: description(),
      package: package(),
      source_url: "https://github.com/appodeal/clickhouse_ecto"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "priv/repo", "test/support"]
  defp elixirc_paths(_), do: ["lib", "priv/repo"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.4"},
      {:clickhousex,
       github: "atlas-forks/clickhousex", ref: "e010c4eaa6cb6b659e44790a3bea2ec7703ceb31"},
      {:ex_doc, "~> 0.19", only: :dev},
      {:db_connection, "~> 2.2.1", override: true},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false}
    ]
  end

  defp package do
    [
      name: "clickhouse_ecto",
      maintainers: maintainers(),
      licenses: ["Apache 2.0"],
      files: ["lib", "test", "config", "mix.exs", "README*", "LICENSE*"],
      links: %{"GitHub" => "https://github.com/appodeal/clickhouse_ecto"}
    ]
  end

  defp description do
    "Ecto adapter for ClickHouse database (uses clickhousex driver)"
  end

  defp maintainers do
    ["Roman Chudov", "Konstantin Grabar", "Evgeniy Shurmin", "Alexey Lukyanov"]
  end
end
