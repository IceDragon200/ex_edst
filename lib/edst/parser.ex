defmodule EDST.Parser do
  @moduledoc """
  The parser takes token input from the Tokenizer and completes the structural formatting for
  consumption.

  This process includes turning words into paragraphs, block tags and their tags into proper blocks
  amongst other fixes.
  """

  @type newline_token :: EDST.Tokenizer.newline_token()

  @type header_token :: EDST.Tokenizer.header_token()

  @type comment_token :: EDST.Tokenizer.comment_token()

  @type tag_token :: EDST.Tokenizer.tag_token()

  @type line_item_token :: EDST.Tokenizer.line_item_token()

  @type dialogue_token :: EDST.Tokenizer.dialogue_token()

  @type quoted_string_token :: EDST.Tokenizer.quoted_string_token()

  @type label_token :: EDST.Tokenizer.label_token()

  @typedoc """
  A named block is formed from a block_tag, open_block, any other terms and finally a closed_block

  Example:

      %%block
      {
        ... Block contents here
      }

  """
  @type named_block_token :: {:named_block, name::String.t(), tokens::[token]}

  @typedoc """
  While originally not supported, anonymous blocks can be created by using curly braces with no
  block_tag

  Example:

      {
        ... Block contents here
      }

  """
  @type block_token :: {:block, tokens::[token]}

  @type paragraph_element_tokens :: EDST.Tokenizer.word_token()
                                  | EDST.Tokenizer.quoted_string_token()

  @typedoc """
  A paragraph is formed from a stream of words and quoted strings and terminated on any non-word,
  non-quoted-string or double newline.

  Any newlines in a paragraph stream are ignored, unless it's a double newline.

  Example

      All of this is considered a "single paragraph" by the parser.

  """
  @type paragraph_token :: {:p, [paragraph_element_tokens()]}

  @typedoc """
  All tokens produced by the parser, some are passed through as is from the tokenizing process.
  """
  @type token :: newline_token()
               | header_token()
               | comment_token()
               | tag_token()
               | named_block_token()
               | block_token()
               | line_item_token()
               | label_token()
               | dialogue_token()
               | paragraph_token()

  @spec parse(binary()) :: {:ok, [token]} | {:error, term()}
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

  defp parse_tokens([{:word, _word} | _] = tokens, acc) do
    case parse_paragraph(tokens, []) do
      {body, tokens} ->
        parse_tokens(tokens, [{:p, body} | acc])
    end
  end

  defp parse_tokens([{:quoted_string, _body} | _] = tokens, acc) do
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

  defp parse_tokens([{:dialogue, _speaker, _body} = token | tokens], acc) do
    parse_tokens(tokens, [token | acc])
  end

  defp parse_paragraph([], acc) do
    {Enum.reverse(acc), []}
  end

  defp parse_paragraph([{:quoted_string, _body} = token | tokens], acc) do
    parse_paragraph(tokens, [token | acc])
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
