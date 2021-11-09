defmodule CryptKeeperWeb.ProductComponent do
  use CryptKeeperWeb, :live_component
  import CryptKeeperWeb.ProductHelpers

  @impl true
  def update(%{trade: trade}, socket) when not is_nil(trade) do
    product_id = to_string(trade.product)
    event_name = "new-trade:#{product_id}"

    socket =
      socket
      |> assign(:trade, trade)
      |> push_event(event_name, to_event(trade))

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    product = assigns.id

    socket =
      assign(socket,
        timezone: assigns.timezone,
        product: product,
        trade: CryptKeeper.get_last_trade(product)
      )

    {:ok, socket}
  end

  @impl true
  def render(%{trade: trade} = assigns) when not is_nil(trade) do
    ~H"""
    <div class="mt-5 mx-2 bg-white shadow overflow-hidden sm:rounded-lg">
      <div class="px-4 py-5 sm:px-6 flex">
        <h3 class="text-lg leading-6 font-medium text-gray-900 flex items-center">
          <img class="mr-2" src={crypto_icon(@socket, @product)} />
          <%= crypto_name(@product) %>
        </h3>
      </div>
      <div class="border-t border-gray-200">
        <dl>
          <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">
              Price
            </dt>
            <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
              <%= @trade.price %>
              <%= fiat_character(@product) %>
            </dd>
          </div>
          <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">
              Product
            </dt>
            <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
              <%= @product.exchange_name %> - <%= fiat_symbol(@product) %>
            </dd>
          </div>
          <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">
              Traded At
            </dt>
            <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
              <%= human_datetime(@trade.traded_at, @timezone) %>
            </dd>
          </div>
          <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
            <dt class="text-sm font-medium text-gray-500">
              Actions
            </dt>
            <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
              <a href="#"
                  phx-click="remove-product"
                  phx-value-product-id={to_string(@product)}
                  class="font-medium text-indigo-600 hover:text-indigo-500">
                <%= "Remove #{crypto_name(@product)}" %>
              </a>
            </dd>
          </div>
        </dl>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="m-5">
      <div class="currency-container">
        <img src={crypto_icon(@socket, @product)} class="icon" />
        <div class="crypto-name">
          <%= crypto_name(@product) %>
        </div>
      </div>

      <div class="price-container">
        <ul class="fiat-symbols">
          <%= for fiat <- fiat_symbols() do %>
            <li class={if fiat_symbol(@product) == fiat, do: "active"}>
              <%= fiat %>
            </li>
          <% end %>
        </ul>

        <div class="price">
          ... <%= fiat_character(@product) %>
        </div>
      </div>

      <div class="exchange-name">
        <%= @product.exchange_name %>
      </div>

      <div class="trade-time">
      </div>
    </div>
    """
  end

  defp to_event(trade) do
    %{
      traded_at: trade.traded_at,
      price: trade.price,
      volume: trade.volume
    }
  end
end
