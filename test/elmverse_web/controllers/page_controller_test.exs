defmodule ElmverseWeb.PageControllerTest do
  use ElmverseWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Elmverse!"
  end
end
