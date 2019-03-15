defmodule Elmverse.PackageTest do
  use ExUnit.Case

  alias Elmverse.Package

  setup do
    {:ok, pid} = Sqlitex.Server.start_link(":memory:")

    Sqlitex.Server.exec(pid, File.read!("./database/schema.sql"))
    Sqlitex.Server.exec(pid, File.read!("./database/initial_data.sql"))

    on_exit(fn ->
      Sqlitex.Server.stop(pid)
    end)

    {:ok, db: pid}
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
