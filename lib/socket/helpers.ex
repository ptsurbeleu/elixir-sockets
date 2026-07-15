defmodule Socket.Helpers do
  @moduledoc """
  A collection of macros that reduce boilerplate across the socket modules.
  """
  defmacro __using__(_opts) do
    quote do
      import Socket.Helpers
    end
  end

  @doc """
  Returns true if `host` is a valid IPv4 address represented as a 4-element tuple
  where each element is an integer in the range 0..255, e.g. `{192, 168, 1, 1}`.
  """
  @spec is_ipv4_address(tuple()) :: boolean()
  defguard is_ipv4_address(host)
           when host |> is_tuple() and tuple_size(host) == 4 and
                  elem(host, 0) in 0..255 and
                  elem(host, 1) in 0..255 and
                  elem(host, 2) in 0..255 and
                  elem(host, 3) in 0..255

  @doc """
  Returns true if `host` is a valid IPv6 address represented as an 8-element tuple
  where each element is an integer in the range 0..65535, e.g. `{8193, 3512, 0, 0, 0, 0, 0, 1}`.
  """
  @spec is_ipv6_address(tuple()) :: boolean()
  defguard is_ipv6_address(host)
           when host |> is_tuple() and tuple_size(host) == 8 and
                  elem(host, 0) in 0..65_535 and
                  elem(host, 1) in 0..65_535 and
                  elem(host, 2) in 0..65_535 and
                  elem(host, 3) in 0..65_535 and
                  elem(host, 4) in 0..65_535 and
                  elem(host, 5) in 0..65_535 and
                  elem(host, 6) in 0..65_535 and
                  elem(host, 7) in 0..65_535

  @doc """
  Returns true if `host` is a valid IPv4 or IPv6 address tuple. See `is_ipv4_address/1`
  and `is_ipv6_address/1` for the exact constraints on each format.
  """
  defguard is_ip_address(host) when is_ipv4_address(host) or is_ipv6_address(host)

  defmacro defbang({name, _, args}) do
    args = if is_list(args), do: args, else: []

    quote generated: true, bind_quoted: [name: Macro.escape(name), args: Macro.escape(args)] do
      def unquote((to_string(name) <> "!") |> String.to_atom())(unquote_splicing(args)) do
        case unquote(name)(unquote_splicing(args)) do
          :ok ->
            :ok

          {:ok, result} ->
            result

          {:error, reason} ->
            raise Socket.Error, reason: reason
        end
      end
    end
  end

  defmacro defbang({name, _, args}, to: mod) do
    args = if is_list(args), do: args, else: []

    quote generated: true,
          bind_quoted: [
            mod: Macro.escape(mod),
            name: Macro.escape(name),
            args: Macro.escape(args)
          ] do
      def unquote((to_string(name) <> "!") |> String.to_atom())(unquote_splicing(args)) do
        case unquote(mod).unquote(name)(unquote_splicing(args)) do
          :ok ->
            :ok

          {:ok, result} ->
            result

          {:error, reason} ->
            raise Socket.Error, reason: reason
        end
      end
    end
  end

  defmacro defwrap({name, _, [self | args]}, options \\ []) do
    if instance = options[:to] do
      quote bind_quoted: [
              name: Macro.escape(name),
              self: Macro.escape(self),
              args: Macro.escape(args),
              instance: Macro.escape(instance),
              field: options[:field] || :socket
            ] do
        def unquote(name)(unquote(self), unquote_splicing(args)) do
          unquote(self).unquote(field)
          |> @protocol.unquote(instance).unquote(name)(unquote_splicing(args))
        end
      end
    else
      quote bind_quoted: [
              name: Macro.escape(name),
              self: Macro.escape(self),
              args: Macro.escape(args),
              field: options[:field] || :socket
            ] do
        def unquote(name)(unquote(self), unquote_splicing(args)) do
          unquote(self).unquote(field) |> @protocol.unquote(name)(unquote_splicing(args))
        end
      end
    end
  end

  defmacro definvalid({name, _, args}) do
    args =
      if args |> is_list do
        for {_, meta, context} <- args do
          {:_, meta, context}
        end
      else
        []
      end

    quote do
      def unquote(name)(unquote_splicing(args)) do
        {:error, :einval}
      end
    end
  end
end
