defmodule CryptKeeper.HistoricalTest do
  use ExUnit.Case, async: true
  alias CryptKeeper.{Historical, Exchanges, Product, Trade}

  setup :start_fresh_historical_with_all_products
  setup :start_fresh_historical_with_all_coinbase_products
  setup :start_historical_with_trades_for_all_products

  describe "get_last_trade/2" do
    test "gets the most recent trade for a product", %{all_historical: historical} do
      product = coinbase_btc_usd_product()
      assert nil == Historical.get_last_trade(historical, product)

      # broadcast the trade
      trade = build_valid_trade(product)
      broadcast_trade(trade)

      new_trade = build_valid_trade(product)
      assert :gt == DateTime.compare(new_trade.traded_at, trade.traded_at)

      broadcast_trade(new_trade)
      assert new_trade == Historical.get_last_trade(historical, product)
    end
  end

  defp all_products, do: Exchanges.available_products()
  defp broadcast_trade(trade), do: Exchanges.broadcast(trade)
  defp coinbase_btc_usd_product, do: Product.new("coinbase", "BTC-USD")
  defp bitstamp_btc_usd_product, do: Product.new("bitstamp", "btcusd")

  defp all_coinbase_products do
    Exchanges.available_products()
    |> Enum.filter(&(&1.exchange_name == "coinbase"))
  end

  defp build_valid_trade(product) do
    %Trade{
      product: product,
      traded_at: DateTime.utc_now(),
      price: "10000.00",
      volume: "0.10000"
    }
  end

  defp start_fresh_historical_with_all_products(_context) do
    {:ok, all_historical} = Historical.start_link(products: all_products())
    [all_historical: all_historical]
  end

  defp start_fresh_historical_with_all_coinbase_products(_context) do
    {:ok, coinbase_historical} = Historical.start_link(products: all_coinbase_products())
    [coinbase_historical: coinbase_historical]
  end

  defp start_historical_with_trades_for_all_products(_context) do
    products = all_products()
    {:ok, historical} = Historical.start_link(products: products)
    Enum.each(products, &send(historical, {:new_trade, build_valid_trade(&1)}))
    [historical_with_trades: historical]
  end
end
