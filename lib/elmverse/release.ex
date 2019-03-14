defmodule Elmverse.Release do
  @type t :: %__MODULE__{
          pub_name: String.t(),
          pkg_ver: String.t(),
          released: pos_integer(),
          repo_id: pos_integer()
        }

  defstruct [
    :pub_name,
    :pkg_ver,
    :released,
    :repo_id
  ]

  alias __MODULE__
  alias Sqlitex.Server, as: Db
  alias Elmverse.Release.Readme

  @spec fetch_readme(Release.t(), String.t()) ::
          {:ok, [Release.t()]}
          | {:error, HTTPoison.Error.t()}
          | {:error, Jason.DecodeError.t()}
  def fetch_readme(%Release{} = r, meta_url) do
    req_url = meta_url <> "/" <> r.pub_name <> "/" <> r.pkg_ver <> "/README.md"

    with {:ok, %HTTPoison.Response{status_code: 200, body: readme}} <- HTTPoison.get(req_url) do
      {:ok, %Readme{pub_name: r.pub_name, pkg_ver: r.pkg_ver, readme: readme, repo_id: r.repo_id}}
    end
  end

  @spec save(Release.t()) :: {:ok, Release.t()} | [{:error, atom()}]
  def save(%Release{} = r) do
    query = """
      INSERT INTO package_release (pub_name, pkg_ver, released, repo_id)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (pub_name, pkg_ver) DO UPDATE SET
          released = $3, repo_id = $4
    """

    with {:ok, _} <-
           Db.query(:elmverse, query,
             bind: [
               r.pub_name,
               r.pkg_ver,
               r.released,
               r.repo_id
             ]
           ) do
      {:ok, r}
    end
  end
end
