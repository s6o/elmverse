defmodule Elmverse.Release.Readme do
  @type t :: %__MODULE__{
          repo_id: pos_integer(),
          rel_id: pos_integer(),
          pub_name: String.t(),
          pkg_ver: String.t(),
          readme: String.t()
        }

  defstruct [
    :repo_id,
    :rel_id,
    :pub_name,
    :pkg_ver,
    :readme
  ]

  alias __MODULE__
  alias Sqlitex.Server, as: Db

  @spec save(Readme.t(), atom() | pid()) :: {:ok, Readme.t()} | [{:error, atom()}]
  def save(%Readme{} = r, db \\ :elmverse) do
    query = """
      INSERT INTO release_readme (repo_id, rel_id, pub_name, pkg_ver, readme)
        VALUES ($1, $2, $3, $4, $5)
    """

    with {:ok, _} <-
           Db.query(db, query,
             bind: [
               r.repo_id,
               r.rel_id,
               r.pub_name,
               r.pkg_ver,
               r.readme
             ]
           ) do
      {:ok, r}
    end
  end
end
