defmodule ElmverseWeb.RepositoryController do
  use ElmverseWeb, :controller

  alias Elmverse.Repository.PackageSummary

  def index(conn, %{"elm_ver" => elm_ver}) do
    repo_packages =
      with {:ok, pkg_list} <- PackageSummary.list(elm_ver) do
        pkg_list
      else
        _ ->
          []
      end

    render(conn, "repository.html", elm_ver: elm_ver, repo_packages: repo_packages)
  end

  def show(conn, %{"elm_ver" => elm_ver, "pub" => pub, "pkg" => pkg, "ver" => ver}) do
    render(conn, "package.html", elm_ver: elm_ver, pub: pub, pkg: pkg, ver: ver)
  end
end
