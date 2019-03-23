defmodule Elmverse.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the endpoint when the application starts
      ElmverseWeb.Endpoint,
      # SQLite Server
      %{
        id: Sqlitex.Server,
        start: {Sqlitex.Server, :start_link, ["priv/elmverse.db", [name: :elmverse]]}
      }
    ]

    opts = [strategy: :one_for_one, name: Elmverse.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ElmverseWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
