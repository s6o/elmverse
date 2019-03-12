defmodule ElmverseWeb.PageController do
  use ElmverseWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
