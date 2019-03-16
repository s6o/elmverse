defmodule Elmverse.DbSetupCase do
  use ExUnit.CaseTemplate

  setup do
    {:ok, pid} = Sqlitex.Server.start_link(":memory:")

    Sqlitex.Server.exec(pid, File.read!("./database/schema.sql"))
    Sqlitex.Server.exec(pid, File.read!("./database/initial_data.sql"))

    on_exit(fn ->
      Sqlitex.Server.stop(pid)
    end)

    {:ok, db: pid}
  end
end
