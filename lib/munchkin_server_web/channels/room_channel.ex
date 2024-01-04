defmodule MunchkinServerWeb.RoomChannel do
  alias MunchkinServer.{Room, RoomSupervisor}
  alias MunchkinServerWeb.Presence
  use MunchkinServerWeb, :channel

  @impl true

  def join("room:" <> room_id, %{"roomEvent" => room_event}, socket) do
    case room_event do
      "create" ->
        start_room_agent(room_id)
        send(self(), :after_join)
        {:ok, socket}

      "enter" ->
        if room_exists?(room_id) do
          start_room_agent(room_id)
          send(self(), :after_join)
          {:ok, socket}
        else
          {:error, %{reason: "room does not exist"}}
        end

      "connect" ->
        start_room_agent(room_id)
        send(self(), :after_join)
        {:ok, socket}

      _ ->
        {:error, %{reason: "invalid room event"}}
    end
  end

  defp start_room_agent(room_id) do
    agent_name = room_agent_name(room_id)

    if Process.whereis(agent_name) == nil do
      {:ok, _pid} =
        DynamicSupervisor.start_child(
          RoomSupervisor,
          {Room, name: agent_name, initial_state: []}
        )
    end
  end

  defp room_exists?(room_id) do
    agent_name = room_agent_name(room_id)

    case Process.whereis(agent_name) do
      nil -> false
      _pid -> true
    end
  end

  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  @impl true
  def handle_in("new_player", payload, %{topic: topic} = socket) do
    get_agent_name(topic)
    |> Room.handler_add_player(payload)

    broadcast(socket, "create_player", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_in("edit_player", payload, %{topic: topic} = socket) do
    get_agent_name(topic)
    |> Room.handler_update_player(payload)

    broadcast(socket, "edited_player", payload)
    {:noreply, socket}
  end

  def handle_in("delete_player", payload, %{topic: topic} = socket) do
    get_agent_name(topic)
    |> Room.handler_delete_player(payload)

    broadcast(socket, "deleted_player", payload)
    {:noreply, socket}
  end

  def handle_in("request_sync", _payload, %{topic: topic} = socket) do
    players =
      get_agent_name(topic)
      |> Room.get_room_state()

    broadcast(socket, "synchronize", %{"players" => players})
    {:noreply, socket}
  end

  def handle_in("reset_all_players", _payload, %{topic: topic} = socket) do
    topic
    |> get_agent_name()
    |> MunchkinServer.Room.reset_all_players()

    players = get_agent_name(topic) |> MunchkinServer.Room.get_room_state()
    broadcast(socket, "synchronize", %{"players" => players})
    {:noreply, socket}
  end

  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} =
      Presence.track(socket, "room", %{
        online_at: inspect(System.system_time(:second))
      })

    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    handler_terminate(socket)
  end

  def handler_terminate(%{topic: topic} = socket) do
    presences = Presence.list(socket)

    if Map.has_key?(presences, "room") do
      %{"room" => %{metas: presences}} = presences
      agent_atom_name = get_agent_name(topic) |> Process.whereis()
      terminate_children(agent_atom_name, presences)
    else
      IO.puts("No presences found for room")
    end
  end

  defp terminate_children(name, presences) when length(presences) <= 1 do
    DynamicSupervisor.terminate_child(RoomSupervisor, name)
  end

  defp terminate_children(_name, _presences) do
    :ok
  end

  defp authorized?(_payload) do
    true
  end

  defp get_agent_name("room:" <> room_id) do
    room_agent_name(room_id)
  end

  defp room_agent_name(room_id) do
    String.to_atom("room_agent_#{room_id}")
  end
end
