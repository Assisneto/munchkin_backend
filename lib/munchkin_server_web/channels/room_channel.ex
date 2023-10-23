defmodule MunchkinServerWeb.RoomChannel do
  alias MunchkinServer.{Room, RoomSupervisor}
  use MunchkinServerWeb, :channel

  @impl true
  def join("room:" <> room_id, payload, socket) do
    if authorized?(payload) do
      start_room_agent(room_id)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  defp start_room_agent(room_id) do
    agent_name = room_agent_name(room_id)
    # Check if the agent already exists
    if Process.whereis(agent_name) == nil do
      # Start a new agent for the room
      {:ok, _pid} =
        DynamicSupervisor.start_child(
          RoomSupervisor,
          {Room, name: agent_name, initial_state: []}
        )
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
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

  def handle_in("request_sync", payload, socket) do
    broadcast(socket, "sync", payload)
    {:noreply, socket}
  end

  def handle_in("syncing", payload, socket) do
    broadcast(socket, "synchronize", payload)
    {:noreply, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (room:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
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
