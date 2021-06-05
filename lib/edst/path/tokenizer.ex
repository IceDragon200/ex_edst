defmodule EDST.Path.Tokenizer do
  @moduledoc """
  Tokenizer module for EDST node paths, it's a trimmed down version of the EDST Document tokenizer,
  and could possibly be used for a generic word parser.
  """
  @type token_meta :: %{
    col_no: non_neg_integer(),
    line_no: non_neg_integer(),
  }

  @type token :: {:newline, nil, token_meta()}
               | {:space, nil, token_meta()}
               | {:quoted_string, nil, token_meta()}
               | {:equals, nil, token_meta()}
               | {:iequals, nil, token_meta()}
               | {:starts_with, nil, token_meta()}
               | {:istarts_with, nil, token_meta()}
               | {:ends_with, nil, token_meta()}
               | {:iends_with, nil, token_meta()}
               | {:contains, nil, token_meta()}
               | {:icontains, nil, token_meta()}
               | {:sub, nil, token_meta()}
               | {:word, nil, token_meta()}

  @spec tokenize(binary()) :: {:ok, [token()]} | {:error, term}
  def tokenize(binary) when is_binary(binary) do
    tokenize_bin(binary, [], %{line_no: 1, col_no: 1})
  end

  defp tokenize_bin("", acc, _meta) do
    {:ok, Enum.reverse(acc)}
  end

  defp tokenize_bin(<<"\r\n",rest::binary>>, acc, meta) do
    # raw newline
    node = {:newline, nil, meta}
    tokenize_bin(rest, [node | acc], next_line(meta))
  end

  defp tokenize_bin(<<"\n",rest::binary>>, acc, meta) do
    # raw newline
    node = {:newline, nil, meta}
    tokenize_bin(rest, [node | acc], next_line(meta))
  end

  defp tokenize_bin(<<"\s",_::binary>> = rest, acc, meta) do
    trimmed = String.trim_leading(rest, "\s")
    tokenize_bin(trimmed, [{:space, nil, meta} | acc], move_column(meta, byte_size(rest) - byte_size(trimmed)))
  end

  defp tokenize_bin(<<"\"",_rest::binary>> = rest, acc, meta) do
    # just a raw quoted string
    case tokenize_quoted_string(rest, meta) do
      {string, rest, new_meta} ->
        tokenize_bin(rest, [{:quoted_string, string, meta} | acc], new_meta)
    end
  end

  defp tokenize_bin(<<"=",rest::binary>>, acc, meta) do
    tokenize_bin(rest, [{:equals, nil, meta} | acc], move_column(meta, 1))
  end

  defp tokenize_bin(<<"~=",rest::binary>>, acc, meta) do
    tokenize_bin(rest, [{:iequals, nil, meta} | acc], move_column(meta, 2))
  end

  defp tokenize_bin(<<"#>",rest::binary>>, acc, meta) do
    tokenize_bin(rest, [{:starts_with, nil, meta} | acc], move_column(meta, 2))
  end

  defp tokenize_bin(<<"~#>",rest::binary>>, acc, meta) do
    tokenize_bin(rest, [{:istarts_with, nil, meta} | acc], move_column(meta, 3))
  end

  defp tokenize_bin(<<">#",rest::binary>>, acc, meta) do
    tokenize_bin(rest, [{:ends_with, nil, meta} | acc], move_column(meta, 2))
  end

  defp tokenize_bin(<<"~>#",rest::binary>>, acc, meta) do
    tokenize_bin(rest, [{:iends_with, nil, meta} | acc], move_column(meta, 3))
  end

  defp tokenize_bin(<<"#",rest::binary>>, acc, meta) do
    tokenize_bin(rest, [{:contains, nil, meta} | acc], move_column(meta, 1))
  end

  defp tokenize_bin(<<"~#",rest::binary>>, acc, meta) do
    tokenize_bin(rest, [{:icontains, nil, meta} | acc], move_column(meta, 2))
  end

  defp tokenize_bin(<<":",rest::binary>>, acc, meta) do
    tokenize_bin(rest, [{:sub, nil, meta} | acc], move_column(meta, 1))
  end

  defp tokenize_bin(<<"@",rest::binary>>, acc, meta) do
    case tokenize_word(rest) do
      {"", _rest} ->
        {:error, :invalid_node_name, meta}

      {name, rest} ->
        tokenize_bin(rest, [{:node, name, meta} | acc], move_column(meta, 1 + byte_size(name)))
    end
  end

  defp tokenize_bin(<<"%%",rest::binary>>, acc, meta) do
    tokenize_bin(rest, [{:node_alias, "named_block", meta} | acc], move_column(meta, 2))
  end

  defp tokenize_bin(<<"%",rest::binary>>, acc, meta) do
    tokenize_bin(rest, [{:node_alias, "tag", meta} | acc], move_column(meta, 2))
  end

  defp tokenize_bin(rest, acc, meta) do
    case tokenize_word(rest) do
      {word, rest} ->
        tokenize_bin(rest, [{:word, word, meta} | acc], move_column(meta, byte_size(word)))
    end
  end

  defp tokenize_quoted_string(str, meta, state \\ :start, acc \\ [])

  defp tokenize_quoted_string(<<"\"",rest::binary>>, meta, :start, acc) do
    tokenize_quoted_string(rest, move_column(meta, 1), :body, acc)
  end

  defp tokenize_quoted_string(<<"\"",rest::binary>>, meta, :body, acc) do
    {Enum.reverse(acc) |> IO.iodata_to_binary(), rest, move_column(meta, 1)}
  end

  defp tokenize_quoted_string(<<"\r\n",rest::binary>>, meta, :body, acc) do
    tokenize_quoted_string(rest, next_line(meta), :body, ["\s" | acc])
  end

  defp tokenize_quoted_string(<<"\n",rest::binary>>, meta, :body, acc) do
    tokenize_quoted_string(rest, next_line(meta), :body, ["\s" | acc])
  end

  defp tokenize_quoted_string(<<c,rest::binary>>, meta, :body, acc) do
    tokenize_quoted_string(rest, move_column(meta, 1), :body, [<<c>> | acc])
  end

  defp tokenize_word(str, acc \\ [])

  defp tokenize_word("", acc) do
    {Enum.reverse(acc) |> IO.iodata_to_binary(), ""}
  end

  defp tokenize_word(<<c,_::binary>> = rest, acc) when c in [?:, ?@, ?~, ?>, ?<, ?#, ?~, ?=] do
    {Enum.reverse(acc) |> IO.iodata_to_binary(), rest}
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

  defp next_line(meta) do
    %{meta | line_no: meta.line_no + 1, col_no: 1}
  end

  defp move_column(meta, amount) do
    %{meta | col_no: meta.col_no + amount}
  end
end
