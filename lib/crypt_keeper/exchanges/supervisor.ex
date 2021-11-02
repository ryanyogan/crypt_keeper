defmodule CryptKeeper.Exchanges.Supervisor do
  use Supervisor
  alias CryptKeeper.Exchanges

  @spec start_link(Keyword.t()) :: Supervisor.on_start()
  def start_link(opts) do
    {clients, opts} = Keyword.pop(opts, :clients, Exchanges.clients())
    Supervisor.start_link(__MODULE__, clients, opts)
  end

  @impl true
  def init(clients) do
    Supervisor.init(clients, strategy: :one_for_one)
  end
end
