defmodule Elmverse.Repository.PackageSummary do
  @type t :: %__MODULE__{
          elm_ver: String.t(),
          pub_name: String.t(),
          publisher: String.t(),
          pkg_name: String.t(),
          pkg_ver: String.t(),
          released: pos_integer(),
          license: String.t(),
          summary: String.t()
        }

  defstruct [
    :elm_ver,
    :pub_name,
    :publisher,
    :pkg_name,
    :pkg_ver,
    :released,
    :license,
    :summary
  ]

  alias __MODULE__
  alias Sqlitex.Server, as: Db

  defimpl Collectable, for: Elmverse.Repository.PackageSummary do
    def into(original) do
      collector_fn = fn s, cmd ->
        case cmd do
          {:cont, {key, value}} ->
            Map.put(s, key, value)

          :done ->
            s

          :halt ->
            :ok
        end
      end

      {original, collector_fn}
    end
  end

  @spec list(String.t(), atom() | pid()) :: {:ok, [PackageSummary.t()]} | {:error, any()}
  def list(elm_ver, db \\ :elmverse) do
    query = "SELECT * FROM repository_package_summary_view WHERE elm_ver = $1"

    with {:ok, results} <- Db.query(db, query, bind: [elm_ver], into: %PackageSummary{}) do
      {:ok, results}
    end
  end
end
