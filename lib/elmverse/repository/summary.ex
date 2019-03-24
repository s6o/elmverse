defmodule Elmverse.Repository.Summary do
  @type t :: %__MODULE__{
          repo_id: pos_integer(),
          elm_ver: String.t(),
          core_pub: String.t(),
          pkg_count: pos_integer(),
          last_update: DateTime.t() | nil
        }

  defstruct [
    :repo_id,
    :elm_ver,
    :core_pub,
    :pkg_count,
    :last_update
  ]

  alias __MODULE__
  alias Sqlitex.Server, as: Db

  defimpl Collectable, for: Elmverse.Repository.Summary do
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

  @spec list(atom() | pid()) :: {:ok, [Summary.t()]} | {:error, any()}
  def list(db \\ :elmverse) do
    query = "SELECT * FROM repository_summary_view ORDER BY elm_ver DESC"

    with {:ok, results} <- Db.query(db, query, into: %Summary{}) do
      {:ok, results}
    end
  end
end
