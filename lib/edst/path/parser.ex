defmodule EDST.Path.Parser do
  alias EDST.Path.Tokenizer

  @allowed_nodes Enum.map([
    "header",
    "comment",
    "line_item",
    "label",
    "tag",
    "dialogue",
    "quoted_string",
    "named_block",
    "block",
    "p",
    "word",
  ], &{&1, String.to_atom(&1)}) |> Enum.into(%{})

  @operators [
    :equals,
    :iequals,
    :contains,
    :icontains,
    :starts_with,
    :istarts_with,
    :ends_with,
    :iends_with,
  ]

  @leaf_tokens [:node, :word, :quoted_string]

  @spec parse(String.t() | [Tokenizer.token()]) :: list()
  def parse(binary) when is_binary(binary) do
    binary
    |> Tokenizer.tokenize()
    |> case do
      {:ok, tokens} ->
        parse(tokens)
    end
  end

  def parse(tokens) when is_list(tokens) do
    do_parse(tokens, [])
  end

  defp do_parse([], acc) do
    {:ok, Enum.reverse(acc)}
  end

  defp do_parse([{spacer, _, _} | rest], acc) when spacer in [:space, :newline] do
    do_parse(rest, acc)
  end

  defp do_parse(tokens, acc) do
    case read_until_space(tokens, []) do
      {tokens, rest} ->
        case to_path_matcher(tokens) do
          {:ok, matcher} ->
            do_parse(rest, [matcher | acc])

          {:error, _reason} = err ->
            err
        end
    end
  end

  defp read_until_space([], acc) do
    {Enum.reverse(acc), []}
  end

  defp read_until_space([{:newline, _, _} | tokens], acc) do
    {Enum.reverse(acc), tokens}
  end

  defp read_until_space([{:space, _, _} | tokens], acc) do
    {Enum.reverse(acc), tokens}
  end

  defp read_until_space([token | tokens], acc) do
    read_until_space(tokens, [token | acc])
  end

  # quoted_string
  defp to_path_matcher([{:quoted_string, item, _}]) do
    {:ok, item}
  end

  # word
  defp to_path_matcher([{:word, item, _}]) do
    {:ok, item}
  end

  # node
  defp to_path_matcher([{:node, item, _}]) do
    to_path_node(item)
  end

  # <op>value
  defp to_path_matcher([{op, nil, _}, {leaf, _, _} = token]) when op in @operators and leaf in @leaf_tokens do
    case to_path_matcher([token]) do
      {:ok, item} ->
        {:ok, {{:op, op}, item}}

      {:error, reason} ->
        {:error, {:invalid_operator_value, reason}}
    end
  end

  # <sub>value
  defp to_path_matcher([{:sub, nil, _}, {leaf, _, _} = token]) when leaf in @leaf_tokens do
    case to_path_matcher([token]) do
      {:ok, item} ->
        {:ok, item}

      {:error, reason} ->
        {:error, {:invalid_sub_value, reason}}
    end
  end

  # node<sub>value
  defp to_path_matcher([{:node, node_type, _}, {:sub, nil, _} | [{leaf, _, _}] = rest]) when leaf in @leaf_tokens do
    case to_path_node(node_type) do
      {:ok, node_type} ->
        case to_path_matcher(rest) do
          {:ok, matcher} ->
            {:ok, {node_type, matcher}}

          {:error, _} = err ->
            err
        end

      {:error, _} = err ->
        err
    end
  end

  # node<op>value
  defp to_path_matcher([{:node, node_type, _} | [{op, nil, _}, {leaf, _, _}] = rest]) when op in @operators and
                                                                                           leaf in @leaf_tokens do
    case to_path_node(node_type) do
      {:ok, node_type} ->
        case to_path_matcher(rest) do
          {:ok, matcher} ->
            {:ok, {node_type, matcher}}

          {:error, _} = err ->
            err
        end

      {:error, _} = err ->
        err
    end
  end

  # node<sub>key<op>value
  defp to_path_matcher([{:node, _, _} = node, {op0, nil, _} = key_op,
                        {key_leaf, _, _} = key, {op1, _, _} = value_op,
                        {value_leaf, _, _} = value]) when key_leaf in @leaf_tokens and
                                                  (op0 in @operators or op0 == :sub) and
                                                  (op1 in @operators or op1 == :sub) and
                                                  value_leaf in @leaf_tokens do
    case to_path_matcher([node, key_op, key]) do
      {:ok, {node_type, key_matcher}} ->
        case to_path_matcher([value_op, value]) do
          {:ok, value_matcher} ->
            {:ok, {node_type, key_matcher, value_matcher}}

          {:error, _} = err ->
            err
        end

      {:error, _} = err ->
        err
    end
  end

  defp to_path_matcher(tokens) do
    {:error, {:unmatched_pattern, tokens}}
  end

  defp to_path_node(name) do
    case Map.fetch(@allowed_nodes, name) do
      {:ok, _value} = res ->
        res

      :error ->
        {:error, {:invalid_node_type, name}}
    end
  end
end
