defmodule Socket.Effects.SSL do
  use Efx

  @typedoc """
  Represents an error term as returned by `:ssl` functions.

  Covers both raw atoms, improper lists, and structured tuples from the Erlang
  `:ssl` module, including TLS alert terms and option-validation errors.
  """
  @type ssl_error() ::
          atom()
          | maybe_improper_list()
          | {:error,
             atom()
             | maybe_improper_list()
             | {:options, any()}
             | {:tls_alert, {any(), any()}}
             | {:option, any(), any()}
             | {:options, any(), any()}}
          | {:options, any()}
          | {:tls_alert, {any(), any()}}
          | {:option, any(), any()}
          | {:options, any(), any()}

  @typedoc """
  Reason term returned in `{:error, reason}` tuples by SSL operations.

  - `:closed` — the connection was closed before the operation completed
  - `:timeout` — the operation exceeded its allowed time
  - `{:options, any()}` — an invalid or unsupported option was supplied
  - `:ssl.error_alert()` — a TLS alert received from the peer
  - `:ssl.reason()` — any other reason surfaced by the Erlang `:ssl` module
  """
  @type ssl_reason() ::
          :closed | :timeout | {:options, any()} | :ssl.error_alert() | :ssl.reason()

  @typedoc """
  SSL socket or host.

  - `:ssl.sslsocket()` — an existing TCP socket to upgrade to TLS
  - `:ssl.host()` — a hostname to open a new TLS connection to
  """
  @type ssl_socket_or_host() :: :ssl.sslsocket() | :ssl.host()

  @typedoc """
  SSL/TLS options or port number.

  - `[:ssl.tls_client_option()]` — TLS options when upgrading an existing socket
  - `:inet.port_number()` — destination port when connecting by hostname
  """
  @type ssl_tls_options_or_port() :: [:ssl.tls_client_option()] | :inet.port_number()

  @typedoc """
  TLS options or timeout.

  - `[:ssl.tls_client_option()]` — TLS options when the second argument is a port number
  - `timeout()` — operation timeout when upgrading an existing socket
  """
  @type ssl_timeout_or_tls_options() :: [:ssl.tls_client_option()] | timeout()

  @doc """
  Get the list of supported SSL/TLS versions.

  NOTE: Typespec returns a list of tuples, since Erlang does not export the `:ssl.version()` type, hence used the most generic `tuple()` type that was compliant.
  """
  @spec versions() :: [tuple()]
  delegateeffect versions(), to: :ssl

  @doc """
  Presents the error returned by an SSL function as a printable string.
  """
  @spec format_error(ssl_error()) :: charlist()
  delegateeffect format_error(error), to: :ssl

  @doc """
  Get the list of supported ciphers.
  """
  @spec cipher_suites(atom(), :ssl.protocol_version()) :: :ssl.ciphers()
  delegateeffect cipher_suites(description, version), to: :ssl

  @doc """
  Opens a TLS/DTLS connection.
  """
  @spec connect(ssl_socket_or_host(), ssl_tls_options_or_port(), ssl_timeout_or_tls_options()) ::
          {:ok, :ssl.sslsocket()}
          | {:ok, :ssl.sslsocket(), :ssl.protocol_extensions()}
          | {:error, ssl_reason()}
  delegateeffect connect(socket, options, timeout), to: :ssl

  @doc """
  Opens a TLS/DTLS connection to address, port.
  """
  @spec connect(:ssl.host(), :inet.port_number(), [:ssl.tls_client_option()], timeout()) ::
          {:ok, :ssl.sslsocket()}
          | {:ok, :ssl.sslsocket(), :ssl.protocol_extensions()}
          | {:error, ssl_reason()}
  delegateeffect connect(address, port, options, timeout), to: :ssl

  @doc """
  Creates an SSL listen socket.
  """
  @spec listen(:inet.port_number(), [:ssl.tls_client_option()]) ::
          {:ok, :ssl.sslsocket()} | {:error, {:options, any()} | :ssl.reason()}
  delegateeffect listen(port, options), to: :ssl

  @doc """
  Accepts an incoming connection request on a listen socket.
  """
  @spec transport_accept(:ssl.sslsocket(), timeout()) ::
          {:ok, :ssl.sslsocket()} | {:error, :ssl.reason()}
  delegateeffect transport_accept(socket, timeout), to: :ssl

  @doc """
  Sets options according to 'options' for 'socket'.
  """
  @spec setopts(:ssl.sslsocket(), [:gen_tcp.option()]) ::
          :ok | {:error, :ssl.reason()}
  delegateeffect setopts(socket, options), to: :ssl

  @doc """
    See `:ssl.handshake/2` in the Erlang docs: `e::ssl.handshake/2`.

    NOTE: Since `:ssl.server_option()` is not exported by Erlang, the `:ssl.tls_server_option()` type is used instead.
    This is a superset of the server options, and will be accepted by `:ssl.handshake/2` as well.
  """
  @spec handshake(:ssl.sslsocket(), timeout() | [:ssl.tls_server_option()]) ::
          {:ok, :ssl.sslsocket()}
          | {:ok, :ssl.sslsocket(), :ssl.protocol_extensions()}
          | {:error, ssl_reason()}
  delegateeffect handshake(socket, optionsOrTimeout), to: :ssl
end
