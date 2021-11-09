defmodule CryptKeeperWeb.CryptoDashboardLive do
  @moduledoc false
  use CryptKeeperWeb, :live_view
  alias CryptKeeper.Product
  alias CryptKeeperWeb.Router.Helpers, as: Routes
  import CryptKeeperWeb.ProductHelpers
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        products: [],
        timezone: get_timezone_from_connection(socket)
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"products" => product_ids}, _uri, socket) do
    new_products = Enum.map(product_ids, &product_from_string/1)
    diff = List.myers_difference(socket.assigns.products, new_products)

    products_to_remove =
      diff
      |> Keyword.get_values(:del)
      |> List.flatten()

    products_to_insert =
      diff
      |> Keyword.get_values(:ins)
      |> List.flatten()

    socket =
      Enum.reduce(products_to_remove, socket, fn product, socket ->
        remove_product(socket, product)
      end)

    socket =
      Enum.reduce(products_to_insert, socket, fn product, socket ->
        add_product(socket, product)
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
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
    product_ids =
      socket.assigns.products
      |> Enum.map(&to_string/1)
      |> Kernel.++([product_id])
      |> Enum.uniq()

    socket = push_patch(socket, to: Routes.live_path(socket, __MODULE__, products: product_ids))

    {:noreply, socket}
  end

  def handle_event("add-product", _, socket) do
    {:noreply, socket}
  end

  def handle_event("remove-product", %{"product-id" => product_id}, socket) do
    product_ids =
      socket.assigns.products
      |> Enum.map(&to_string/1)
      |> Kernel.--([product_id])
      |> Enum.uniq()

    socket = push_patch(socket, to: Routes.live_path(socket, __MODULE__, products: product_ids))

    {:noreply, socket}
  end

  defp product_from_string(product_id) do
    [exchange_name, currency_pair] = String.split(product_id, ":")
    Product.new(exchange_name, currency_pair)
  end

  defp add_product(socket, product) do
    CryptKeeper.subscribe_to_trades(product)

    socket
    |> update(:products, &(&1 ++ [product]))
  end

  defp remove_product(socket, product) do
    CryptKeeper.unsubscribe_to_trades(product)

    socket
    |> update(:products, &(&1 -- [product]))
  end
end
