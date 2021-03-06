defmodule CryptKeeperWeb.Router do
  use CryptKeeperWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {CryptKeeperWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CryptKeeperWeb do
    pipe_through :browser

    live "/", CryptoDashboardLive
    live "/products/:id", ProductLive
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: CryptKeeperWeb.Telemetry
    end
  end

  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
