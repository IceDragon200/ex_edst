defmodule EDST.Tokenizer do
  @spec tokenize(binary()) :: {:ok, list()} | {:error, term}
  def tokenize(binary) when is_binary(binary) do
    tokenize_bin(binary, [])
  end

  defp tokenize_bin("", acc) do
    {:ok, Enum.reverse(acc)}
  end

  defp tokenize_bin(<<"\s",rest::binary>>, acc) do
    tokenize_bin(String.trim_leading(rest), acc)
  end

  defp tokenize_bin(<<"\r\n",rest::binary>>, acc) do
    # raw newline
    node = :newline
    tokenize_bin(rest, [node | acc])
  end

  defp tokenize_bin(<<"\n",rest::binary>>, acc) do
    # raw newline
    node = :newline
    tokenize_bin(rest, [node | acc])
  end

  defp tokenize_bin(<<"~",rest::binary>>, acc) do
    # header tag
    case tokenize_word(rest) do
      {header, rest} ->
        node = {:header, header}
        tokenize_bin(rest, [node | acc])
    end
  end

  defp tokenize_bin(<<"#",rest::binary>>, acc) do
    # comment
    {node, rest} =
      case String.split(rest, "\n", parts: 2) do
        [comment, rest] ->
          {{:comment, comment}, rest}

        [] ->
          {{:comment, rest}, ""}
      end

    tokenize_bin(rest, [node | acc])
  end

  defp tokenize_bin(<<"%%",rest::binary>>, acc) do
    # block tag
    {node, rest} =
      case String.split(rest, "\n", parts: 2) do
        [name, rest] ->
          {{:block_tag, name}, rest}

        [] ->
          {{:block_tag, rest}, ""}
      end

    tokenize_bin(rest, [node | acc])
  end

  defp tokenize_bin(<<"%",rest::binary>>, acc) do
    # tag
    case tokenize_word(rest) do
      {name, rest} ->
        case String.split(rest, "\n", parts: 2) do
          [value, rest] ->
            value = String.trim(value)
            tokenize_bin(rest, [{:tag, name, value} | acc])

          [] ->
            value = String.trim(rest)
            tokenize_bin("", [{:tag, name, value} | acc])
        end
    end
  end

  defp tokenize_bin(<<"{",rest::binary>>, acc) do
    # open block
    case String.split(rest, "\n", parts: 2) do
      [should_be_blank, rest] ->
        case String.trim(should_be_blank) do
          "" ->
            tokenize_bin(rest, [:open_block | acc])

          _ ->
            {:error, {:opening_block_error, should_be_blank}}
        end
    end
  end

  defp tokenize_bin(<<"}",rest::binary>>, acc) do
    # close block
    case String.split(rest, "\n", parts: 2) do
      [should_be_blank, rest] ->
        case String.trim(should_be_blank) do
          "" ->
            tokenize_bin(rest, [:close_block | acc])

          _ ->
            {:error, {:close_block_error, should_be_blank}}
        end

      [_] ->
        tokenize_bin("", [:close_block | acc])
    end
  end

  defp tokenize_bin(<<"--- ",rest::binary>>, acc) do
    # line item
    case String.split(rest, "\n", parts: 2) do
      [item, rest] ->
        tokenize_bin(rest, [{:line_item, item} | acc])
    end
  end

  defp tokenize_bin(<<"-- ", rest::binary>>, [:newline | _] = acc) do
    # label after newline
    case String.split(rest, "--", parts: 2) do
      [label, rest] ->
        tokenize_bin(rest, [{:label, label} | acc])

      [_] ->
        {:error, {:incomplete_label, rest}}
    end
  end

  defp tokenize_bin(<<"-- ", rest::binary>>, [] = acc) do
    # label starting line
    case String.split(rest, "--", parts: 2) do
      [label, rest] ->
        tokenize_bin(rest, [{:label, label} | acc])
    end
  end

  defp tokenize_bin(<<"@ ",rest::binary>>, acc) do
    # dialogue speaker
    case tokenize_speaker_name(rest, []) do
      {name, <<"\"",_::binary>> = rest} ->
        name = String.trim(name)
        case tokenize_quoted_string(rest) do
          {body, rest} ->
            tokenize_bin(rest, [{:dialogue, name, body} | acc])
        end
    end
  end

  defp tokenize_bin(<<"\"",_rest::binary>> = rest, acc) do
    # just a raw quoted string
    case tokenize_quoted_string(rest) do
      {string, rest} ->
        tokenize_bin(rest, [{:quoted_string, string} | acc])
    end
  end

  defp tokenize_bin(rest, acc) do
    case tokenize_word(rest) do
      {word, rest} ->
        tokenize_bin(rest, [{:word, word} | acc])
    end
  end

  defp tokenize_speaker_name(<<"\"",_rest::binary>> = rest, acc) do
    name = Enum.reverse(acc) |> IO.iodata_to_binary()
    {name, rest}
  end

  defp tokenize_speaker_name(<<c,rest::binary>>, acc) do
    tokenize_speaker_name(rest, [<<c>> | acc])
  end

  defp tokenize_quoted_string(str, state \\ :start, acc \\ [])

  defp tokenize_quoted_string(<<"\"",rest::binary>>, :start, acc) do
    tokenize_quoted_string(rest, :body, acc)
  end

  defp tokenize_quoted_string(<<"\"",rest::binary>>, :body, acc) do
    {Enum.reverse(acc) |> IO.iodata_to_binary(), rest}
  end

  defp tokenize_quoted_string(<<c,rest::binary>>, :body, acc) do
    tokenize_quoted_string(rest, :body, [<<c>> | acc])
  end

  defp tokenize_word(str, acc \\ [])

  defp tokenize_word("", acc) do
    {Enum.reverse(acc) |> IO.iodata_to_binary(), ""}
  end

  defp tokenize_word(<<"\s",_::binary>> = rest, acc) do
    {Enum.reverse(acc) |> IO.iodata_to_binary(), rest}
  end

  defp tokenize_word(<<"\r\n",_::binary>> = rest, acc) do
    {Enum.reverse(acc) |> IO.iodata_to_binary(), rest}
  end

  defp tokenize_word(<<"\n",_::binary>> = rest, acc) do
    {Enum.reverse(acc) |> IO.iodata_to_binary(), rest}
  end

  defp tokenize_word(<<c,rest::binary>>, acc) do
    tokenize_word(rest, [<<c>> | acc])
  end
end
