defmodule EDST.Path do
  def find_nodes(tokens, [name]) when is_binary(name) do
    tokens
    |> Enum.reduce([], fn
      {:named_block, ^name, _children} = node, acc ->
        [node | acc]

      {:tag, ^name, _value} = node, acc ->
        [node | acc]

      _, acc ->
        acc
    end)
    |> Enum.reverse()
  end

  def find_nodes(tokens, [name | rest] = path) when is_binary(name) do
    tokens
    |> Enum.reduce([], fn
      {:named_block, ^name, children}, acc ->
        acc ++ find_nodes(children, rest)

      {:named_block, _, children}, acc ->
        acc ++ find_nodes(children, path)

      {:block, children}, acc ->
        acc ++ find_nodes(children, path)

      _, acc ->
        acc
    end)
  end
end
