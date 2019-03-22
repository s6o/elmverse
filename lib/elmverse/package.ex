defmodule Elmverse.Package do
  @type t :: %__MODULE__{
          repo_id: pos_integer(),
          pub_name: String.t(),
          publisher: String.t(),
          pkg_name: String.t(),
          license: String.t(),
          summary: String.t(),
          latest_version: String.t()
        }

  defstruct [
    :repo_id,
    :pub_name,
    :publisher,
    :pkg_name,
    :license,
    :summary,
    :latest_version
  ]

  alias __MODULE__
  alias Sqlitex.Server, as: Db
  alias Elmverse.Release

  defimpl Collectable, for: Elmverse.Package do
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

  @spec list(atom() | pid()) :: {:ok, [Package.t()]} | {:error, any()}
  def list(db \\ :elmverse) do
    query = "SELECT * FROM package ORDER BY repo_id, pub_name"

    with {:ok, results} <- Db.query(db, query, into: %Package{}) do
      {:ok, results}
    end
  end

  @spec fetch_releases(Package.t(), String.t()) ::
          {:ok, [Release.t()]}
          | {:error, HTTPoison.Error.t()}
          | {:error, Jason.DecodeError.t()}
          | {:error, String.t()}
  def fetch_releases(%Package{} = pkg, meta_url) do
    req_url = meta_url <> "/" <> pkg.pub_name <> "/releases.json"

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(req_url),
         {:ok, rel_list} <- Jason.decode(body) do
      {:ok,
       rel_list
       |> Enum.filter(fn {ver, _} -> ver == pkg.latest_version end)
       |> Enum.map(fn {ver, epoch} ->
         %Release{
           repo_id: pkg.repo_id,
           pub_name: pkg.pub_name,
           pkg_ver: ver,
           released: epoch
         }
       end)}
    else
      {:ok, %HTTPoison.Response{} = r} ->
        {:error, "Unexpected HTTP response | #{inspect(r)}"}

      error ->
        error
    end
  end

  @spec save(Package.t(), atom() | pid()) :: {:ok, Package.t()} | {:error, any()}
  def save(%Package{} = pkg, db \\ :elmverse) do
    exists = "SELECT * FROM package WHERE repo_id = $1 AND pub_name = $2"

    insert = """
      INSERT INTO package (repo_id, pub_name, publisher, pkg_name, license, summary, latest_version)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
    """

    update = """
      UPDATE package
      SET license = $1,
          summary = $2,
          latest_version = $3
      WHERE repo_id = $4 AND pub_name = $5
    """

    with {:ok, [%Package{}]} <-
           Db.query(db, exists, bind: [pkg.repo_id, pkg.pub_name], into: %Package{}),
         {:ok, _} <-
           Db.query(db, update,
             bind: [pkg.license, pkg.summary, pkg.latest_version, pkg.repo_id, pkg.pub_name]
           ) do
      {:ok, pkg}
    else
      {:ok, _} ->
        with {:ok, _} <-
               Db.query(db, insert,
                 bind: [
                   pkg.repo_id,
                   pkg.pub_name,
                   pkg.publisher,
                   pkg.pkg_name,
                   pkg.license,
                   pkg.summary,
                   pkg.latest_version
                 ]
               ) do
          {:ok, pkg}
        end

      {:error, _} = error ->
        error
    end
  end
end
