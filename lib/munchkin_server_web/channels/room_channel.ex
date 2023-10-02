defmodule MunchkinServerWeb.RoomChannel do
  use MunchkinServerWeb, :channel

  @impl true
  def join("room:lobby", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  @impl true
  def handle_in("new_player", payload, socket) do
    broadcast(socket, "create_player", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_in("edit_player", payload, socket) do
    broadcast(socket, "edited_player", payload)
    {:noreply, socket}
  end

  def handle_in("delete_player", payload, socket) do
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
end
