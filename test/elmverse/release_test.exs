defmodule Elmverse.ReleaseTest do
  use ExUnit.Case
  use Elmverse.DbSetupCase

  alias Elmverse.Package
  alias Elmverse.Release

  test "Elmverse.Release.to_module_doc/2", _context do
    rel = %Release{
      repo_id: 2,
      pub_name: "elm/browser",
      pkg_ver: "1.0.1",
      released: 1_539_963_190
    }

    with {:ok, contents} <- File.read("./test/elmverse/browser_docs.json"),
         {:ok, json_docs} <- Jason.decode(contents) do
      docs =
        json_docs
        |> Enum.map(fn item -> Release.to_module_doc(rel, item) end)
        |> Enum.reduce(%{}, fn m, acc -> Map.merge(acc, m) end)

      docs
      |> Map.values()
      |> Enum.each(fn doc ->
        assert String.ends_with?(doc.item_path, doc.item_name)
      end)
    else
      error ->
        IO.inspect(error, label: "Failed to read browser.json")
        assert false
    end
  end

  test "Elmverse.Release.save/2", %{db: pid} = _context do
    pkg = %Package{
      repo_id: 2,
      pub_name: "elm/browser",
      publisher: "elm",
      pkg_name: "browser",
      license: "BSD",
      summary: "Test package"
    }

    {:ok, _saved_pkg} = Package.save(pkg, pid)

    rel = %Release{
      repo_id: 2,
      pub_name: "elm/browser",
      pkg_ver: "1.0.0",
      released: 1_534_772_907
    }

    with {:ok, _saved_rel} <- Release.save(rel, pid) do
      assert true
    else
      error ->
        IO.inspect(error, label: "Release save failure.")
        assert false
    end
  end
end
