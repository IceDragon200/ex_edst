defmodule EDST.Path.Encoder do
  @moduledoc """
  Provides utilities for encoding a node matcher path into a single string.
  """

  @doc """
  Turns a node path into a serialized form, to undo the process use the EDST.Path.Parser.parse
  """
  @spec encode(list()) :: {:ok, String.t()}
  def encode(path) when is_list(path) do
    result =
      path
      |> Enum.map(&encode_matcher/1)
      |> Enum.intersperse(" ")
      |> IO.iodata_to_binary()

    {:ok, result}
  end

  def encode_matcher({{:op, operator}, value}) do
    [encode_operator(operator), escape_value(value)]
  end

  def encode_matcher({node_type, value}) when is_atom(node_type) do
    [encode_matcher(node_type), encode_matcher_with_leading(value)]
  end

  def encode_matcher({node_type, key, value}) when is_atom(node_type) do
    [encode_matcher(node_type), encode_matcher_with_leading(key), encode_matcher_with_leading(value)]
  end

  def encode_matcher(value) when is_binary(value) do
    escape_value(value)
  end

  def encode_matcher(value) when is_atom(value) do
    ["@", to_string(value)]
  end

  defp encode_matcher_with_leading({{:op, _}, _} = value) do
    encode_matcher(value)
  end

  defp encode_matcher_with_leading(value) when is_binary(value) do
    [":", encode_matcher(value)]
  end

  defp encode_operator(:equals), do: "="
  defp encode_operator(:iequals), do: "~="
  defp encode_operator(:contains), do: "#"
  defp encode_operator(:icontains), do: "~#"
  defp encode_operator(:starts_with), do: "#>"
  defp encode_operator(:istarts_with), do: "~#>"
  defp encode_operator(:ends_with), do: ">#"
  defp encode_operator(:iends_with), do: "~>#"

  defp escape_value(value) when is_binary(value) do
    if String.contains?(value, "\s") or String.contains?(value, ":") do
      # TODO: properly handle escpaing double-quotes inside the existing string
      "\"#{value}\""
    else
      value
    end
  end
end
