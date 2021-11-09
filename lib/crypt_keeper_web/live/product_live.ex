defmodule CryptKeeperWeb.ProductLive do
  @moduledoc false
  use CryptKeeperWeb, :live_view
  import CryptKeeperWeb.ProductHelpers

  @impl true
  def mount(%{"id" => product_id}, _session, socket) do
    product = product_from_string(product_id)
    trade = CryptKeeper.get_last_trade(product)

    socket =
      assign(
        socket,
        product: product,
        product_id: product_id,
        trade: trade,
        page_title: page_title_from_trade(trade)
      )

    if connected?(socket) do
      CryptKeeper.subscribe_to_trades(product)
    end

    {:ok, socket}
  end

  @impl true
  def render(%{trade: trade} = assigns) when not is_nil(trade) do
    ~H"""
      <div>
        <h1><%= fiat_character(@product) %> <%= @trade.price %></h1>
        <p>Traded at <%= human_datetime(@trade.traded_at) %></p>
      </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <h1><%= fiat_character(@product) %>...</h1>
      </div>
    """
  end

  @impl true
  def handle_info({:new_trade, trade}, socket) do
    socket =
      socket
      |> assign(:trade, trade)

    {:noreply, socket}
  end

  defp page_title_from_trade(trade) do
    "#{fiat_character(trade.product)}"
  end
end
