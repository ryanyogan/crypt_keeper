defmodule CryptKeeper.Exchanges.CoinbaseClient do
  alias CryptKeeper.{Product, Trade}
  alias CryptKeeper.Exchanges.Client

  require Client

  Client.defclient(
    exchange_name: "coinbase",
    host: 'ws-feed.pro.coinbase.com',
    port: 443,
    currency_pairs: ["BTC-USD", "ETH-USD", "LTC-USD"]
  )

  @impl true
  def handle_ws_message(%{"type" => "ticker"} = msg, state) do
    msg
    |> message_to_trade()
    |> IO.inspect(label: "ticker")

    {:noreply, state}
  end

  @impl true
  def handle_ws_message(msg, state) do
    IO.inspect(msg, label: "unhandled message")
    {:noreply, state}
  end

  @impl true
  @spec subscription_frames(list()) :: [{:text, String.t()}]
  def subscription_frames(currency_pairs) do
    msg =
      %{
        "type" => "subscribe",
        "product_ids" => currency_pairs,
        "channels" => ["ticker"]
      }
      |> Jason.encode!()

    [{:text, msg}]
  end

  @spec message_to_trade(map()) :: {:ok, Trade.t()} | {:error, any()}
  def message_to_trade(msg) do
    with :ok <- validate_required(msg, ["product_id", "time", "price", "last_size"]),
         {:ok, traded_at, _} <- DateTime.from_iso8601(msg["time"]) do
      currency_pair = msg["product_id"]

      {:ok,
       Trade.new(
         product: Product.new(exchange_name(), currency_pair),
         price: msg["price"],
         volume: msg["last_size"],
         traded_at: traded_at
       )}
    else
      {:error, _reason} = error -> error
    end
  end
end
