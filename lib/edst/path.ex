defmodule EDST.Path do
  @moduledoc """
  Path utilities for finding specific blocks or tags within a token list.
  """

  def find_nodes(tokens, [name]) when is_binary(name) do
    tokens
    |> Enum.reduce([], fn
      {:named_block, {^name, _children}, _} = node, acc ->
        [node | acc]

      {:tag, {^name, _value}, _} = node, acc ->
        [node | acc]

      {:label, ^name, _} = node, acc ->
        [node | acc]

      {_, _, _}, acc ->
        acc
    end)
    |> Enum.reverse()
  end

  def find_nodes(tokens, [name]) when is_atom(name) do
    tokens
    |> Enum.reduce([], fn
      {^name, _, _} = node, acc ->
        [node | acc]

      {_, _, _}, acc ->
        acc
    end)
    |> Enum.reverse()
  end

  def find_nodes(tokens, [name | rest] = path) when is_binary(name) do
    tokens
    |> Enum.reduce([], fn
      {:named_block, {^name, children}, _}, acc ->
        acc ++ find_nodes(children, rest)

      {:named_block, {_, children}, _}, acc ->
        acc ++ find_nodes(children, path)

      {:block, children, _}, acc ->
        acc ++ find_nodes(children, path)

      {_, _, _}, acc ->
        acc
    end)
  end

  def find_nodes(tokens, [name | _rest] = path) when is_atom(name) do
    tokens
    |> Enum.reduce([], fn
      {^name, _, _} = node, acc ->
        [node | acc]

      {:named_block, {_, children}, _}, acc ->
        acc ++ find_nodes(children, path)

      {:block, children, _}, acc ->
        acc ++ find_nodes(children, path)

      {_, _, _}, acc ->
        acc
    end)
    |> Enum.reverse()
  end
end
