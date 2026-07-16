defmodule Socket.HostTest do
  @moduledoc """
  Unit tests for Socket.Host module public API.

  NOTE: See "RFC2606 :: Section 2 - TLDs for Testing, & Documentation Examples" to
  clarify use of '.invalid' domain names in the test code.
  """
  use ExUnit.Case

  describe "Socket.Host.by_address/1" do
    test "resolves IPv4 loopback address" do
      {:ok, host} = Socket.Host.by_address("127.0.0.1")

      assert [{127, 0, 0, 1}] == host.list
      assert "localhost" == host.name
      assert :inet == host.type
      assert [] == host.aliases
      assert 4 == host.length
    end

    test "resolves IPv6 loopback address" do
      {:ok, host} = Socket.Host.by_address("::1")

      # NOTE: In some evironments ::1 is resolved into 'ipv6-localhost' while others resolve it into 'localhost'
      assert host.name in ["ip6-localhost", "localhost"]
      assert [{0, 0, 0, 0, 0, 0, 0, 1}] == host.list
      assert :inet6 == host.type
      assert [] == host.aliases
      assert 16 == host.length
    end

    test "returns error for address with no reverse DNS record" do
      # An attempt to resolve broadcast IP should always fail
      assert {:error, _} = Socket.Host.by_address("255.255.255.255")
    end
  end

  describe "Socket.Host.by_address!/1" do
    test "resolves IPv4 loopback address" do
      host = Socket.Host.by_address!("127.0.0.1")

      assert [{127, 0, 0, 1}] == host.list
      assert "localhost" == host.name
      assert :inet == host.type
      assert [] == host.aliases
      assert 4 == host.length
    end

    test "raises Socket.Error for address with no reverse DNS record" do
      # An attempt to resolve broadcast IP should always fail
      assert_raise Socket.Error, fn ->
        Socket.Host.by_address!("255.255.255.255")
      end
    end
  end

  describe "Socket.Host.by_name/2" do
    test "resolves 10.84.201.37.nip.io with :inet family" do
      {:ok, host} = Socket.Host.by_name("10.84.201.37.nip.io", :inet)

      assert [{10, 84, 201, 37}] == host.list
      assert "10.84.201.37.nip.io" == host.name
      assert :inet == host.type
      assert [] == host.aliases
      assert 4 == host.length
    end

    test "returns error for non-existent hostname" do
      # An attempt to resolve an invalid hostname always fail
      assert {:error, _reason} =
               Socket.Host.by_name("nonexistent.invalid", :inet)
    end
  end

  describe "Socket.Host.by_name/1" do
    test "resolves 172.19.133.62.nip.io defaulting to :inet" do
      {:ok, host} = Socket.Host.by_name("172.19.133.62.nip.io")

      assert [{172, 19, 133, 62}] == host.list
      assert "172.19.133.62.nip.io" == host.name
      assert :inet == host.type
      assert [] == host.aliases
      assert 4 == host.length
    end

    test "returns error for non-existent hostname" do
      # An attempt to resolve an invalid hostname always fail
      assert {:error, _reason} = Socket.Host.by_name("nonexistent.invalid")
    end
  end

  describe "Socket.Host.by_name!/2" do
    test "resolves '192.168.10.112.nip.io' with :inet family" do
      host = Socket.Host.by_name!("192.168.10.112.nip.io", :inet)

      assert [{192, 168, 10, 112}] == host.list
      assert "192.168.10.112.nip.io" == host.name
      assert :inet == host.type
      assert [] == host.aliases
      assert 4 == host.length
    end

    test "raises Socket.Error for non-existent hostname" do
      # An attempt to resolve an invalid hostname always fail
      assert_raise Socket.Error, fn ->
        Socket.Host.by_name!("nonexistent.invalid", :inet)
      end
    end
  end

  describe "Socket.Host.by_name!/1" do
    test "resolves 192.168.47.213.sslip.io" do
      host = Socket.Host.by_name!("192.168.47.213.nip.io")

      assert [{192, 168, 47, 213}] == host.list
      assert "192.168.47.213.nip.io" == host.name
      assert :inet == host.type
      assert [] == host.aliases
      assert 4 == host.length
    end

    test "raises Socket.Error for non-existent hostname" do
      # An attempt to resolve an invalid hostname always fail
      assert_raise Socket.Error, fn ->
        Socket.Host.by_name!("nonexistent.invalid")
      end
    end
  end

  describe "Socket.Host.name/0" do
    test "returns the local machine hostname" do
      # NOTE: 64 should be enough to read a hostname without truncating it,
      # since hostname is 64 bytes long (obtained via 'getconf HOST_NAME_MAX')
      {hostname, 0} = System.cmd("hostname", [], lines: 64)

      assert hostname == Socket.Host.name()
    end
  end

  describe "Socket.Host.interfaces/0" do
    test "returns an equivalent list of network interfaces" do
      expected =
        System.cmd("ls", ["/sys/class/net"])
        |> then(fn {stdout, 0} -> stdout end)
        |> String.split("\n", trim: true)
        |> Enum.sort()

      actual =
        Socket.Host.interfaces()
        |> then(fn {:ok, interfaces} -> interfaces end)
        |> Enum.map(fn {name, _opts} -> to_string(name) end)
        |> Enum.sort()

      # NOTE: Sorted output should be equivalent given both calls
      # produce exactly the same output
      assert expected == actual
    end
  end

  describe "Socket.Host.interfaces!/0" do
    test "returns an equivalent list of network interfaces" do
      expected =
        System.cmd("ls", ["/sys/class/net"])
        |> then(fn {stdout, 0} -> stdout end)
        |> String.split("\n", trim: true)
        |> Enum.sort()

      actual =
        Socket.Host.interfaces!()
        |> Enum.map(fn {name, _opts} -> to_string(name) end)
        |> Enum.sort()

      # NOTE: Sorted output should be equivalent given both calls
      # produce exactly the same output
      assert expected == actual
    end
  end
end
