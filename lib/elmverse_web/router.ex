defmodule ElmverseWeb.Router do
  use ElmverseWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ElmverseWeb do
    pipe_through :browser

    get "/", IndexController, :index

    get "/repo/:elm_ver", RepositoryController, :index
    get "/repo/:elm_ver/:pub/:pkg/:ver", RepositoryController, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", ElmverseWeb do
  #   pipe_through :api
  # end
end
