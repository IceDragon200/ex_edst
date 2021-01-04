defmodule EDST.Tokenizer do
  @typedoc """
  The newline token represents a raw newline occuring between words

  Other tokens may already require a newline and would parse them out already.
  """
  @type newline_token :: :newline

  @typedoc """
  A header is a space delimited string starting with ~

  Example:

      ~SECTION:1

  """
  @type header_token :: {:header, String.t()}

  @typedoc """
  Comments are a newline delimited character strings starting with a #

  Originally comments could only appear on a line by themselves and not inline with other terms.

  Example:

      # This is a valid comment

      Word # This is now a valid comment

  """
  @type comment_token :: {:comment, String.t()}

  @typedoc """
  Block tags are those that start with %% followed by name denoted until the end of the line
  and are immediately followed up by an open_block token and then terminated with a close_block.

  Example:

      %%block

  """
  @type block_tag_token :: {:block_tag, String.t()}

  @typedoc """
  Plain tags are those that start with a % followed by a word and then the rest of the line
  is the value.

  Example:

      %tag Value

      %name John Doe

  """
  @type tag_token :: {:tag, name::String.t(), value::String.t()}

  @typedoc """
  Open block tokens are just a open curly brace `{` on a line by itself

  Example:

    {

  """
  @type open_block_token :: :open_block

  @typedoc """
  Close block tokens are just a close curly brace `}` on a line by itself

  Example:

    }

  """
  @type close_block_token :: :close_block

  @typedoc """
  A line item is denoted by `---` followed by the value

  Example:

      --- Value

  """
  @type line_item_token :: {:line_item, String.t()}

  @typedoc """
  A label is denoted by a starting `--` and then terminated by another `--`, normally on a line
  by itself.

  Example:

      -- Label --

  """
  @type label_token :: {:label, String.t()}

  @typedoc """
  A dialogue is a line starting with @ followed by any number of words and finally terminated
  by a quoted string.

  Example:

      @ Speaker "Body"

      @ John Doe "Hello darkness my old friend."

  """
  @type dialogue_token :: {:dialogue, speaker::String.t(), body::String.t()}

  @typedoc """
  A quoted string is a list of words enclosed by `"`

  At the moment escape sequences for double-quotes are not supported.

  Example:

    "This is a quoted string"

  """
  @type quoted_string_token :: {:quoted_string, body::String.t()}

  @typedoc """
  A word is any other bit of text not recognized as a formal token, though it's called word it
  may contain numbers, punctuation or any other non-space characters.

  Example:

    These are words (this-too)

  """
  @type word_token :: {:word, word::String.t()}

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
    # label directly after newline
    case String.split(rest, "--", parts: 2) do
      [label, rest] ->
        tokenize_bin(rest, [{:label, label} | acc])

      [_] ->
        {:error, {:incomplete_label, rest}}
    end
  end

  defp tokenize_bin(<<"-- ", rest::binary>>, [] = acc) do
    # label at start
    case String.split(rest, "--", parts: 2) do
      [label, rest] ->
        label = String.trim(label)
        tokenize_bin(rest, [{:label, label} | acc])

      [_] ->
        {:error, {:incomplete_label, rest}}
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
