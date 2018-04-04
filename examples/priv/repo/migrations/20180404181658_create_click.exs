defmodule ExampleApp.Repo.Migrations.CreateClick do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:clicks, engine: "MergeTree(date,(date,inserted_at,source,site_id,ip,score,width,height),8192)") do
      add :site_id, :integer, default: 0
      add :source, :string, default: ""
      add :ip, :string, default: ""
      add :score, :float, default: 0.0
      add :width, :integer
      add :height, :integer

      add :date, :date, default: :today
      timestamps(updated_at: false)
    end
  end
end
