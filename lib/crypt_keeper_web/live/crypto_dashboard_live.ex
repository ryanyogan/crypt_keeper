defmodule CryptKeeperWeb.CryptoDashboardLive do
  use CryptKeeperWeb, :live_view
  alias CryptKeeper.Product
  import CryptKeeperWeb.ProductHelpers

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        products: [],
        timezone: get_timezone_from_connection(socket)
      )

    {:ok, socket}
  end

  defp get_timezone_from_connection(socket) do
    case get_connect_params(socket) do
      %{"timezone" => tz} when not is_nil(tz) -> tz
      _ -> "UTC"
    end
  end

  @impl true
  def handle_info({:new_trade, trade}, socket) do
    send_update(
      CryptKeeperWeb.ProductComponent,
      id: trade.product,
      trade: trade
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("add-product", %{"product_id" => product_id}, socket) do
    product = product_from_string(product_id)
    socket = maybe_add_product(socket, product)
    {:noreply, socket}
  end

  def handle_event("add-product", _, socket) do
    {:noreply, socket}
  end

  def handle_event("remove-product", %{"product-id" => product_id}, socket) do
    product = product_from_string(product_id)
    socket = update(socket, :products, &List.delete(&1, product))
    CryptKeeper.unsubscribe_to_trades(product)
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

  defp product_from_string(product_id) do
    [exchange_name, currency_pair] = String.split(product_id, ":")
    Product.new(exchange_name, currency_pair)
  end

  defp add_product(socket, product) do
    CryptKeeper.subscribe_to_trades(product)

    socket
    |> update(:products, fn products -> [product | products] end)
  end

  defp grouped_products_by_exchange_name do
    CryptKeeper.available_products()
    |> Enum.group_by(& &1.exchange_name)
  end
end
