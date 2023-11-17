defmodule EDST.Tokenizer do
  import EDST.Tokens

  @type token_meta :: EDST.Tokens.token_meta()

  @typedoc """
  The newline token represents a raw newline occuring between words

  Other tokens may already require a newline and would parse them out already.
  """
  @type newline_token :: {:newline, nil, token_meta()}

  @typedoc """
  A header is a space delimited string starting with ~

  Example:

      ~SECTION:1

  """
  @type header_token :: {:header, String.t(), token_meta()}

  @typedoc """
  Comments are a newline delimited character strings starting with a #

  Originally comments could only appear on a line by themselves and not inline with other terms.

  Example:

      # This is a valid comment

      Word # This is now a valid comment

  """
  @type comment_token :: {:comment, String.t(), token_meta()}

  @typedoc """
  Block tags are those that start with %% followed by name denoted until the end of the line
  and are immediately followed up by an open_block token and then terminated with a close_block.

  Example:

      %%block

  """
  @type block_tag_token :: {:block_tag, String.t(), token_meta()}

  @typedoc """
  Plain tags are those that start with a % followed by a word and then the rest of the line
  is the value.

  Example:

      %tag Value

      %name John Doe

  """
  @type tag_token :: {:tag, {name::String.t(), value::String.t()}, token_meta()}

  @typedoc """
  Open block tokens are just a open curly brace `{` on a line by itself

  Example:

    {

  """
  @type open_block_token :: {:open_block, nil, token_meta()}

  @typedoc """
  Close block tokens are just a close curly brace `}` on a line by itself

  Example:

    }

  """
  @type close_block_token :: {:close_block, nil, token_meta()}

  @typedoc """
  A line item is denoted by `---` followed by the value

  Example:

      --- Value

  """
  @type line_item_token :: {:line_item, String.t(), token_meta()}

  @typedoc """
  A label is denoted by a starting `--` and then terminated by another `--`, normally on a line
  by itself.

  Example:

      -- Label --

  """
  @type label_token :: {:label, String.t(), token_meta()}

  @typedoc """
  A dialogue is a line starting with @ followed by any number of words and finally terminated
  by a quoted string.

  Example:

      @ Speaker "Body"

      @ John Doe "Hello darkness my old friend."

  """
  @type dialogue_token :: {:dialogue, {speaker::String.t(), body::String.t()}, token_meta()}

  @typedoc """
  A quoted string is a list of words enclosed by `"`

  At the moment escape sequences for double-quotes are not supported.

  Example:

    "This is a quoted string"

  """
  @type quoted_string_token :: {:quoted_string, body::String.t(), token_meta()}

  @typedoc """
  A word is any other bit of text not recognized as a formal token, though it's called word it
  may contain numbers, punctuation or any other non-space characters.

  Example:

    These are words (this-too)

  """
  @type word_token :: {:word, word::String.t(), token_meta()}

  @typedoc """
  All of the tokens that can be produced by the tokenizer
  """
  @type token :: newline_token()
               | header_token()
               | comment_token()
               | block_tag_token()
               | tag_token()
               | open_block_token()
               | close_block_token()
               | line_item_token()
               | label_token()
               | dialogue_token()
               | quoted_string_token()
               | word_token()

  @spec tokenize(binary()) :: {:ok, [token()]} | {:error, term}
  def tokenize(binary) when is_binary(binary) do
    tokenize_bin(binary, [], token_meta())
  end

  defp tokenize_bin("", acc, _meta) do
    {:ok, Enum.reverse(acc)}
  end

  defp tokenize_bin(<<"\r\n",rest::binary>>, acc, meta) do
    # raw newline
    node = newline(meta: meta)
    tokenize_bin(rest, [node | acc], next_line(meta))
  end

  defp tokenize_bin(<<"\n",rest::binary>>, acc, meta) do
    # raw newline
    node = newline(meta: meta)
    tokenize_bin(rest, [node | acc], next_line(meta))
  end

  defp tokenize_bin(<<"\s",_::binary>> = rest, acc, meta) do
    trimmed = String.trim_leading(rest, "\s")
    tokenize_bin(trimmed, acc, move_column(meta, byte_size(rest) - byte_size(trimmed)))
  end

  defp tokenize_bin(<<"~",rest::binary>>, acc, meta) do
    # header tag
    case tokenize_word(rest) do
      {header, rest} ->
        node = header(value: header, meta: meta)
        tokenize_bin(rest, [node | acc], move_column(meta, 1 + byte_size(header)))
    end
  end

  defp tokenize_bin(<<"#",rest::binary>>, acc, meta) do
    # comment
    {node, rest, meta} =
      case String.split(rest, "\n", parts: 2) do
        [comment, rest] ->
          {comment(value: comment, meta: meta), rest, next_line(meta)}

        [] ->
          {comment(value: rest, meta: meta), "", meta}
      end

    tokenize_bin(rest, [node | acc], meta)
  end

  defp tokenize_bin(<<"%%",rest::binary>>, acc, meta) do
    # block tag
    {node, rest, meta} =
      case String.split(rest, "\n", parts: 2) do
        [name, rest] ->
          {block_tag(value: name, meta: meta), rest, next_line(meta)}

        [] ->
          {block_tag(value: rest, meta: meta), ""}
      end

    tokenize_bin(rest, [node | acc], meta)
  end

  defp tokenize_bin(<<"%",rest::binary>>, acc, meta) do
    # tag
    case tokenize_word(rest) do
      {name, rest} ->
        case String.split(rest, "\n", parts: 2) do
          [value, rest] ->
            value = String.trim(value)
            token = tag(pair: {name, value}, meta: meta)
            tokenize_bin(rest, [token | acc], next_line(meta))

          [] ->
            value = String.trim(rest)
            token = tag(pair: {name, value}, meta: meta)
            tokenize_bin("", [token | acc], meta)
        end
    end
  end

  defp tokenize_bin(<<"{",rest::binary>>, acc, meta) do
    # open block
    case String.split(rest, "\n", parts: 2) do
      [should_be_blank, rest] ->
        case String.trim(should_be_blank) do
          "" ->
            token = open_block(meta: meta)
            tokenize_bin(rest, [token | acc], next_line(meta))

          _ ->
            {:error, {:opening_block_error, should_be_blank}}
        end
    end
  end

  defp tokenize_bin(<<"}",rest::binary>>, acc, meta) do
    # close block
    case String.split(rest, "\n", parts: 2) do
      [should_be_blank, rest] ->
        case String.trim(should_be_blank) do
          "" ->
            token = close_block(meta: meta)
            tokenize_bin(rest, [token | acc], next_line(meta))

          _ ->
            {:error, {:close_block_error, should_be_blank}}
        end

      [_] ->
        token = close_block(meta: meta)
        tokenize_bin("", [token | acc], meta)
    end
  end

  defp tokenize_bin(<<"--- ",rest::binary>>, acc, meta) do
    # line item
    case String.split(rest, "\n", parts: 2) do
      [item, rest] ->
        token = line_item(value: item, meta: meta)
        tokenize_bin(rest, [token | acc], next_line(meta))

      [item] ->
        token = line_item(value: item, meta: meta)
        tokenize_bin("", [token | acc], meta)
    end
  end

  defp tokenize_bin(<<"-- ", rest::binary>>, acc, meta) do
    # label at start
    case String.split(rest, "--", parts: 2) do
      [label, rest] ->
        label = String.trim(label)
        token = label(value: label, meta: meta)
        tokenize_bin(rest, [token | acc], meta)

      [_] ->
        {:error, {:incomplete_label, rest}}
    end
  end

  defp tokenize_bin(<<"@ ",rest::binary>>, acc, meta) do
    # dialogue speaker
    case tokenize_speaker_name(rest, []) do
      {raw_name, <<"\"",_::binary>> = rest} ->
        name = String.trim(raw_name)
        case tokenize_quoted_string(rest, move_column(meta, 2 + byte_size(raw_name))) do
          {body, rest, new_meta} ->
            token = dialogue(pair: {name, body}, meta: meta)
            tokenize_bin(rest, [token | acc], new_meta)
        end
    end
  end

  defp tokenize_bin(<<"\"",_rest::binary>> = rest, acc, meta) do
    # just a raw quoted string
    case tokenize_quoted_string(rest, meta) do
      {string, rest, new_meta} ->
        token = quoted_string(value: string, meta: meta)
        tokenize_bin(rest, [token | acc], new_meta)
    end
  end

  defp tokenize_bin(rest, acc, meta) do
    case tokenize_word(rest) do
      {word, rest} ->
        token = word(value: word, meta: meta)
        tokenize_bin(rest, [token | acc], move_column(meta, byte_size(word)))
    end
  end

  defp tokenize_speaker_name(<<"\"",_rest::binary>> = rest, acc) do
    name = Enum.reverse(acc) |> IO.iodata_to_binary()
    {name, rest}
  end

  defp tokenize_speaker_name(<<c,rest::binary>>, acc) do
    tokenize_speaker_name(rest, [<<c>> | acc])
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

  defp tokenize_quoted_string(<<"\\", c::utf8, rest::binary>>, meta, :body, acc) do
    tokenize_quoted_string(rest, move_column(meta, 2), :body, [<<c::utf8>> | acc])
  end

  defp tokenize_quoted_string(<<c::utf8,rest::binary>>, meta, :body, acc) do
    tokenize_quoted_string(rest, move_column(meta, 1), :body, [<<c::utf8>> | acc])
  end

  defp tokenize_word(str, acc \\ [])

  defp tokenize_word("", acc) do
    {Enum.reverse(acc) |> IO.iodata_to_binary(), ""}
  end

  defp tokenize_word(<<"\t",_::binary>> = rest, acc) do
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
    token_meta(meta, line_no: token_meta(meta, :line_no) + 1, col_no: 1)
  end

  defp move_column(meta, amount) do
    token_meta(meta, col_no: token_meta(meta, :col_no) + amount)
  end
end
