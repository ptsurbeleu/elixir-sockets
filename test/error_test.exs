defmodule Socket.ErrorTest do
  @moduledoc """

  NOTE: Check https://badssl.com for more options to generate actual TLS errors.
  """
  use ExUnit.Case

  # NOTE: TLS alerts are emitted via :logger and corrupt ExUnit's test result output.
  # Enabling this flag captures and suppresses them.
  @moduletag capture_log: true

  describe "Socket.Error.exception/1" do
    test "decodes a known POSIX atom" do
      err = Socket.Error.exception(reason: :econnrefused)
      assert err.message == "connection refused"
    end

    test "decodes a known SSL atom" do
      # Pick an atom recognized by SSL but not TCP's inet.format_error
      err = Socket.Error.exception(reason: :closed)
      assert err.message == "TLS connection is closed"
    end

    test "decodes TLS alert (:unknown_ca)" do
      # Empty cacerts will force the handshake to fail with TLS alert
      {:error, reason} = :ssl.connect(~c"google.com", 443, cacerts: [])
      err = Socket.Error.exception(reason: reason)

      assert err.message =~
               ~r"TLS client:\ In state wait_cert_cr at ssl_handshake.erl\:.* generated CLIENT ALERT\: Fatal - Unknown CA"
    end

    test "decodes TLS alert (:certificate_expired)" do
      {:error, reason} =
        :ssl.connect(~c"expired.badssl.com", 443, cacerts: :public_key.cacerts_get())

      err = Socket.Error.exception(reason: reason)

      assert err.message =~
               ~r"TLS client:\ In state certify at ssl_handshake.erl\:.* generated CLIENT ALERT\: Fatal - Certificate Expired"
    end

    test "extracts message from TLS alert tuple" do
      err =
        Socket.Error.exception(
          reason: {:tls_alert, {1, ~c"TLS Client: Something else gone wrong"}}
        )

      assert err.message == "TLS Client: Something else gone wrong"
    end

    test "falls back to atom string for unknown atom" do
      err = Socket.Error.exception(reason: :some_unknown_reason)
      assert err.message == "some_unknown_reason"
    end

    test "inspects arbitrary non-atom reasons" do
      err = Socket.Error.exception(reason: {:weird, :nested, 42})
      assert err.message == inspect({:weird, :nested, 42})
    end
  end
end
