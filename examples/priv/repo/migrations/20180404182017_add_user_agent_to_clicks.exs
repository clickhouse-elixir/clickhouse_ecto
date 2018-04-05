defmodule ExampleApp.Repo.Migrations.AddUserAgentToClicks do
  use Ecto.Migration

  def change do
    alter table(:clicks) do
      add :user_agent, :string
    end
  end
end
