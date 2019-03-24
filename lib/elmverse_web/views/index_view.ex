defmodule ElmverseWeb.IndexView do
  use ElmverseWeb, :view

  alias Elmverse.Repository.Summary

  def fmt_last_update(%Summary{} = s) do
    {:ok, ts, _} = DateTime.from_iso8601(s.last_update)
    DateTime.to_string(ts)
  end
end
