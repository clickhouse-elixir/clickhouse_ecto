defmodule ExampleApp.User do
  use ExampleApp.Web, :model

  schema "clicks" do
    field :site_id, :integer
    field :source, :string
    field :ip, :string
    field :points, :decimal
    field :width, :integer
    field :height, :integer
    field :date, :date

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:site_id, :source, :ip, :points, :width, :height, :date])
    |> validate_required([:date, :site_id])
  end
end
