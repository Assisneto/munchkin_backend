defmodule MunchkinServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      MunchkinServerWeb.Telemetry,
      # Start the Ecto repository
      MunchkinServer.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: MunchkinServer.PubSub},
      # Start the Endpoint (http/https)
      MunchkinServerWeb.Endpoint,
      # Start a worker by calling: MunchkinServer.Worker.start_link(arg)
      {DynamicSupervisor, strategy: :one_for_one, name: MunchkinServer.RoomSupervisor},
      MunchkinServerWeb.Presence
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MunchkinServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MunchkinServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
