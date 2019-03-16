defmodule Elmverse.ReleaseTest do
  use ExUnit.Case
  use Elmverse.DbSetupCase

  alias Elmverse.Package
  alias Elmverse.Release

  test "Elmverse.Release.save/2", %{db: pid} = _context do
    pkg = %Package{
      repo_id: 2,
      pub_name: "elm/browser",
      publisher: "elm",
      pkg_name: "browser",
      license: "BSD",
      summary: "Test package"
    }

    {:ok, saved_pkg} = Package.save(pkg, pid)

    rel = %Release{
      repo_id: 2,
      pkg_id: saved_pkg.pkg_id,
      pub_name: "elm/browser",
      pkg_ver: "1.0.0",
      released: 1_534_772_907
    }

    with {:ok, saved_rel} <- Release.save(rel, pid) do
      assert saved_rel.rel_id == 1
    else
      error ->
        IO.inspect(error, label: "Release save failure.")
        assert false
    end
  end
end
