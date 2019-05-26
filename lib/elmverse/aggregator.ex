defmodule Elmverse.Aggregator do
  alias Elmverse.Repository
  alias Elmverse.Package
  alias Elmverse.Release
  alias Elmverse.Release.Readme
  alias Elmverse.Release.Dep
  alias Elmverse.Release.Doc
  require Logger

  @tasksleep 500

  @doc """
  Main aggregator, combines the:
    * add_packages/0
    * add_releases/1
    * add_docs/1
    * add_deps/1
  into a single function.
  """
  @spec run() :: {:ok, non_neg_integer()} | {:error, any()}
  def run() do
    with {:ok, packages} <- add_packages(),
         {:ok, releases} <- add_releases(packages),
         {:ok, doc_count} <- add_docs(releases),
         {:ok, _} <- add_deps(releases) do
      {:ok, doc_count}
    end
  end

  @doc """
  Fetch list of packages over repositories, return list of packages with a new release.
  """
  @spec add_packages() :: {:ok, [] | [Package.t()]} | {:error, any()}
  def add_packages() do
    with {:ok, repos} <- Repository.list() do
      {:ok,
       repos
       |> Enum.flat_map(fn r ->
         with {:ok, repo_packages} <- Repository.fetch_packages(r),
              {:ok, stored_packages} <- Repository.packages(r),
              {:ok, _} <- Repository.update_timestamp(r) do
           MapSet.difference(
             MapSet.new(repo_packages),
             MapSet.new(stored_packages)
           )
           |> MapSet.to_list()
           |> Enum.reduce([], fn pkg, acc ->
             with {:ok, saved_pkg} <- Package.save(pkg) do
               Logger.info("New package: #{inspect(saved_pkg)}")
               [saved_pkg | acc]
             else
               error ->
                 Logger.error("Failed to store package: #{inspect(pkg)} | #{inspect(error)}")
                 acc
             end
           end)
         else
           error ->
             Logger.error("Failed to fetch & diff repository packages | #{Kernel.inspect(error)}")
             []
         end
       end)}
    else
      error ->
        Logger.error("Failed to launch package update aggregator. | #{inspect(error)}")
        error
    end
  end

  @doc """
  Add release entries for latest updated packages, return list of new package releases.
  """
  @spec add_releases([Package.t()]) :: {:ok, [] | [Releases.t()]} | {:error, any()}
  def add_releases([]), do: {:ok, []}

  def add_releases([%Package{} | _] = packages) do
    with {:ok, repos} <- Repository.list() do
      meta_map =
        repos
        |> Enum.map(fn r -> {r.repo_id, r.meta_url} end)
        |> Map.new()

      {:ok,
       packages
       |> Task.async_stream(fn pkg ->
         Process.sleep(@tasksleep)
         meta_url = Map.get(meta_map, pkg.repo_id)

         with {:ok, repo_releases} <- Package.fetch_releases(pkg, meta_url) do
           repo_releases
           |> Enum.filter(fn r -> r.pkg_ver == pkg.latest_version end)
           |> Enum.reduce([], fn rel, acc ->
             with {:ok, saved_rel} <- Release.save(rel) do
               Logger.info("New package release: #{inspect(saved_rel)}")
               [saved_rel | acc]
             else
               error ->
                 Logger.error("Failed to store new release: #{inspect(rel)} | #{inspect(error)}")

                 acc
             end
           end)
         else
           error ->
             Logger.error(
               "Failed to fetch & diff releases for: #{inspect(pkg)} from #{meta_url} | #{
                 inspect(error)
               }"
             )

             []
         end
       end)
       |> Enum.reduce([], fn {:ok, rels}, acc -> [rels | acc] end)
       |> List.flatten()}
    else
      error ->
        Logger.error("Failed to launch release update aggregator. | #{inspect(error)}")
        error
    end
  end

  @doc """
  For a given package release fetch package dependencies.
  """
  @spec add_deps([Release.t()]) :: {:ok, non_neg_integer()} | {:error, any()}
  def add_deps([]), do: {:ok, 0}

  def add_deps([%Release{} | _] = releases) do
    with {:ok, repos} <- Repository.list() do
      dep_map =
        repos
        |> Enum.map(fn r -> {r.repo_id, {r.dep_url, r.dep_json}} end)
        |> Map.new()

      {:ok,
       releases
       |> Task.async_stream(
         fn rel ->
           Process.sleep(@tasksleep)
           {dep_url, dep_json} = Map.get(dep_map, rel.repo_id)

           with {:ok, deps} <- Release.fetch_deps(rel, dep_url, dep_json),
                {:ok, rel_count} <-
                  (fn ->
                     deps
                     |> Enum.reduce(0, fn d, index ->
                       with {:ok, _} <- Dep.save(d) do
                         index + 1
                       else
                         error ->
                           Logger.error(
                             "Failed to save dependencies: #{inspect(d)} | #{inspect(error)}"
                           )

                           index
                       end
                     end)
                     |> (fn count ->
                           if count == Enum.count(deps) do
                             Logger.info("Processed dependencies for #{inspect(rel)}")
                             {:ok, 1}
                           else
                             {:error, "Failed to save dependencies | #{inspect(rel)}"}
                           end
                         end).()
                   end).() do
             {:ok, rel_count}
           else
             error ->
               req_url = dep_url <> "/" <> rel.pub_name <> "/" <> rel.pkg_ver <> "/" <> dep_json

               Logger.error(
                 "Failed to fetch dependencies for: #{inspect(rel)} from #{req_url} | #{
                   inspect(error)
                 }"
               )

               error
           end
         end,
         timeout: 10_000 + Enum.count(releases) * @tasksleep
       )
       |> Stream.filter(fn {res1, {res2, _}} -> res1 == :ok && res2 == :ok end)
       |> Enum.reduce(0, fn {:ok, {_, c}}, acc -> acc + c end)}
    else
      error ->
        Logger.error("Failed to launch release dependency aggregator. | #{inspect(error)}")
        error
    end
  end

  @doc """
  For a given package release fetch package release documentation.
  """
  @spec add_docs([Release.t()]) :: {:ok, non_neg_integer()} | {:error, any()}
  def add_docs([]), do: {:ok, 0}

  def add_docs([%Release{} | _] = releases) do
    with {:ok, repos} <- Repository.list() do
      meta_map =
        repos
        |> Enum.map(fn r -> {r.repo_id, r.meta_url} end)
        |> Map.new()

      {:ok,
       releases
       |> Task.async_stream(
         fn rel ->
           Process.sleep(@tasksleep)
           meta_url = Map.get(meta_map, rel.repo_id)

           with {:ok, readme} <- Release.fetch_readme(rel, meta_url),
                {:ok, docs_map} <- Release.fetch_docs(rel, meta_url),
                {:ok, _} <- Readme.save(readme),
                {:ok, rel_count} <-
                  (fn ->
                     docs_map
                     |> Enum.reduce(0, fn {_, d}, index ->
                       with {:ok, _} <- Doc.save(d) do
                         index + 1
                       else
                         error ->
                           Logger.error(
                             "Failed to save release doc: #{inspect(d)} | #{inspect(error)}"
                           )

                           index
                       end
                     end)
                     |> (fn count ->
                           if count == Enum.count(docs_map) do
                             Logger.info("Processed docs for #{inspect(rel)}")
                             {:ok, 1}
                           else
                             {:error, "Failed to save release doc | #{inspect(rel)}"}
                           end
                         end).()
                   end).() do
             {:ok, rel_count}
           else
             error ->
               Logger.error(
                 "Failed to fetch readme and/or docs for: #{inspect(rel)} from #{meta_url} | #{
                   inspect(error)
                 }"
               )

               error
           end
         end,
         timeout: 10_000 + Enum.count(releases) * @tasksleep
       )
       |> Stream.filter(fn {res1, {res2, _}} -> res1 == :ok && res2 == :ok end)
       |> Enum.reduce(0, fn {:ok, {_, c}}, acc -> acc + c end)}
    else
      error ->
        Logger.error("Failed to launch release update aggregator. | #{inspect(error)}")
        error
    end
  end
end
