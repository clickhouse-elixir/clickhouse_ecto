defmodule ClickhouseEcto.Mixfile do
  use Mix.Project

  def project do
    [
      app: :clickhouse_ecto,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
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
      {:clickhousex, path: "./../clickhousex"}
    ]
  end
end
