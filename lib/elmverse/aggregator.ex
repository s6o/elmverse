defmodule Elmverse.Aggregator do
  alias Elmverse.Repository
  alias Elmverse.Package
  alias Elmverse.Release
  alias Elmverse.Release.Readme
  alias Elmverse.Release.Doc
  require Logger

  @tasksleep 500

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
  For a given of package release list fetch package release documentation.
  """
  @spec add_docs([Release.t()]) :: {:ok, non_neg_integer()} | {:error, any()}
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
                             Logger.info("Processed #{inspect(rel)}")
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
