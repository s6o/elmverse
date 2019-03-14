defmodule Elmverse.Package do
  @type t :: %__MODULE__{
          pub_name: String.t(),
          repo_id: pos_integer(),
          publisher: String.t(),
          pkg_name: String.t(),
          license: String.t(),
          summary: String.t()
        }

  defstruct [
    :pub_name,
    :repo_id,
    :publisher,
    :pkg_name,
    :license,
    :summary
  ]

  alias __MODULE__
  alias Sqlitex.Server, as: Db
  alias Elmverse.Release

  @spec fetch_releases(Package.t(), String.t()) ::
          {:ok, [Release.t()]}
          | {:error, HTTPoison.Error.t()}
          | {:error, Jason.DecodeError.t()}
  def fetch_releases(%Package{} = pkg, meta_url) do
    req_url = meta_url <> "/" <> pkg.pub_name <> "/releases.json"

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(req_url),
         {:ok, rel_list} <- Jason.decode(body) do
      {:ok,
       rel_list
       |> Enum.map(fn {ver, epoch} ->
         %Release{pub_name: pkg.pub_name, pkg_ver: ver, released: epoch, repo_id: pkg.repo_id}
       end)}
    end
  end

  @spec save(Package.t()) :: {:ok, Package.t()} | [{:error, atom()}]
  def save(%Package{} = pkg) do
    query = """
      INSERT INTO package (pub_name, repo_id, publisher, pkg_name, license, summary)
        VALUES ($1, $2, $3, $4, $5, $6)
        ON CONFLICT (pub_name, repo_id) DO UPDATE SET
          license = $5, summary = $6
    """

    with {:ok, _} <-
           Db.query(:elmverse, query,
             bind: [
               pkg.pub_name,
               pkg.repo_id,
               pkg.publisher,
               pkg.pkg_name,
               pkg.license,
               pkg.summary
             ]
           ) do
      {:ok, pkg}
    end
  end
end
