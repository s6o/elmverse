defmodule Elmverse.Package do
  @type t :: %__MODULE__{
          pkg_id: pos_integer(),
          repo_id: pos_integer(),
          pub_name: String.t(),
          publisher: String.t(),
          pkg_name: String.t(),
          license: String.t(),
          summary: String.t()
        }

  defstruct [
    :pkg_id,
    :repo_id,
    :pub_name,
    :publisher,
    :pkg_name,
    :license,
    :summary
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

  @spec list(atom() | pid()) :: {:ok, Package.t()} | {:error, any()}
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
  def fetch_releases(%Package{} = pkg, meta_url) do
    req_url = meta_url <> "/" <> pkg.pub_name <> "/releases.json"

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(req_url),
         {:ok, rel_list} <- Jason.decode(body) do
      {:ok,
       rel_list
       |> Enum.map(fn {ver, epoch} ->
         %Release{
           repo_id: pkg.repo_id,
           pkg_id: pkg.pkg_id,
           pub_name: pkg.pub_name,
           pkg_ver: ver,
           released: epoch
         }
       end)}
    end
  end

  @spec releases(Package.t(), atom() | pid()) :: {:ok, [Release.t()]} | {:error, any()}
  def releases(%Package{} = p, db \\ :elmverse) do
    query = "SELECT * FROM package_release WHERE pkg_id = $1 ORDER BY released"

    with {:ok, results} <- Db.query(db, query, into: %Release{}, bind: [p.pkg_id]) do
      {:ok, results}
    end
  end

  @spec save(Package.t(), atom() | pid()) :: {:ok, Package.t()} | {:error, any()}
  def save(%Package{} = pkg, db \\ :elmverse) do
    query = """
      INSERT INTO package (repo_id, pub_name, publisher, pkg_name, license, summary)
        VALUES ($1, $2, $3, $4, $5, $6)
    """

    with {:ok, _} <-
           Db.query(db, query,
             bind: [
               pkg.repo_id,
               pkg.pub_name,
               pkg.publisher,
               pkg.pkg_name,
               pkg.license,
               pkg.summary
             ]
           ),
         {:ok, [%{:pkg_id => pkg_id}]} <-
           Db.query(db, "SELECT last_insert_rowid() as pkg_id", into: %{}) do
      {:ok, Map.put(pkg, :pkg_id, pkg_id)}
    end
  end
end
