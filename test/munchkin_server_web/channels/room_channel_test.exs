defmodule MunchkinServerWeb.RoomChannelTest do
  use MunchkinServerWeb.ChannelCase

  setup do
    {:ok, _, socket} =
      MunchkinServerWeb.UserSocket
      |> socket("user_id", %{some: :assign})
      |> subscribe_and_join(MunchkinServerWeb.RoomChannel, "room:lobby")

    player = %{"name" => "John", "gender" => "male", "power" => 10, "level" => 1}
    edited_player = %{"name" => "John", "gender" => "male", "power" => 20, "level" => 2}

    %{socket: socket, player: player, edited_player: edited_player}
  end

  test "ping replies with status ok", %{socket: socket} do
    reply = %{"ping" => "pong"}
    ref = push(socket, "ping", reply)
    assert_reply(ref, :ok, ^reply)
  end

  test "shout broadcasts to room:lobby", %{socket: socket} do
    push(socket, "shout", %{"hello" => "all"})
    assert_broadcast "shout", %{"hello" => "all"}
  end

  test "new_player broadcasts player creation", %{socket: socket, player: player} do
    push(socket, "new_player", player)
    assert_broadcast "create_player", ^player
  end

  test "edit_player broadcasts player update", %{socket: socket, edited_player: edited_player} do
    push(socket, "edit_player", edited_player)
    assert_broadcast "edited_player", ^edited_player
  end

  test "request_sync broadcasts players list", %{player: player} do
    {:ok, _, socket} =
      MunchkinServerWeb.UserSocket
      |> socket("user_id", %{some: :assign})
      |> subscribe_and_join(MunchkinServerWeb.RoomChannel, "room:test")

    push(socket, "new_player", player)

    push(socket, "request_sync", %{})

    assert_receive %Phoenix.Socket.Message{
      event: "synchronize",
      payload: %{
        "players" => [^player]
      }
    }
  end

  test "delete_player broadcasts player removal", %{socket: socket} do
    player_name = "John"
    push(socket, "delete_player", %{"name" => player_name})
    assert_broadcast "deleted_player", %{"name" => ^player_name}
  end

  test "reset_all_players resets player attributes and broadcasts them", %{
    socket: socket,
    player: player
  } do
    push(socket, "new_player", player)

    push(socket, "reset_all_players", %{})

    player_name = player["name"]
    player_gender = player["gender"]

    assert_receive %Phoenix.Socket.Message{
      event: "synchronize",
      payload: %{
        "players" => [
          %{"name" => ^player_name, "gender" => ^player_gender, "power" => 0, "level" => 1}
        ]
      }
    }
  end
end
