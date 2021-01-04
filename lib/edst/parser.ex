defmodule EDST.Parser do
  def parse(bin) when is_binary(bin) do
    case EDST.Tokenizer.tokenize(bin) do
      {:ok, tokens} ->
        parse_tokens(tokens, [])

      {:error, reason} ->
        {:error, {:tokenizer_error, reason}}
    end
  end

  defp parse_tokens([], acc) do
    {:ok, Enum.reverse(acc), []}
  end

  defp parse_tokens([{:block_tag, name}, :open_block | tokens], acc) do
    case parse_tokens(tokens, []) do
      {:ok, body, [:close_block | rest]} ->
        parse_tokens(rest, [{:named_block, name, body} | acc])
    end
  end

  defp parse_tokens([:open_block | tokens], acc) do
    case parse_tokens(tokens, []) do
      {:ok, body, [:close_block | rest]} ->
        parse_tokens(rest, [{:block, body} | acc])
    end
  end

  defp parse_tokens([:close_block | _tokens] = tokens, acc) do
    {:ok, Enum.reverse(acc), tokens}
  end

  defp parse_tokens([{:tag, _key, _value} = token | tokens], acc) do
    parse_tokens(tokens, [token | acc])
  end

  defp parse_tokens([{:line_item, _item} = token | tokens], acc) do
    parse_tokens(tokens, [token | acc])
  end

  defp parse_tokens([{:comment, _comment} = token | tokens], acc) do
    parse_tokens(tokens, [token | acc])
  end

  defp parse_tokens([{:word, _} | _] = tokens, acc) do
    case parse_paragraph(tokens, []) do
      {body, tokens} ->
        parse_tokens(tokens, [{:p, body} | acc])
    end
  end

  defp parse_tokens([:newline = token | tokens], acc) do
    parse_tokens(tokens, [token | acc])
  end

  defp parse_tokens([{:header, _header} = token | tokens], acc) do
    parse_tokens(tokens, [token | acc])
  end

  defp parse_tokens([{:label, _label} = token | tokens], acc) do
    parse_tokens(tokens, [token | acc])
  end

  defp parse_tokens([{:quoted_string, _body} = token | tokens], acc) do
    parse_tokens(tokens, [token | acc])
  end

  defp parse_tokens([{:dialogue, _speaker, _body} = token | tokens], acc) do
    parse_tokens(tokens, [token | acc])
  end

  defp parse_paragraph([], acc) do
    {Enum.reverse(acc), []}
  end

  defp parse_paragraph([{:word, _word} = token | tokens], acc) do
    parse_paragraph(tokens, [token | acc])
  end

  defp parse_paragraph([:newline | tokens], acc) do
    case tokens do
      [:newline | rest] ->
        {Enum.reverse(acc), rest}

      rest ->
        parse_paragraph(rest, acc)
    end
  end

  defp parse_paragraph(tokens, acc) do
    # no other matching tokens
    {Enum.reverse(acc), tokens}
  end
end
