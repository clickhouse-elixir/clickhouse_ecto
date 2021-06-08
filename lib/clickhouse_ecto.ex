defmodule ClickhouseEcto do
  require IEx

  @moduledoc false
  @behaviour Ecto.Adapter.Storage

  use Ecto.Adapters.SQL,
    driver: :clickhousex,
    migration_lock: "FOR UPDATE"

  alias ClickhouseEcto.Migration
  alias ClickhouseEcto.Storage
  alias ClickhouseEcto.Structure

  import ClickhouseEcto.Type, only: [encode: 2, decode: 2]

  def autogenerate(:binary_id), do: Ecto.UUID.generate()
  def autogenerate(type), do: super(type)

  def dumpers({:embed, _}, type), do: [&Ecto.Type.embedded_dump(type, &1, :json)]
  def dumpers(:binary_id, _type), do: []
  def dumpers(:uuid, _type), do: []
  def dumpers(ecto_type, type), do: [type, &encode(&1, ecto_type)]

  def loaders({:embed, _}, type), do: [&Ecto.Type.embedded_load(type, &1, :json)]
  def loaders(ecto_type, type), do: [&decode(&1, ecto_type), type]

  ## Migration
  def supports_ddl_transaction?, do: Migration.supports_ddl_transaction?()

  ## Storage
  @impl Ecto.Adapter.Storage
  def storage_up(opts), do: Storage.storage_up(opts)
  @impl Ecto.Adapter.Storage
  def storage_down(opts), do: Storage.storage_down(opts)
  @impl Ecto.Adapter.Storage
  def storage_status(opts), do: Storage.storage_status(opts)

  ## Structure
  def structure_dump(default, config), do: Structure.structure_dump(default, config)
  def structure_load(default, config), do: Structure.structure_load(default, config)
end
