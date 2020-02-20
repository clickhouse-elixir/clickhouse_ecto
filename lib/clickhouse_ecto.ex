defmodule ClickhouseEcto do
  @moduledoc false
  @behaviour Ecto.Adapter.Storage

  use Ecto.Adapters.SQL,
    driver: :clickhousex,
    migration_lock: nil

  alias ClickhouseEcto.Migration
  alias ClickhouseEcto.Storage

  import ClickhouseEcto.Type, only: [encode: 2, decode: 2]

  def autogenerate(:binary_id), do: Ecto.UUID.generate()
  def autogenerate(type), do: super(type)

  def dumpers({:embed, _} = type, _), do: [&Ecto.Adapters.SQL.dump_embed(type, &1)]
  def dumpers(:binary_id, _type), do: []
  def dumpers(:uuid, _type), do: []
  def dumpers(ecto_type, type), do: [type, &encode(&1, ecto_type)]

  def loaders({:embed, _} = type, _), do: [&Ecto.Adapters.SQL.load_embed(type, &1)]
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
  def structure_dump(_default, _config), do: raise("not supported")
  def structure_load(_default, _config), do: raise("not supported")
end
