defmodule Elmverse.Aggregator do
  alias Elmverse.Repository
  alias Elmverse.Package
  alias Elmverse.Release
  require Logger

  @doc """
  Launch package repository aggregation/update tasks after every second.
  On success return number of tasks launched.
  """
  @spec update_packages() :: {:ok, non_neg_integer} | {:error, any()}
  def update_packages() do
    with {:ok, repos} <- Repository.list() do
      {:ok,
       repos
       |> Enum.reduce(0, fn r, index ->
         task_sleep = (index + 1) * 1_000

         Task.Supervisor.start_child(AggregatorTasks, fn ->
           Process.sleep(task_sleep)

           with {:ok, repo_packages} <- Repository.fetch_packages(r),
                {:ok, stored_packages} <- Repository.packages(r),
                {:ok, _} <- Repository.update_timestamp(r) do
             MapSet.difference(
               MapSet.new(repo_packages),
               MapSet.new(stored_packages |> Enum.map(fn p -> %{p | pkg_id: nil} end))
             )
             |> MapSet.to_list()
             |> (fn new_pkgs ->
                   if Enum.empty?(new_pkgs) do
                     Logger.info("No new packages | #{inspect(r)}")
                   else
                     Enum.each(new_pkgs, fn pkg ->
                       with {:ok, saved_pkg} <- Package.save(pkg) do
                         Logger.info("New package: #{inspect(saved_pkg)}")
                       else
                         error ->
                           Logger.error(
                             "Failed to store package: #{inspect(pkg)} | #{inspect(error)}"
                           )
                       end
                     end)
                   end
                 end).()
           else
             error ->
               Logger.error(
                 "Failed to fetch & diff repository packages | #{Kernel.inspect(error)}"
               )
           end
         end)

         index + 1
       end)}
    else
      error ->
        Logger.error("Failed to launch package update aggregator. | #{inspect(error)}")
        error
    end
  end

  @doc """
  Lauch package release aggregation/update tasks after every second.
  On success return number of tasks launched.
  """
  @spec update_releases() :: {:ok, non_neg_integer()} | {:error, any()}
  def update_releases() do
    with {:ok, repos} <- Repository.list(),
         {:ok, packages} <- Package.list() do
      meta_map =
        repos
        |> Enum.map(fn r -> {r.repo_id, r.meta_url} end)
        |> Map.new()

      {:ok,
       packages
       |> Enum.reduce(0, fn pkg, index ->
         meta_url = Map.get(meta_map, pkg.repo_id)
         task_sleep = (index + 1) * 1_000

         Task.Supervisor.start_child(AggregatorTasks, fn ->
           Process.sleep(task_sleep)

           with {:ok, repo_releases} <- Package.fetch_releases(pkg, meta_url),
                {:ok, stored_releases} <- Package.releases(pkg) do
             MapSet.difference(
               MapSet.new(repo_releases),
               MapSet.new(stored_releases |> Enum.map(fn r -> %{r | rel_id: nil} end))
             )
             |> MapSet.to_list()
             |> (fn new_rels ->
                   if Enum.empty?(new_rels) do
                     Logger.info("No new releases | #{inspect(pkg)}")
                   else
                     Enum.each(new_rels, fn rel ->
                       with {:ok, saved_rel} <- Release.save(rel) do
                         Logger.info("New release: #{inspect(saved_rel)}")
                       else
                         error ->
                           Logger.error(
                             "Failed to store new release: #{inspect(rel)} | #{inspect(error)}"
                           )
                       end
                     end)
                   end
                 end).()
           else
             error ->
               Logger.error(
                 "Failed to fetch & diff releases for: #{inspect(pkg)} from #{meta_url} | #{
                   inspect(error)
                 }"
               )
           end
         end)

         index + 1
       end)}
    else
      error ->
        Logger.error("Failed to launch release update aggregator. | #{inspect(error)}")
        error
    end
  end
end
