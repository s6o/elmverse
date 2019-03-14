defmodule Elmverse.Repository do
  @type t :: %__MODULE__{
          repo_id: pos_integer(),
          repo_url: String.t(),
          elm_ver: String.t(),
          last_update: DateTime.t() | nil
        }

  defstruct [
    :repo_id,
    :repo_url,
    :elm_ver,
    :last_update
  ]

  alias __MODULE__
  alias Sqlitex.Server, as: Db
  alias Elmverse.Package

  @spec list() :: {:ok, [Repository.t()]} | [{:error, atom()}]
  def list() do
    query = "SELECT * FROM package_repository ORDER BY elm_ver DESC"

    with {:ok, results} <- Db.query(:elmverse, query) do
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
         |> Enum.map(fn pkg_map -> Package.from_map!(repo.repo_id, pkg_map) end)}
      catch
        e ->
          {:error, Kernel.inspect(e)}
      end
    end
  end

  @spec update_timestamp(Repository.t()) :: {:ok, Repository.t()} | [{:error, atom()}]
  def update_timestamp(%Repository{} = repo) do
    query = "UPDATE package_repository SET last_update = $1 WHERE repo_id = $2"
    ts = DateTime.utc_now() |> DateTime.to_iso8601()

    with {:ok, _} <- Db.query(:elmverse, query, bind: [ts, repo.repo_id]) do
      {:ok, %{repo | :last_update => ts}}
    end
  end
end
