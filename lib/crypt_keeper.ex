defmodule CryptKeeper do
  @moduledoc """
  CryptKeeper keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  defdelegate subscribe_to_trades(product), to: CryptKeeper.Exchanges, as: :subscribe
  defdelegate unsubscribe_to_trades(product), to: CryptKeeper.Exchanges, as: :unsubscribe
  defdelegate get_last_trade(product), to: CryptKeeper.Historical
  defdelegate get_last_trades(products), to: CryptKeeper.Historical
end
