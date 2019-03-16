defmodule Elmverse.Aggregator do
  alias Elmverse.Repository
  alias Elmverse.Package
  require Logger

  @spec update_packages() :: [Package.t()] | []
  def update_packages() do
    with {:ok, repos} <- Repository.list() do
      repos
      |> Enum.map(fn r ->
        with {:ok, repo_packages} <- Repository.fetch_packages(r),
             {:ok, stored_packages} <- Repository.packages(r),
             {:ok, _} <- Repository.update_timestamp(r) do
          MapSet.difference(MapSet.new(repo_packages), MapSet.new(stored_packages))
          |> MapSet.to_list()
        else
          error ->
            Logger.error("Failed to diff repository packages | #{Kernel.inspect(error)}")
            []
        end
      end)
      |> Enum.flat_map(&extract_packages/1)
    end
  end

  defp extract_packages(repo_packages) do
    repo_packages
    |> Enum.reduce([], fn pkg, acc ->
      with {:ok, saved_pkg} <- Package.save(pkg) do
        [saved_pkg | acc]
      else
        _ ->
          acc
      end
    end)
  end
end
