defmodule Plug.AccessLog.DefaultFormatter do
  @moduledoc """
  Default log message formatter.
  """

  alias Plug.AccessLog.DefaultFormatter

  @behaviour Plug.AccessLog.Formatter

  @doc """
  Formats a log message.

  The following formatting directives are available:

  - `%%` - Percentage sign
  - `%a` - Remote IP-address
  - `%b` - Size of response in bytes. Outputs "-" when no bytes are sent.
  - `%B` - Size of response in bytes. Outputs "0" when no bytes are sent.
  - `%{VARNAME}C` - Cookie sent by the client
  - `%D` - Time taken to serve the request (microseconds)
  - `%h` - Remote hostname
  - `%{VARNAME}i` - Header line sent by the client
  - `%l` - Remote logname
  - `%m` - Request method
  - `%M` - Time taken to serve the request (milliseconds)
  - `%{VARNAME}o` - Header line sent by the server
  - `%q` - Query string (prepended with "?" or empty string)
  - `%r` - First line of HTTP request
  - `%>s` - Response status code
  - `%t` - Time the request was received in the format `[10/Jan/2015:14:46:18 +0100]`
  - `%T` - Time taken to serve the request (full seconds)
  - `%u` - Remote user
  - `%U` - URL path requested (without query string)
  - `%v` - Server name
  - `%V` - Server name (canonical)

  **Note for %b and %B**: To determine the size of the response the
  "Content-Length" will be inspected and, if available, returned
  unverified. If the header is not present the response body will be
  inspected using `byte_size/1`.

  **Note for %h**: The hostname will always be the ip of the client (same as `%a`).

  **Note for %l**: Always a dash ("-").

  **Note for %r**: For now the http version is always logged as "HTTP/1.1",
  regardless of the true http version.

  **Note for %T**: Rounding happens, so "0.6 seconds" will be reported as "1 second".

  **Note for %V**: Alias for `%v`.
  """
  def format(format, conn), do: log("", conn, format)


  # Internal construction methods

  defp log(message, _conn, ""), do: message

  defp log(message, conn, << "%%", rest :: binary >>) do
    message <> "%"
    |> log(conn, rest)
  end

  defp log(message, conn, << "%a", rest :: binary >>) do
    message
    |> DefaultFormatter.RemoteIPAddress.append(conn)
    |> log(conn, rest)
  end

  defp log(message, conn, << "%b", rest :: binary >>) do
    message
    |> DefaultFormatter.ResponseBytes.append(conn, "-")
    |> log(conn, rest)
  end

  defp log(message, conn, << "%B", rest :: binary >>) do
    message
    |> DefaultFormatter.ResponseBytes.append(conn, "0")
    |> log(conn, rest)
  end

  defp log(message, conn, << "%D", rest :: binary >>) do
    message
    |> DefaultFormatter.RequestServingTime.append(conn, :usecs)
    |> log(conn, rest)
  end

  defp log(message, conn, << "%h", rest :: binary >>) do
    message
    |> DefaultFormatter.RemoteIPAddress.append(conn)
    |> log(conn, rest)
  end

  defp log(message, conn, << "%l", rest :: binary >>) do
    message <> "-"
    |> log(conn, rest)
  end

  defp log(message, conn, << "%m", rest :: binary >>) do
    message <> conn.method
    |> log(conn, rest)
  end

  defp log(message, conn, << "%M", rest :: binary >>) do
    message
    |> DefaultFormatter.RequestServingTime.append(conn, :msecs)
    |> log(conn, rest)
  end

  defp log(message, conn, << "%q", rest :: binary >>) do
    message
    |> DefaultFormatter.QueryString.append(conn)
    |> log(conn, rest)
  end

  defp log(message, conn, << "%r", rest :: binary >>) do
    message
    |> DefaultFormatter.RequestLine.append(conn)
    |> log(conn, rest)
  end

  defp log(message, conn, << "%>s", rest :: binary >>) do
    message <> to_string(conn.status)
    |> log(conn, rest)
  end

  defp log(message, conn, << "%t", rest :: binary >>) do
    message
    |> DefaultFormatter.RequestTime.append(conn)
    |> log(conn, rest)
  end

  defp log(message, conn, << "%T", rest :: binary >>) do
    message
    |> DefaultFormatter.RequestServingTime.append(conn, :secs)
    |> log(conn, rest)
  end

  defp log(message, conn, << "%u", rest :: binary >>) do
    message
    |> DefaultFormatter.RemoteUser.append(conn)
    |> log(conn, rest)
  end

  defp log(message, conn, << "%U", rest :: binary >>) do
    message
    |> DefaultFormatter.RequestPath.append(conn)
    |> log(conn, rest)
  end

  defp log(message, conn, << "%v", rest :: binary >>) do
    message <> conn.host
    |> log(conn, rest)
  end

  defp log(message, conn, << "%V", rest :: binary >>) do
    message <> conn.host
    |> log(conn, rest)
  end

  defp log(message, conn, << "%{", rest :: binary >>) do
    [ varname, rest ] = rest |> String.split("}", parts: 2)

    << vartype :: binary-1, rest :: binary >> = rest

    message = case vartype do
      "C" -> DefaultFormatter.RequestCookie.append(message, conn, varname)
      "i" -> DefaultFormatter.RequestHeader.append(message, conn, varname)
      "o" -> DefaultFormatter.ResponseHeader.append(message, conn, varname)
      _   -> message <> "-"
    end

    log(message, conn, rest)
  end

  defp log(message, conn, << char, rest :: binary >>) do
    message <> << char >>
    |> log(conn, rest)
  end
end