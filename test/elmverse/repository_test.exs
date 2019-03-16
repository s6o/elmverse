defmodule Elmverse.RepositoryTest do
  use Elmverse.DbSetupCase

  alias Elmverse.Repository

  test "Elmverse.Repository.list/1 | Elmverse.Repository.update_timestamp/2",
       %{db: pid} = _context do
    with {:ok, repos} <- Repository.list(pid) do
      repos
      |> Enum.filter(fn r -> r.elm_ver == "0.19" end)
      |> (fn [r | _] ->
            assert r.repo_id == 2
            assert r.last_update == nil

            with {:ok, updated_repo} <- Repository.update_timestamp(r, pid) do
              assert Regex.match?(
                       ~r/\d{4,4}-\d{2,2}-\d{2,2}T\d{2,2}:\d{2,2}:\d{2,2}\.\d+Z/,
                       updated_repo.last_update
                     )
            else
              error ->
                IO.inspect(error, label: "Elmverse.Repository.update_timestamp/2")
                assert false
            end
          end).()
    else
      error ->
        IO.inspect(error, label: "Elmverse.Repository.list/1")
        assert false
    end
  end

  test "Elmverse.Repository.fetch_packages/1", %{db: pid} = _context do
    with {:ok, repos} <- Repository.list(pid) do
      repos
      |> Enum.filter(fn r -> r.elm_ver == "0.19" end)
      |> (fn [r | _] ->
            assert r.repo_id == 2
            assert r.last_update == nil

            with {:ok, packages} <- Repository.fetch_packages(r) do
              packages
              |> Enum.filter(fn p -> p.pub_name == "s6o/elm-recase" end)
              |> (fn [pkg | _] ->
                    assert pkg.repo_id == 2
                    assert pkg.publisher == "s6o"
                    assert pkg.pkg_name == "elm-recase"
                  end).()
            else
              error ->
                IO.inspect(error, label: "Elmverse.Repository.update_timestamp/2")
                assert false
            end
          end).()
    else
      error ->
        IO.inspect(error, label: "Elmverse.Repository.list/1")
        assert false
    end
  end
end
