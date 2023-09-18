defmodule MunchkinServer.Repo do
  use Ecto.Repo,
    otp_app: :munchkin_server,
    adapter: Ecto.Adapters.Postgres
end
