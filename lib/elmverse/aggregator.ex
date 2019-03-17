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
      repos
      |> Enum.reduce(0, fn r, index ->
        task_sleep = (index + 1) * 1_000

        Task.Supervisor.start_child(AggregatorTasks, fn ->
          Process.sleep(task_sleep)

          with {:ok, repo_packages} <- Repository.fetch_packages(r),
               {:ok, stored_packages} <- Repository.packages(r),
               {:ok, _} <- Repository.update_timestamp(r) do
            MapSet.difference(MapSet.new(repo_packages), MapSet.new(stored_packages))
            |> MapSet.to_list()
            |> (fn new_pkgs -> Logger.info("New packages: #{inspect(new_pkgs)}") end).()
            |> Enum.each(fn pkg ->
              with {:ok, _} <- Package.save(pkg) do
                :ok
              else
                error ->
                  Logger.error("Failed to store package: #{inspect(pkg)} | #{inspect(error)}")
              end
            end)
          else
            error ->
              Logger.error(
                "Failed to fetch & diff repository packages | #{Kernel.inspect(error)}"
              )

              []
          end
        end)

        index + 1
      end)
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

      packages
      |> Enum.reduce(0, fn pkg, index ->
        meta_url = Map.get(meta_map, pkg.repo_id)
        task_sleep = (index + 1) * 1_000

        Task.Supervisor.start_child(AggregatorTasks, fn ->
          Process.sleep(task_sleep)

          with {:ok, repo_releases} <- Package.fetch_releases(pkg, meta_url),
               {:ok, stored_releases} <- Package.releases(pkg) do
            MapSet.difference(MapSet.new(repo_releases), MapSet.new(stored_releases))
            |> MapSet.to_list()
            |> (fn new_releases -> Logger.info("New releases: #{inspect(new_releases)}") end).()
            |> Enum.each(fn rel ->
              with {:ok, _} <- Release.save(rel) do
                :ok
              else
                error ->
                  Logger.error("Failed to store new release: #{inspect(rel)} | #{inspect(error)}")
              end
            end)
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
      end)
    else
      error ->
        Logger.error("Failed to launch release update aggregator. | #{inspect(error)}")
        error
    end
  end
end
