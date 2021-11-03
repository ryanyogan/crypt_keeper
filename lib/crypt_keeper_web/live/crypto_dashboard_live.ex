defmodule CryptKeeperWeb.CryptoDashboardLive do
  use CryptKeeperWeb, :live_view
  alias CryptKeeper.Product
  import CryptKeeperWeb.ProductHelpers

  @impl true
  def mount(_params, _session, socket) do
    products = CryptKeeper.available_products()

    trades =
      products
      |> CryptKeeper.get_last_trades()
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&{&1.product, &1})
      |> Enum.into(%{})

    if connected?(socket) do
      Enum.each(products, &CryptKeeper.subscribe_to_trades/1)
    end

    # socket = assign(socket, trades: trades, products: products)
    socket = assign(socket, trades: %{}, products: [])
    {:ok, socket}
  end

  # @impl true
  # def render(assigns) do
  #   ~H"""
  #   <form action="#" phx-submit="add-product">
  #     <select name="product_id">
  #       <option selected disabled>Add a Crypto Product</option>
  #       <%= for product <- CryptKeeper.available_products() do %>
  #         <option value={to_string(product)}>
  #           <%= product.exchange_name %> - <%= product.currency_pair %>
  #         </option>
  #       <% end %>
  #     </select>

  #     <button type="submit" phx-disable-with="Loading...">Add product</button>
  #   </form>

  #   <h1 class="text-red-500 text-5xl font-bold text-center">Tailwind CSS</h1>
  #   <table>
  #     <thead>
  #       <th>Traded at</th>
  #       <th>Exchange</th>
  #       <th>Currency</th>
  #       <th>Price</th>
  #       <th>Volume</th>
  #     </thead>
  #     <tbody>
  #     <%= for product <- @products, trade = @trades[product], not is_nil(trade) do%>
  #       <tr>
  #         <td><%= trade.traded_at %></td>
  #         <td><%= trade.product.exchange_name %></td>
  #         <td><%= trade.product.currency_pair %></td>
  #         <td><%= trade.price %></td>
  #         <td><%= trade.volume %></td>
  #       </tr>
  #     <% end %>
  #     </tbody>
  #   </table>
  #   """
  # end

  @impl true
  def handle_info({:new_trade, trade}, socket) do
    socket =
      update(socket, :trades, fn trades ->
        Map.put(trades, trade.product, trade)
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear", _params, socket) do
    {:noreply, assign(socket, :trades, %{})}
  end

  @impl true
  def handle_event("add-product", %{"product_id" => product_id}, socket) do
    [exchange_name, currency_pair] = String.split(product_id, ":")
    product = Product.new(exchange_name, currency_pair)
    socket = maybe_add_product(socket, product)
    {:noreply, socket}
  end

  defp maybe_add_product(socket, product) do
    if product not in socket.assigns.products do
      socket
      |> add_product(product)
    else
      socket
    end
  end

  defp add_product(socket, product) do
    CryptKeeper.subscribe_to_trades(product)

    socket
    |> update(:products, fn products -> [product | products] end)
    |> update(:trades, fn trades ->
      trade = CryptKeeper.get_last_trade(product)
      Map.put(trades, product, trade)
    end)
  end

  defp grouped_products_by_exchange_name do
    CryptKeeper.available_products()
    |> Enum.group_by(& &1.exchange_name)
  end
end
