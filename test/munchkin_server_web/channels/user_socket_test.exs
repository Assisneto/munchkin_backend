defmodule MunchkinServerWeb.UserSocketTest do
  use MunchkinServerWeb.ChannelCase
  alias MunchkinServerWeb.UserSocket

  describe "connect/3" do
    test "can be connected to without parameters" do
      assert {:ok, %Phoenix.Socket{}} = connect(UserSocket, %{})
    end
  end

  setup do
    {:ok, socket} = connect(UserSocket, %{})

    %{socket: socket}
  end

  test "channel can be joined" do
    assert {:ok, _, %Phoenix.Socket{}} =
             socket(UserSocket, nil, %{})
             |> subscribe_and_join("room:test", %{test: "Test"})
  end

  test "handle_in ping" do
    assert {:ok, _, socket} =
             socket(UserSocket, nil, %{})
             |> subscribe_and_join("room:test", %{test: "Test"})

    reply = %{"ping" => "pong"}
    ref = push(socket, "ping", reply)
    assert_reply(ref, :ok, ^reply)
  end

  test "join in two topics" do
    assert {:ok, _, _socket} =
             socket(UserSocket, nil, %{})
             |> subscribe_and_join("room:test", %{test: "Test"})

    assert {:ok, _, _socket} =
             socket(UserSocket, nil, %{})
             |> subscribe_and_join("room:another", %{test: "Test"})
  end
end
