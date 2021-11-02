defmodule CryptKeeper.Exchanges.CoinbaseClient do
  use GenServer

  alias CryptKeeper.{Product, Trade}

  @exchange_name "coinbase"

  @spec server_host :: charlist()
  def server_host, do: 'ws-feed.pro.coinbase.com'

  @spec server_port :: integer()
  def server_port, do: 443

  @spec connect(map()) :: map()
  def connect(state) do
    {:ok, conn} = :gun.open(server_host(), server_port(), %{protocols: [:http]})
    %{state | conn: conn}
  end

  @spec start_link(list(), Keyword.t()) :: GenServer.on_start()
  def start_link(currency_pairs, options \\ []) do
    GenServer.start_link(__MODULE__, currency_pairs, options)
  end

  @impl true
  def init(currency_pairs) do
    state = %{
      currency_pairs: currency_pairs,
      conn: nil
    }

    {:ok, state, {:continue, :connect}}
  end

  @impl true
  def handle_continue(:connect, state) do
    updated_state = connect(state)
    {:noreply, updated_state}
  end

  @impl true
  def handle_info({:gun_up, conn, :http}, %{conn: conn} = state) do
    :gun.ws_upgrade(state.conn, "/")
    {:noreply, state}
  end

  @impl true
  def handle_info({:gun_upgrade, _conn, _ref, ["websocket"], _headers}, state) do
    subscribe(state)
    {:noreply, state}
  end

  @impl true
  def handle_info({:gun_ws, _conn, _ref, {:text, msg}}, state) do
    handle_ws_message(Jason.decode!(msg), state)
  end

  @spec handle_ws_message(map(), map()) :: tuple()
  def handle_ws_message(%{"type" => "ticker"} = msg, state) do
    msg
    |> message_to_trade()
    |> IO.inspect(label: "ticker")

    {:noreply, state}
  end

  def handle_ws_message(msg, state) do
    IO.inspect(msg, label: "unhandled message")
    {:noreply, state}
  end

  @spec message_to_trade(map()) :: {:ok, Trade.t()} | {:error, any()}
  def message_to_trade(msg) do
    with :ok <- validate_required(msg, ["product_id", "time", "price", "last_size"]),
         {:ok, traded_at, _} <- DateTime.from_iso8601(msg["time"]) do
      currency_pair = msg["product_id"]

      {:ok,
       Trade.new(
         product: Product.new(@exchange_name, currency_pair),
         price: msg["price"],
         volume: msg["last_size"],
         traded_at: traded_at
       )}
    else
      {:error, _reason} = error -> error
    end
  end

  @spec validate_required(map(), [String.t()]) :: :ok | {:error, {String.t(), :required}}
  def validate_required(msg, keys) do
    required_key = Enum.find(keys, fn k -> is_nil(msg[k]) end)

    if is_nil(required_key),
      do: :ok,
      else: {:error, {required_key, :required}}
  end

  defp subscribe(state) do
    subscription_frames(state.currency_pairs)
    |> Enum.each(&:gun.ws_send(state.conn, &1))
  end

  @spec subscription_frames(list()) :: list()
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
end
