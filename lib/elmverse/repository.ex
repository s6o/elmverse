defmodule Elmverse.Repository do
  @type t :: %__MODULE__{
          repo_id: pos_integer(),
          repo_url: String.t(),
          meta_url: String.t(),
          elm_ver: String.t(),
          core_pub: String.t(),
          last_update: DateTime.t() | nil
        }

  defstruct [
    :repo_id,
    :repo_url,
    :meta_url,
    :elm_ver,
    :core_pub,
    :last_update
  ]

  alias __MODULE__
  alias Sqlitex.Server, as: Db
  alias Elmverse.Package

  defimpl Collectable, for: Elmverse.Repository do
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

  @spec list(atom() | pid()) :: {:ok, [Repository.t()]} | {:error, any()}
  def list(db \\ :elmverse) do
    query = "SELECT * FROM repository ORDER BY elm_ver"

    with {:ok, results} <- Db.query(db, query, into: %Repository{}) do
      {:ok, results}
    end
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
    else
      {:ok, %HTTPoison.Response{} = r} ->
        {:error, "Unexpected HTTP response | #{inspect(r)}"}

      error ->
        error
    end
  end

  defp to_package!(
         %{"name" => pub_name, "summary" => summary, "versions" => versions} = item,
         repo_id
       ) do
    [publisher | [pkg_name | _]] = String.split(pub_name, "/")
    license = Map.get(item, "license", nil)

    latest_version =
      versions
      |> Enum.sort(&(&1 >= &2))
      |> (fn [lv | _] -> lv end).()

    %Package{
      repo_id: repo_id,
      pub_name: pub_name,
      publisher: publisher,
      pkg_name: pkg_name,
      license: license,
      summary: summary,
      latest_version: latest_version
    }
  end

  @spec packages(Repository.t(), atom() | pid()) :: {:ok, [Package.t()]} | {:error, any()}
  def packages(%Repository{} = r, db \\ :elmverse) do
    query = "SELECT * FROM package WHERE repo_id = $1 ORDER BY pub_name"

    with {:ok, results} <- Db.query(db, query, into: %Package{}, bind: [r.repo_id]) do
      {:ok, results}
    end
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
