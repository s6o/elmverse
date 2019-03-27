defmodule ElmverseWeb.RepositoryView do
  use ElmverseWeb, :view

  def release_date(unix_epoch) do
    unix_epoch
    |> DateTime.from_unix!(:second)
    |> DateTime.to_string()
  end
end
