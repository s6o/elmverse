defmodule Elmverse.Aggregator do
  alias Elmverse.Repository
  alias Elmverse.Package
  alias Elmverse.Release
  require Logger

  @tasksleep 500

  @doc """
  Fetch list of packages over repositories, return list of packages with a new release.
  """
  @spec update_packages() :: {:ok, [] | [Package.t()]} | {:error, any()}
  def update_packages() do
    with {:ok, repos} <- Repository.list() do
      {:ok,
       repos
       |> Enum.flat_map(fn r ->
         with {:ok, repo_packages} <- Repository.fetch_packages(r),
              {:ok, stored_packages} <- Repository.packages(r),
              {:ok, _} <- Repository.update_timestamp(r) do
           MapSet.difference(
             MapSet.new(repo_packages),
             MapSet.new(stored_packages |> Enum.map(fn p -> %{p | pkg_id: nil} end))
           )
           |> MapSet.to_list()
           |> Enum.reduce([], fn pkg, acc ->
             with {:ok, saved_pkg} <- Package.save(pkg) do
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
  @spec update_releases([Package.t()]) :: {:ok, [] | [Releases.t()]} | {:error, any()}
  def update_releases([%Package{} | _] = packages) do
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
end
