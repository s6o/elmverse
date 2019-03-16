defmodule Elmverse.Repository do
  @type t :: %__MODULE__{
          repo_id: pos_integer(),
          repo_url: String.t(),
          meta_url: String.t(),
          elm_ver: String.t(),
          last_update: DateTime.t() | nil
        }

  defstruct [
    :repo_id,
    :repo_url,
    :meta_url,
    :elm_ver,
    :last_update
  ]

  alias __MODULE__
  alias Sqlitex.Server, as: Db
  alias Elmverse.Package

  @spec list(atom() | pid()) :: {:ok, [Repository.t()]} | [{:error, atom()}]
  def list(db \\ :elmverse) do
    query = "SELECT * FROM repository ORDER BY elm_ver DESC"

    with {:ok, results} <- Db.query(db, query) do
      {:ok,
       results
       |> Enum.map(&to_repository/1)}
    end
  end

  defp to_repository(kv_list) do
    kv_list
    |> Enum.reduce(%Repository{}, fn {k, v}, r -> Map.put(r, k, v) end)
  end

  @spec fetch_packages(Elmverse.Repository.t()) ::
          {:ok, [Package.t()]}
          | {:error, HTTPoison.Error.t()}
          | {:error, Jason.DecodeError.t()}
          | {:error, String.t()}
  def fetch_packages(%Repository{} = repo) do
    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(repo.repo_url),
         {:ok, pkg_list} <- Jason.decode(body) do
      try do
        {:ok,
         pkg_list
         |> Enum.map(fn pkg_map -> pkg_map |> to_package!(repo.repo_id) end)}
      catch
        e ->
          {:error, Kernel.inspect(e)}
      end
    end
  end

  defp to_package!(%{"license" => license, "name" => pub_name, "summary" => summary}, repo_id) do
    [publisher | [pkg_name | _]] = String.split(pub_name, "/")

    %Package{
      repo_id: repo_id,
      pub_name: pub_name,
      publisher: publisher,
      pkg_name: pkg_name,
      license: license,
      summary: summary
    }
  end

  @spec update_timestamp(Repository.t(), atom() | pid()) ::
          {:ok, Repository.t()} | [{:error, atom()}]
  def update_timestamp(%Repository{} = repo, db \\ :elmverse) do
    query = "UPDATE repository SET last_update = $1 WHERE repo_id = $2"
    ts = DateTime.utc_now() |> DateTime.to_iso8601()

    with {:ok, _} <- Db.query(db, query, bind: [ts, repo.repo_id]) do
      {:ok, %{repo | :last_update => ts}}
    end
  end
end
