defmodule ElmverseWeb.RepositoryController do
  use ElmverseWeb, :controller

  def index(conn, %{"elm_ver" => elm_ver}) do
    render(conn, "repository.html", elm_ver: elm_ver)
  end

  def show(conn, %{"elm_ver" => elm_ver, "pub" => pub, "pkg" => pkg, "ver" => ver}) do
    render(conn, "package.html", elm_ver: elm_ver, pub: pub, pkg: pkg, ver: ver)
  end
end
