defmodule MunchkinServer.RoomTest do
  use ExUnit.Case
  alias MunchkinServer.{Room, RoomSupervisor}

  setup do
    # Ensure the Room agent is stopped before starting it
    if Process.whereis(:test) do
      Process.unregister(:test)
    end

    {:ok, room} =
      DynamicSupervisor.start_child(
        RoomSupervisor,
        {Room, name: :test, initial_state: []}
      )

    %{room: room}
  end

  test "get_room_state returns the current state of the room", %{room: room} do
    assert MunchkinServer.Room.get_room_state(room) == []
  end

  test "handler_add_player adds a player to the room state", %{room: room} do
    player = %{"name" => "John", "gender" => "male", "power" => 10, "level" => 1}
    MunchkinServer.Room.handler_add_player(room, player)
    assert MunchkinServer.Room.get_room_state(room) == [player]
  end

  test "handler_update_player updates a player in the room state", %{room: room} do
    player = %{"name" => "John", "gender" => "male", "power" => 10, "level" => 1}
    updated_player = %{"name" => "John", "gender" => "male", "power" => 20, "level" => 2}
    MunchkinServer.Room.handler_add_player(room, player)
    MunchkinServer.Room.handler_update_player(room, updated_player)
    assert MunchkinServer.Room.get_room_state(room) == [updated_player]
  end

  test "handler_delete_player removes a player from the room state", %{room: room} do
    player = %{"name" => "John", "gender" => "male", "power" => 10, "level" => 1}
    MunchkinServer.Room.handler_add_player(room, player)
    MunchkinServer.Room.handler_delete_player(room, %{"name" => "John"})
    assert MunchkinServer.Room.get_room_state(room) == []
  end

  test "reset_all_players resets all players' attributes", %{room: room} do
    player_1 = %{"name" => "John", "gender" => "male", "power" => 10, "level" => 3}
    player_2 = %{"name" => "Jane", "gender" => "female", "power" => 5, "level" => 2}

    MunchkinServer.Room.handler_add_player(room, player_1)
    MunchkinServer.Room.handler_add_player(room, player_2)

    MunchkinServer.Room.reset_all_players(room)

    reset_player_1 = %{"name" => "John", "gender" => "male", "power" => 0, "level" => 1}
    reset_player_2 = %{"name" => "Jane", "gender" => "female", "power" => 0, "level" => 1}

    assert Enum.sort(MunchkinServer.Room.get_room_state(room)) ==
             Enum.sort([reset_player_2, reset_player_1])
  end
end
