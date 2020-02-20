defmodule ClickhouseEcto.IntegrationTest do
  defmodule TestRepo do
    use Ecto.Repo,
      otp_app: :clickhouse_ecto,
      adapter: ClickhouseEcto

    @db_name "test_db"
    def table_up(name) do
      create_statement = """
      CREATE TABLE #{name} (
        u64_val UInt64,
        u32_val UInt32,
        u16_val UInt16,
        u8_val  UInt8,

        i64_val Int64,
        i32_val Int32,
        i16_val Int16,
        i8_val  Int8,

        f64_val Float64,
        f32_val Float32,

        string_val String,
        fixed_string_val FixedString(5),

        date_val Date,
        date_time_val DateTime
      )

      ENGINE = Memory
      """

      __MODULE__.query!(create_statement)
    end

    def db_name, do: @db_name
  end

  defmodule TestSchema do
    use Ecto.Schema
    import Ecto.Changeset

    @table_name "test_table"
    @schema_prefix TestRepo.db_name()

    schema @table_name do
      field(:u64_val, :integer)
      field(:u32_val, :integer)
      field(:u16_val, :integer)
      field(:u8_val, :integer)

      field(:i64_val, :integer)
      field(:i32_val, :integer)
      field(:i16_val, :integer)
      field(:i8_val, :integer)

      field(:f64_val, :float)
      field(:f32_val, :float)

      field(:string_val, :string)
      field(:fixed_string_val, :string)

      field(:date_val, :date)
      field(:date_time_val, :naive_datetime)
    end

    @fields [
      :u64_val,
      :u32_val,
      :u16_val,
      :u8_val,
      :i64_val,
      :i32_val,
      :i16_val,
      :i8_val,
      :f64_val,
      :f32_val,
      :string_val,
      :fixed_string_val,
      :date_val,
      :date_time_val
    ]
    def changeset(data \\ %__MODULE__{}, attrs) do
      data
      |> cast(attrs, @fields)
    end

    def table_name, do: @table_name
  end

  use ExUnit.Case

  setup_all do
    setup_database()

    Application.put_env(:clickhouse_ecto, TestRepo, pool: Ecto.Adapters.SQL.Sandbox)

    {:ok, _pid} = TestRepo.start_link([])
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(TestRepo, {:shared, self()})
    TestRepo.table_up(TestRepo.db_name() <> "." <> TestSchema.table_name())
    :ok
  end

  test "insert" do
    assert {:ok, entry} =
             %{
               u64_val: 10,
               u32_val: 10,
               u16_val: 10,
               u8_val: 10,
               i64_val: 10,
               i32_val: 10,
               i16_val: 10,
               i8_val: 10,
               f64_val: 1.2,
               f32_val: 1.2,
               string_val: "test string",
               fixed_string_val: "1234",
               date_val: Date.utc_today(),
               date_time_val: NaiveDateTime.utc_now()
             }
             |> TestSchema.changeset()
             |> TestRepo.insert()
  end

  defp setup_database do
    on_exit(fn ->
      {:ok, client} = Clickhousex.start_link([])
      Clickhousex.query!(client, "DROP DATABASE IF EXISTS #{TestRepo.db_name()}", [])
    end)

    {:ok, client} = Clickhousex.start_link([])
    Clickhousex.query!(client, "CREATE DATABASE IF NOT EXISTS #{TestRepo.db_name()}", [])
  end
end
