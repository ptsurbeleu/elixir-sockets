defmodule Socket.AddressTest do
  use ExUnit.Case

  describe "Socket.Address.parse/1" do
    test "parses ipv4 loopback address from string" do
      ip = Socket.Address.parse("127.0.0.1")
      assert ip == {127, 0, 0, 1}
    end

    test "parses an ipv4 address from string" do
      ip = Socket.Address.parse("224.0.0.251")
      assert ip == {224, 0, 0, 251}
    end

    test "parses ipv6 loopback address from string (short version)" do
      ip = Socket.Address.parse("::1")
      assert ip == {0, 0, 0, 0, 0, 0, 0, 1}
    end

    test "parses ipv6 loopback address from string (full version)" do
      ip = Socket.Address.parse("0000:0000:0000:0000:0000:0000:0000:0001")
      assert ip == {0, 0, 0, 0, 0, 0, 0, 1}
    end

    test "parses an ipv6 address from string (short version)" do
      ip = Socket.Address.parse("ff02::fb")
      assert ip == {65_282, 0, 0, 0, 0, 0, 0, 251}
    end

    test "parses an ipv6 address from string" do
      ip = Socket.Address.parse("fe80::8b8:72ec:dd2f:1172")
      assert ip == {65_152, 0, 0, 0, 2232, 29_420, 56_623, 4466}
    end

    test "returns nil when ipv4 is wrong" do
      ip = Socket.Address.parse("257.192.0.10")
      assert ip == nil
    end

    test "returns nil when ipv6 is wrong" do
      ip = Socket.Address.parse("xy80::8b8:72ec:dd2f:1172")
      assert ip == nil
    end
  end

  describe "Socket.Address.valid?/1" do
    test "returns true for a valid ipv4 address",
      do: assert(Socket.Address.valid?("127.0.0.1") == true)

    test "returns false for an invalid ipv4 address",
      do: assert(Socket.Address.valid?("257.0.0.1") == false)

    test "returns true for a valid ipv6 address",
      do: assert(Socket.Address.valid?("fe80::8b8:72ec:dd2f:1172") == true)

    test "returns false for an invalid ipv6 address",
      do: assert(Socket.Address.valid?("xy80::8b8:72ec:dd2f:1172") == false)
  end

  describe "Socket.Address.for/2" do
    test "resolves string to valid ipv4 addresses",
      do: assert(Socket.Address.for("10.0.192.1.nip.io", :inet) == {:ok, [{10, 0, 192, 1}]})

    test "resolves charlist to valid ipv4 addresses",
      do: assert(Socket.Address.for(~c"10.0.192.1.nip.io", :inet) == {:ok, [{10, 0, 192, 1}]})

    test "resolves tuple to valid ipv4 addresses",
      do:
        assert(
          Socket.Address.for({10, 0, 192, 1}, :inet) ==
            {:ok, [{10, 0, 192, 1}]}
        )

    test "resolves string to valid ipv6 addresses",
      do:
        assert(
          Socket.Address.for("fe80--8b8-72ec-dd2f-1172.nip.io", :inet6) ==
            {:ok, [{65_152, 0, 0, 0, 2232, 29_420, 56_623, 4466}]}
        )

    test "resolves charlist to valid ipv6 addresses",
      do:
        assert(
          Socket.Address.for(~c"fe80--8b8-72ec-dd2f-1172.nip.io", :inet6) ==
            {:ok, [{65_152, 0, 0, 0, 2232, 29_420, 56_623, 4466}]}
        )

    test "resolves tuple to valid ipv6 addresses",
      do:
        assert(
          Socket.Address.for({65_152, 0, 0, 0, 2232, 29_420, 56_623, 4466}, :inet6) ==
            {:ok, [{65_152, 0, 0, 0, 2232, 29_420, 56_623, 4466}]}
        )
  end

  describe "Socket.Address.for!/2" do
    test "resolves hostname string to valid ipv4 addresses",
      do: assert(Socket.Address.for!("10.0.192.1.nip.io", :inet) == [{10, 0, 192, 1}])

    test "resolves hostname charlist to valid ipv4 addresses",
      do: assert(Socket.Address.for!(~c"10.0.192.1.nip.io", :inet) == [{10, 0, 192, 1}])

    test "resolves tuple to valid ipv4 addresses",
      do:
        assert(
          Socket.Address.for!({10, 0, 192, 1}, :inet) ==
            [{10, 0, 192, 1}]
        )

    test "resolves hostname string to valid ipv6 addresses",
      do:
        assert(
          Socket.Address.for!("fe80--8b8-72ec-dd2f-1172.nip.io", :inet6) ==
            [{0xFE80, 0, 0, 0, 0x8B8, 0x72EC, 0xDD2F, 0x1172}]
        )

    test "resolves hostname charlist to valid ipv6 addresses",
      do:
        assert(
          Socket.Address.for!(~c"fe80--8b8-72ec-dd2f-1172.nip.io", :inet6) ==
            [{0xFE80, 0, 0, 0, 0x8B8, 0x72EC, 0xDD2F, 0x1172}]
        )

    test "resolves tuple to valid ipv6 addresses",
      do:
        assert(
          Socket.Address.for!({0xFE80, 0, 0, 0, 0x08B8, 0x72EC, 0xDD2F, 0x1172}, :inet6) ==
            [{0xFE80, 0, 0, 0, 0x08B8, 0x72EC, 0xDD2F, 0x1172}]
        )
  end

  describe "Socket.Address.is_in_subnet?/3" do
    test "checks ip v4 is in the same subnet (h: 110 / n:24)",
      do: assert(Socket.Address.is_in_subnet?({192, 168, 0, 110}, {192, 168, 0, 0}, 24) == true)

    test "checks ip v4 is not in the same subnet (h: 110 / n:24)",
      do: assert(Socket.Address.is_in_subnet?({192, 168, 1, 110}, {192, 168, 0, 0}, 24) == false)

    test "checks ip v4 is in the same subnet (h: 116 / n:32)",
      do:
        assert(Socket.Address.is_in_subnet?({192, 168, 10, 116}, {192, 168, 10, 116}, 32) == true)

    test "checks ip v6 is in the same subnet (h: 0b1111_0001_0111_0010 / n:112)",
      do:
        assert(
          Socket.Address.is_in_subnet?(
            # ipaddr
            {0xFE80, 0, 0, 0, 0x08B8, 0x72EC, 0xDD2F, 0b1111_0001_0111_0010},
            # subnet
            {0xFE80, 0, 0, 0, 0x08B8, 0x72EC, 0xDD2F, 0b0000_0000_0000_0000},
            112
          ) == true
        )

    test "checks ip v6 is in the same subnet (h:0b0111_0001_0111_0010 / n:113)",
      do:
        assert(
          Socket.Address.is_in_subnet?(
            # ipaddr
            {0xFE80, 0, 0, 0, 0x08B8, 0x72EC, 0xDD2F, 0b0111_0001_0111_0010},
            # subnet
            {0xFE80, 0, 0, 0, 0x08B8, 0x72EC, 0xDD2F, 0b0000_0000_0000_0000},
            113
          ) == true
        )

    test "checks ip v6 is not in the same subnet (h:0b0111_0001_0111_0010 / n:113)",
      do:
        assert(
          Socket.Address.is_in_subnet?(
            # ipaddr
            {0xFE80, 0, 0, 0, 0x08B8, 0x72EC, 0xDD2F, 0b0111_0001_0111_0010},
            # subnet
            {0xFE80, 0, 0, 0, 0x08B8, 0x72EC, 0xDD2F, 0b1000_0000_0000_0000},
            113
          ) == false
        )

    test "checks ip v6 is in the same subnet (h:0x1fe7 / n:128)",
      do:
        assert(
          Socket.Address.is_in_subnet?(
            # ipaddr
            {0xFE80, 0, 0, 0, 0x08B8, 0x72EC, 0xDD2F, 0x1FE7},
            # subnet
            {0xFE80, 0, 0, 0, 0x08B8, 0x72EC, 0xDD2F, 0x1FE7},
            128
          ) == true
        )
  end
end
