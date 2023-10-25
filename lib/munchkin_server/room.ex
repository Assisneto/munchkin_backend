defmodule MunchkinServer.Room do
  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    initial_state = Keyword.get(opts, :initial_state, [])
    Agent.start_link(fn -> initial_state end, name: name)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def get_room_state(name) do
    Agent.get(name, fn state -> state end)
  end

  def handler_add_player(name, player) do
    Agent.update(name, fn state -> add_player(state, player) end)
  end

  def handler_update_player(name, player) do
    Agent.update(name, fn state -> update_player(state, player) end)
  end

  def handler_delete_player(name, player) do
    Agent.update(name, fn state -> delete_player(state, player) end)
  end

  def reset_all_players(name) do
    Agent.update(name, &reset_player_attributes/1)
  end

  defp add_player(state, player) do
    state ++ [player]
  end

  defp update_player(state, player) do
    updated_state = delete_player(state, player)
    [player | updated_state]
  end

  def delete_player(state, %{"name" => name}) do
    Enum.reject(state, fn player -> player["name"] == name end)
  end

  defp reset_player_attributes(state) do
    Enum.map(state, fn player ->
      Map.put(player, "level", 1)
      |> Map.put("power", 0)
    end)
  end
end
