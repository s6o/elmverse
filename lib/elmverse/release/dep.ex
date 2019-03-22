defmodule Elmverse.Release.Dep do
  @type t :: %__MODULE__{
          repo_id: pos_integer(),
          pub_name: String.t(),
          pkg_ver: String.t(),
          dep_pub: String.t(),
          dep_guard: String.t()
        }

  defstruct [
    :repo_id,
    :pub_name,
    :pkg_ver,
    :dep_pub,
    :dep_guard
  ]

  alias __MODULE__
  alias Sqlitex.Server, as: Db

  @spec save(Dep.t(), atom() | pid()) :: {:ok, Dep.t()} | [{:error, atom()}]
  def save(%Dep{} = dep, db \\ :elmverse) do
    query = """
      INSERT INTO release_dep (repo_id, pub_name, pkg_ver, dep_pub, dep_guard)
        VALUES ($1, $2, $3, $4, $5)
    """

    with {:ok, _} <-
           Db.query(db, query,
             bind: [
               dep.repo_id,
               dep.pub_name,
               dep.pkg_ver,
               dep.dep_pub,
               dep.dep_guard
             ]
           ) do
      {:ok, dep}
    end
  end
end
