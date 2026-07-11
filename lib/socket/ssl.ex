#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Socket.SSL do
  @moduledoc """
  This module allows usage of SSL sockets and promotion of TCP sockets to SSL
  sockets.

  ## Options

  When creating a socket you can pass a series of options to use for it.

  * `:cert` can either be an encoded certificate or `[path:
    "path/to/certificate"]`
  * `:key` can either be an encoded certificate, `[path: "path/to/key"]`, `[rsa:
    "rsa encoded"]` or `[dsa: "dsa encoded"]` or `[ec: "ec encoded"]`
  * `:authorities` can iehter be an encoded authorities or `[path:
    "path/to/authorities"]`
  * `:dh` can either be an encoded dh or `[path: "path/to/dh"]`
  * `:verify` can either be `false` to disable peer certificate verification,
    or a keyword list containing a `:function` and an optional `:data`
  * `:cacerts` can be a custom list of certificates to accept during
    certificate verification
  * `:password` the password to use to decrypt certificates
  * `:renegotiation` if it's set to `:secure` renegotiation will be secured
  * `:ciphers` is a list of ciphers to allow
  * `:advertised_protocols` is a list of strings representing the advertised
    protocols for NPN
  * `:preferred_protocols` is a list of strings representing the preferred next
    protocols for NPN

  You can also pass TCP options.

  ## Smart garbage collection

  Normally sockets in Erlang are closed when the controlling process exits,
  with smart garbage collection the controlling process will be the
  `Socket.Manager` and it will be closed when there are no more references to
  it.
  """

  use Socket.Helpers
  require Record

  @type t :: Socket.SSL.t()
  @type error :: nil | String.t()
  @type sslsocket :: :ssl.sslsocket()

  @doc """
  Get the list of supported ciphers.
  """
  @spec ciphers(:ssl.protocol_version()) :: :ssl.ciphers()
  def ciphers(version \\ :"tlsv1.3") do
    :ssl.cipher_suites(:all, version)
  end

  @doc """
  Get the list of supported SSL/TLS versions.
  """
  @spec versions :: [tuple]
  def versions do
    :ssl.versions()
  end

  @doc """
  Return a proper error string for the given code or nil if it can't be
  converted.

  NOTE: :ssl.format_error/1 delegates to :inet.format_error/1 internally,
  so POSIX error codes are decoded successfully. Callers must not assume a
  POSIX error code will produce ~c"Unexpected error: <code>".
  """
  @spec error(term) :: String.t() | nil
  def error(code) do
    case :ssl.format_error(code) do
      ~c"Unexpected error:" ++ _ ->
        nil

      message ->
        message |> to_string
    end
  end

  @doc """
  Connect to the given address and port tuple or SSL connect the given socket.
  """
  @spec connect({Socket.Address.t(), :inet.port_number()}) ::
          {:ok, sslsocket} | {:ok, sslsocket, :ssl.protocol_extensions()} | {:error, term}
  def connect({address, port}) do
    connect(address, port)
  end

  @spec connect(Socket.t()) ::
          {:ok, sslsocket} | {:ok, sslsocket, :ssl.protocol_extensions()} | {:error, term}
  def connect(socket) do
    connect(socket, [])
  end

  @doc """
  Connect to the given address and port tuple or SSL connect the given socket,
  raising if an error occurs.
  """
  @spec connect!(Socket.Address.t(), :inet.port_number()) ::
          sslsocket | {sslsocket, :ssl.protocol_extensions()}
  def connect!(address, port) when is_integer(port) do
    case connect(address, port) do
      {:ok, socket} ->
        socket

      {:ok, socket, extensions} ->
        {socket, extensions}

      {:error, reason} ->
        raise Socket.Error, reason: reason
    end
  end

  @spec connect!({Socket.Address.t(), :inet.port_number()}, Keyword.t()) ::
          sslsocket | {sslsocket, :ssl.protocol_extensions()}
  def connect!({address, port}, options) when options |> is_list do
    case connect(address, port, options) do
      {:ok, socket} ->
        socket

      {:ok, socket, extensions} ->
        {socket, extensions}

      {:error, reason} ->
        raise Socket.Error, reason: reason
    end
  end

  @doc """
  Connect to the given address and port tuple with the given options or SSL
  connect the given socket with the given options or connect to the given
  address and port.
  """
  @spec connect({Socket.Address.t(), :inet.port_number()}, Keyword.t()) ::
          {:ok, sslsocket} | {:ok, sslsocket, :ssl.protocol_extensions()} | {:error, term}
  def connect({address, port}, options) when options |> is_list do
    connect(address, port, options)
  end

  @spec connect(Socket.Port.t() | port, Keyword.t()) ::
          {:ok, sslsocket} | {:ok, sslsocket, :ssl.protocol_extensions()} | {:error, term}
  def connect(wrap, options) when options |> is_list do
    # Extract raw Erlang port from either a Socket.Port struct or a bare port
    socket =
      case wrap do
        %Socket.Port{port: raw} -> raw
        raw when is_port(raw) -> raw
      end

    timeout = options[:timeout] || :infinity

    options =
      options
      |> Keyword.delete(:timeout)
      |> Keyword.put_new_lazy(:cacerts, fn -> :public_key.cacerts_get() end)
      |> Keyword.put_new(:verify, true)

    :ssl.connect(socket, options, timeout)
  end

  @spec connect(Socket.Address.t(), :inet.port_number()) ::
          {:ok, sslsocket} | {:ok, sslsocket, :ssl.protocol_extensions()} | {:error, term}
  def connect(address, port) when port |> is_integer do
    connect(address, port, [])
  end

  @doc """
  Connect to the given address and port with the given options.
  """
  @spec connect(Socket.Address.t(), :inet.port_number(), Keyword.t()) ::
          {:ok, sslsocket} | {:ok, sslsocket, :ssl.protocol_extensions()} | {:error, term}
  def connect(address, port, options) do
    address =
      if address |> is_binary do
        String.to_charlist(address)
      else
        address
      end

    timeout = options[:timeout] || :infinity

    options =
      options
      |> Keyword.delete(:timeout)
      |> Keyword.put_new_lazy(:cacerts, fn -> :public_key.cacerts_get() end)
      |> Keyword.put_new(:verify, true)

    :ssl.connect(address, port, arguments(options), timeout)
  end

  @doc """
  Connect to the given address and port with the given options, raising if an
  error occurs.
  """
  @spec connect!(Socket.Address.t(), :inet.port_number(), Keyword.t()) ::
          sslsocket | {sslsocket, :ssl.protocol_extensions()}
  def connect!(address, port, options) do
    case connect(address, port, options) do
      {:ok, socket} ->
        socket

      {:ok, socket, extensions} ->
        {socket, extensions}

      {:error, reason} ->
        raise Socket.Error, reason: reason
    end
  end

  @doc """
  Create an SSL socket listening on an OS chosen port, use `local` to know the
  port it was bound on.
  """
  @spec listen :: {:ok, sslsocket} | {:error, term}
  def listen do
    listen(0, [])
  end

  @doc """
  Create an SSL socket listening on an OS chosen port, use `local` to know the
  port it was bound on, raising in case of error.
  """
  @spec listen! :: sslsocket
  defbang(listen)

  @doc """
  Create an SSL socket listening on an OS chosen port using the given options or
  listening on the given port.
  """
  @spec listen(:inet.port_number()) :: {:ok, sslsocket} | {:error, term}
  def listen(port) when port |> is_integer do
    listen(port, [])
  end

  @spec listen(Keyword.t()) :: {:ok, sslsocket} | {:error, term}
  def listen(options) do
    listen(0, options)
  end

  @doc """
  Create an SSL socket listening on an OS chosen port using the given options
  or listening on the given port, raising in case of error.
  """
  @spec listen!(:inet.port_number() | Keyword.t()) :: sslsocket
  defbang(listen(port_or_options))

  @doc """
  Create an SSL socket listening on the given port and using the given options.
  """
  @spec listen(:inet.port_number(), Keyword.t()) :: {:ok, sslsocket} | {:error, term}
  def listen(port, options) do
    options = Keyword.put(options, :mode, :passive)
    options = Keyword.put_new(options, :reuse, true)

    :ssl.listen(port, arguments(options))
  end

  @doc """
  Create an SSL socket listening on the given port and using the given options,
  raising in case of error.
  """
  @spec listen!(:inet.port_number(), Keyword.t()) :: sslsocket
  defbang(listen(port, options))

  @doc """
  Accept a connection from a listening SSL socket or start an SSL connection on
  the given client socket.
  """
  @spec accept(Socket.t() | t) :: {:ok, sslsocket} | {:error, term}
  def accept(self) do
    accept(self, [])
  end

  @doc """
  Accept a connection from a listening SSL socket or start an SSL connection on
  the given client socket, raising if an error occurs.
  """
  @spec accept!(Socket.t() | t) :: sslsocket
  defbang(accept(socket))

  @doc """
  Accept a connection from a listening SSL socket with the given options or
  start an SSL connection on the given client socket with the given options.
  """
  @spec accept(Socket.t(), Keyword.t()) :: {:ok, sslsocket} | {:error, term}
  def accept(socket, options) when socket |> Record.is_record(:sslsocket) do
    timeout = options[:timeout] || :infinity

    with {:ok, socket} <- socket |> :ssl.transport_accept(timeout),
         :ok <-
           if(options[:mode] == :active, do: socket |> :ssl.setopts([{:active, true}]), else: :ok),
         {:ok, socket} <- socket |> handshake(timeout: timeout) do
      {:ok, socket}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def accept(wrap, options) when wrap |> is_port do
    timeout = options[:timeout] || :infinity
    options = Keyword.delete(options, :timeout)

    :ssl.handshake(wrap, arguments(options), timeout)
  end

  @doc """
  Accept a connection from a listening SSL socket with the given options or
  start an SSL connection on the given client socket with the given options,
  raising if an error occurs.
  """
  @spec accept!(Socket.t(), Keyword.t()) :: sslsocket
  def accept!(socket, options) do
    case accept(socket, options) do
      {:ok, socket} ->
        socket

      {:error, reason} ->
        raise Socket.Error, reason: reason
    end
  end

  @doc """
  Execute the handshake; useful if you want to delay the handshake to make it
  in another process.
  """
  @spec handshake(sslsocket) ::
          {:ok, sslsocket} | {:ok, sslsocket, :ssl.protocol_extensions()} | {:error, term}
  @spec handshake(sslsocket, Keyword.t()) ::
          {:ok, sslsocket} | {:ok, sslsocket, :ssl.protocol_extensions()} | {:error, term}
  def handshake(socket, options \\ []) when socket |> Record.is_record(:sslsocket) do
    timeout = options[:timeout] || :infinity

    :ssl.handshake(socket, timeout)
  end

  @doc """
  Execute the handshake, raising if an error occurs; useful if you want to
  delay the handshake to make it in another process.
  """
  @spec handshake!(sslsocket) :: sslsocket | {sslsocket, :ssl.protocol_extensions()}
  @spec handshake!(sslsocket, Keyword.t()) :: sslsocket | {sslsocket, :ssl.protocol_extensions()}
  def handshake!(socket, options \\ []) do
    case handshake(socket, options) do
      {:ok, socket} ->
        socket

      {:ok, socket, extensions} ->
        {socket, extensions}

      {:error, reason} ->
        raise Socket.Error, reason: reason
    end
  end

  @doc """
  Set the process which will receive the messages.
  """
  @spec process(sslsocket | port, pid) :: :ok | {:error, :closed | :not_owner | term}
  def process(socket, pid) when socket |> Record.is_record(:sslsocket) do
    :ssl.controlling_process(socket, pid)
  end

  @doc """
  Set the process which will receive the messages, raising if an error occurs.
  """
  @spec process!(sslsocket | port, pid) :: :ok
  def process!(socket, pid) do
    case process(socket, pid) do
      :ok ->
        :ok

      {:error, :closed} ->
        raise RuntimeError, message: "the socket is closed"

      {:error, :not_owner} ->
        raise RuntimeError, message: "the current process isn't the owner"

      {:error, code} ->
        raise Socket.Error, reason: code
    end
  end

  @doc """
  Set options of the socket.
  """
  @spec options(sslsocket, Keyword.t()) :: :ok | {:error, :ssl.reason()}
  def options(socket, options) when socket |> Record.is_record(:sslsocket) do
    :ssl.setopts(socket, arguments(options))
  end

  @doc """
  Set options of the socket, raising if an error occurs.
  """
  @spec options!(sslsocket, Keyword.t()) :: :ok
  defbang(options(socket, options))

  @doc """
  Convert SSL options to `:ssl.setopts` compatible arguments.
  """
  @spec arguments(Keyword.t()) :: list
  def arguments(options) do
    options =
      Enum.group_by(options, fn
        {:server_name, _} -> true
        {:cert, _} -> true
        {:key, _} -> true
        {:authorities, _} -> true
        {:sni, _} -> true
        {:dh, _} -> true
        {:cacerts, _} -> true
        {:verify, _} -> true
        {:password, _} -> true
        {:renegotiation, _} -> true
        {:ciphers, _} -> true
        {:depth, _} -> true
        {:identity, _} -> true
        {:versions, _} -> true
        {:alert, _} -> true
        {:hibernate, _} -> true
        {:session, _} -> true
        {:advertised_protocols, _} -> true
        {:preferred_protocols, _} -> true
        _ -> false
      end)

    {local, global} = {
      Map.get(options, true, []),
      Map.get(options, false, [])
    }

    Socket.TCP.arguments(global) ++
      Enum.flat_map(local, fn
        {:server_name, false} ->
          [{:server_name_indication, :disable}]

        {:server_name, name} ->
          [
            {:server_name_indication, String.to_charlist(name)},
            wildcard_fix()
          ]

        {:cert, [path: path]} ->
          [{:certfile, path}]

        {:cert, cert} ->
          [{:cert, cert}]

        {:key, [path: path]} ->
          [{:keyfile, path}]

        {:key, [rsa: key]} ->
          [{:key, {:RSAPrivateKey, key}}]

        {:key, [dsa: key]} ->
          [{:key, {:DSAPrivateKey, key}}]

        {:key, [ec: key]} ->
          [{:key, {:ECPrivateKey, key}}]

        {:key, key} ->
          [{:key, {:PrivateKeyInfo, key}}]

        {:authorities, [path: path]} ->
          [{:cacertfile, path}]

        {:authorities, ca} ->
          [{:cacerts, ca}]

        {:dh, [path: path]} ->
          [{:dhfile, path}]

        {:dh, dh} ->
          [{:dh, dh}]

        {:sni, sni} ->
          Enum.flat_map(sni, fn
            {:hosts, hosts} ->
              [
                {:sni_hosts,
                 Enum.map(hosts, fn {name, options} ->
                   {String.to_charlist(name), arguments(options)}
                 end)}
              ]

            {:function, fun} ->
              [{:sni_fun, fun}]
          end)

        {:cacerts, certs} ->
          [{:cacerts, certs}]

        {:verify, true} ->
          [{:verify, :verify_peer}, wildcard_fix()]

        {:verify, false} ->
          [{:verify, :verify_none}]

        {:verify, [function: fun]} ->
          [{:verify, :verify_peer}, {:verify_fun, {fun, nil}}, wildcard_fix()]

        {:verify, [function: fun, data: data]} ->
          [{:verify, :verify_peer}, {:verify_fun, {fun, data}}, wildcard_fix()]

        {:identity, identity} ->
          Enum.flat_map(identity, fn
            {:psk, value} ->
              [{:psk_identity, String.to_charlist(value)}]

            {:srp, {first, second}} ->
              [{:srp_identity, {String.to_charlist(first), String.to_charlist(second)}}]
          end)

        {:password, password} ->
          [{:password, String.to_charlist(password)}]

        {:renegotiation, :secure} ->
          [{:secure_renegotiate, true}]

        {:ciphers, ciphers} ->
          [{:ciphers, ciphers}]

        {:depth, depth} ->
          [{:depth, depth}]

        {:versions, versions} ->
          [{:versions, versions}]

        {:alert, value} ->
          [{:log_alert, value}]

        {:hibernate, hibernate} ->
          [{:hibernate_after, hibernate}]

        {:session, session} ->
          Enum.flat_map(session, fn
            {:reuse, true} ->
              [{:reuse_sessions, true}]

            {:reuse, false} ->
              [{:reuse_sessions, false}]

            {:reuse, fun} when fun |> is_function ->
              [{:reuse_session, fun}]
          end)

        {:advertised_protocols, protocols} ->
          [{:next_protocols_advertised, protocols}]

        {:preferred_protocols, protocols} ->
          [{:client_preferred_next_protocols, protocols}]
      end)
  end

  @doc """
  Get information about the SSL connection.
  """
  @spec info(sslsocket) :: {:ok, :ssl.connection_info()} | {:error, :ssl.reason()}
  def info(socket) when socket |> Record.is_record(:sslsocket) do
    :ssl.connection_information(socket)
  end

  @doc """
  Get information about the SSL connection, raising if an error occurs.
  """
  @spec info!(sslsocket) :: :ssl.connection_info()
  defbang(info(socket))

  @doc """
  Get the certificate of the peer.
  """
  @spec certificate(sslsocket) :: {:ok, :public_key.der_encoded()} | {:error, :ssl.reason()}
  def certificate(socket) when socket |> Record.is_record(:sslsocket) do
    :ssl.peercert(socket)
  end

  @doc """
  Get the certificate of the peer, raising if an error occurs.
  """
  @spec certificate!(sslsocket) :: :public_key.der_encoded()
  defbang(certificate(socket))

  @doc """
  Get the negotiated protocol.
  """
  @spec negotiated_protocol(sslsocket) :: binary()
  def negotiated_protocol(socket) when socket |> Record.is_record(:sslsocket) do
    case :ssl.negotiated_protocol(socket) do
      {:ok, protocol} ->
        protocol

      {:error, reason} ->
        raise Socket.Error, reason: reason
    end
  end

  @doc """
  Renegotiate the secure connection.
  """
  @spec renegotiate(sslsocket) :: :ok | {:error, :ssl.reason()}
  def renegotiate(socket) when socket |> Record.is_record(:sslsocket) do
    :ssl.renegotiate(socket)
  end

  @doc """
  Renegotiate the secure connection, raising if an error occurs.
  """
  @spec renegotiate!(sslsocket) :: :ok
  defbang(renegotiate(socket))

  defp wildcard_fix do
    # Without this Erlang doesn't accept wildcards SSL certificate alternative names.
    # https://github.com/erlang/otp/issues/4321
    {:customize_hostname_check, [match_fun: :public_key.pkix_verify_hostname_match_fun(:https)]}
  end
end
