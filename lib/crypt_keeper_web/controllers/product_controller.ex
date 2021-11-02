defmodule CryptKeeperWeb.ProductController do
  use CryptKeeperWeb, :controller

  def index(conn, _params) do
    trades =
      CryptKeeper.available_products()
      |> CryptKeeper.get_last_trades()

    render(conn, "index.html", trades: trades)
  end
end
