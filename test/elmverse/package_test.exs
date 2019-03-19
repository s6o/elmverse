defmodule Elmverse.PackageTest do
  use ExUnit.Case
  use Elmverse.DbSetupCase

  alias Elmverse.Repository
  alias Elmverse.Package

  test "Elmverse.Package.fetch_releases/2", %{db: pid} = _context do
    with {:ok, repos} <- Repository.list(pid) do
      repos
      |> Enum.filter(fn r -> r.elm_ver == "0.19" end)
      |> (fn [r | _] ->
            assert r.repo_id == 2
            assert r.last_update == nil

            with {:ok, packages} <- Repository.fetch_packages(r) do
              packages
              |> Enum.filter(fn p -> p.pub_name == "elm/browser" end)
              |> (fn [pkg | _] ->
                    assert pkg.repo_id == 2
                    assert pkg.publisher == "elm"
                    assert pkg.pkg_name == "browser"

                    with {:ok, [rel | _releases]} <- Package.fetch_releases(pkg, r.meta_url) do
                      assert rel.pub_name == "elm/browser"
                      assert rel.pkg_ver == "1.0.1"
                      assert rel.released == 1_539_963_190
                      assert rel.repo_id == 2
                    else
                      error ->
                        IO.inspect(error, label: "Release fetch.")
                    end
                  end).()
            else
              error ->
                IO.inspect(error, label: "Package fetch.")
                assert false
            end
          end).()
    else
      error ->
        IO.inspect(error, label: "Repository fetch.")
        assert false
    end
  end

  test "Elmverse.Package.save/1", %{db: pid} = _context do
    pkg1 = %Package{
      repo_id: 1,
      pub_name: "elm/browser",
      publisher: "elm",
      pkg_name: "browser",
      license: "BSD",
      summary: "Pkg test"
    }

    pkg2 = %Package{
      repo_id: 1,
      pub_name: "elm/core",
      publisher: "elm",
      pkg_name: "core",
      license: "BSD",
      summary: "Pkg test"
    }

    with {:ok, new_pkg1} <- Package.save(pkg1, pid),
         {:ok, new_pkg2} <- Package.save(pkg2, pid) do
      assert Map.get(new_pkg1, :pkg_id) == 1
      assert Map.get(new_pkg2, :pkg_id) == 2
    else
      error ->
        IO.inspect(error, label: "Elmverse.Package.save/1")
        assert false
    end
  end
end
