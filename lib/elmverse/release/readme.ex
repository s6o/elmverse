defmodule Elmverse.Release.Readme do
  @type t :: %__MODULE__{
          pub_name: String.t(),
          pkg_ver: String.t(),
          readme: String.t(),
          repo_id: pos_integer()
        }

  defstruct [
    :pub_name,
    :pkg_ver,
    :readme,
    :repo_id
  ]

  alias __MODULE__
  alias Sqlitex.Server, as: Db

  @spec save(Readme.t()) :: {:ok, Readme.t()} | [{:error, atom()}]
  def save(%Readme{} = r) do
    query = """
      INSERT INTO release_readme (pub_name, pkg_ver, readme, repo_id)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (pub_name, pkg_ver) DO UPDATE SET
          readme = $3, repo_id = $4
    """

    with {:ok, _} <-
           Db.query(:elmverse, query,
             bind: [
               r.pub_name,
               r.pkg_ver,
               r.readme,
               r.repo_id
             ]
           ) do
      {:ok, r}
    end
  end
end
