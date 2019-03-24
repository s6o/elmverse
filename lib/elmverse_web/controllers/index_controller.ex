defmodule ElmverseWeb.IndexController do
  use ElmverseWeb, :controller

  alias Elmverse.Repository.Summary

  def index(conn, _params) do
    repositories =
      with {:ok, repos} <- Summary.list() do
        repos
      else
        _ -> []
      end

    render(conn, "index.html", repositories: repositories)
  end
end
