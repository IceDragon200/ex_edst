defmodule EDST.Utils do
  import EDST.Tokens

  @type split_by_newlines_option :: {:keep_newline, boolean()}

  @type char_or_code :: binary() | integer()

  @type esc_multiline :: {:esc | :uesc, [char_or_code()]}

  defmacro add_meta_line(meta, amount \\ 1) do
    quote do
      token_meta(unquote(meta), line_no: token_meta(unquote(meta), :line_no) + unquote(amount), col_no: 1)
    end
  end

  defmacro add_meta_col(meta, amount) do
    quote do
      token_meta(unquote(meta), col_no: token_meta(unquote(meta), :col_no) + unquote(amount))
    end
  end

  defguard is_utf8_bom_char(c) when c == 0xFEFF
  defguard is_utf8_digit_char(c) when c >= ?0 and c <= ?9
  defguard is_utf8_scalar_char(c) when (c >= 0x0000 and c <= 0xD7FF) or (c >= 0xE000 and c <= 0x10FFFF)
  defguard is_utf8_direction_control_char(c) when
    (c >= 0x200E and c <= 0x200F) or
    (c >= 0x2066 and c <= 0x2069) or
    (c >= 0x202A and c <= 0x202E)

  defguard is_utf8_space_like_char(c) when c in [
    0x09,
    0x0B,
    # Whitespace
    0x20,
    # No-Break Space
    0xA0,
    # Ogham Space Mark
    0x1680,
    # En Quad
    0x2000,
    # Em Quad
    0x2001,
    # En Space
    0x2002,
    # Em Space
    0x2003,
    # Three-Per-Em Space
    0x2004,
    # Four-Per-Em Space
    0x2005,
    # Six-Per-Em Space
    0x2006,
    # Figure Space
    0x2007,
    # Punctuation Space
    0x2008,
    # Thin Space
    0x2009,
    # Hair Space
    0x200A,
    # Narrow No-Break Space
    0x202F,
    # Medium Mathematical Space
    0x205F,
    # Ideographic Space
    0x3000,
  ]

  defguard is_utf8_newline_like_char(c) when c in [
    # New Line
    0x0A,
    # NP form feed, new pag
    0x0C,
    # Carriage Return
    0x0D,
    # Next-Line
    0x85,
    # Line Separator
    0x2028,
    # Paragraph Separator
    0x2029,
  ]

  defguard is_utf8_twochar_newline(c1, c2) when c1 == 0x0D and c2 == 0x0A

  defguard is_utf8_disallowed_char(c) when
    not is_utf8_scalar_char(c) or
    is_utf8_direction_control_char(c)

  @spec utf8_char_byte_size(integer()) :: integer()
  def utf8_char_byte_size(c) when c < 0x80 do
    1
  end

  def utf8_char_byte_size(c) when c < 0x800 do
    2
  end

  def utf8_char_byte_size(c) when c < 0x10000 do
    3
  end

  def utf8_char_byte_size(c) when c >= 0x10000 do
    4
  end

  @doc """
  Converts a list to a binary, this also handles tokenizer specific escape tuples.
  """
  @spec list_to_utf8_binary(list()) :: binary()
  def list_to_utf8_binary(list) when is_list(list) do
    list
    |> Enum.map(fn
      {:esc, c} when is_integer(c) -> <<c::utf8>>
      {:esc, c} when is_binary(c) -> c
      {:esc, c} when is_list(c) -> list_to_utf8_binary(c)
      c when is_integer(c) -> <<c::utf8>>
      c when is_binary(c) -> c
      c when is_list(c) -> list_to_utf8_binary(c)
    end)
    |> IO.iodata_to_binary()
  end

  @doc """
  Splits off as many space characters as possible
  """
  @spec split_spaces(binary(), list()) :: {spaces::binary(), rest::binary()}
  def split_spaces(rest, acc \\ [])

  def split_spaces(<<>> = rest, acc) do
    {IO.iodata_to_binary(Enum.reverse(acc)), rest}
  end

  def split_spaces(<<c::utf8, rest::binary>>, acc) when is_utf8_space_like_char(c) do
    split_spaces(rest, [<<c::utf8>> | acc])
  end

  def split_spaces(rest, acc) do
    {IO.iodata_to_binary(Enum.reverse(acc)), rest}
  end

  def split_spaces_and_newlines(rest, meta, acc \\ [])

  def split_spaces_and_newlines(<<c::utf8, rest::binary>>, meta, acc) when is_utf8_space_like_char(c) do
    split_spaces_and_newlines(rest, add_meta_col(meta, utf8_char_byte_size(c)), [<<c::utf8>> | acc])
  end

  def split_spaces_and_newlines(<<c1::utf8, c2::utf8, rest::binary>>, meta, acc) when is_utf8_twochar_newline(c1, c2) do
    split_spaces_and_newlines(rest, add_meta_line(meta, 1), [<<c1::utf8, c2::utf8>> | acc])
  end

  def split_spaces_and_newlines(<<c::utf8, rest::binary>>, meta, acc) when is_utf8_newline_like_char(c) do
    split_spaces_and_newlines(rest, add_meta_line(meta, 1), [<<c::utf8>> | acc])
  end

  def split_spaces_and_newlines(rest, meta, acc) do
    {IO.iodata_to_binary(Enum.reverse(acc)), rest, meta}
  end

  @spec split_up_to_newline(binary(), any(), [any()]) :: {:ok, binary(), binary(), meta::any()} | {:error, term()}
  def split_up_to_newline(rest, meta, acc \\ [])

  def split_up_to_newline(<<>> = rest, meta, acc) do
    {:ok, IO.iodata_to_binary(Enum.reverse(acc)), rest, meta}
  end

  def split_up_to_newline(
    <<c1::utf8, c2::utf8, _rest::binary>> = rest,
    meta,
    acc
  ) when is_utf8_twochar_newline(c1, c2) do
    {:ok, IO.iodata_to_binary(Enum.reverse(acc)), rest, meta}
  end

  def split_up_to_newline(
    <<c::utf8, _rest::binary>> = rest,
    meta,
    acc
  ) when is_utf8_newline_like_char(c) do
    {:ok, IO.iodata_to_binary(Enum.reverse(acc)), rest, meta}
  end

  def split_up_to_newline(
    <<c::utf8, _rest::binary>>,
    _meta,
    _acc
  ) when is_utf8_disallowed_char(c) do
    {:error, {:disallowed_char, c}}
  end

  def split_up_to_newline(
    <<c::utf8, rest::binary>>,
    meta,
    acc
  ) when is_utf8_scalar_char(c) do
    split_up_to_newline(rest, add_meta_col(meta, utf8_char_byte_size(c)), [<<c::utf8>> | acc])
  end

  @spec split_by_newlines(binary(), [split_by_newlines_option()]) ::
    {[binary()], EDST.Tokens.token_meta()}
  def split_by_newlines(blob, meta, options \\ []) do
    do_split_by_newlines(blob, blob, meta, 0, [], options)
  end

  defp do_split_by_newlines(
    blob,
    <<>>,
    meta,
    _count,
    acc,
    _options
  ) do
    {Enum.reverse([blob | acc]), meta}
  end

  defp do_split_by_newlines(
    blob,
    <<c1::utf8, c2::utf8, _rest::binary>>,
    meta,
    count,
    acc,
    options
  ) when is_utf8_twochar_newline(c1, c2) do
    # count + utf8_char_byte_size(c1) + utf8_char_byte_size(c2)
    if options[:keep_newline] do
      count = count + utf8_char_byte_size(c1) + utf8_char_byte_size(c2)
      <<seg::binary-size(count), rest::binary>> = blob
      do_split_by_newlines(
        rest,
        rest,
        add_meta_line(meta),
        0,
        [seg | acc],
        options
      )
    else
      nl_size = utf8_char_byte_size(c1) + utf8_char_byte_size(c2)
      <<seg::binary-size(count), _nl::binary-size(nl_size), rest::binary>> = blob
      do_split_by_newlines(
        rest,
        rest,
        add_meta_line(meta),
        0,
        [seg | acc],
        options
      )
    end
  end

  defp do_split_by_newlines(
    blob,
    <<c::utf8, _rest::binary>>,
    meta,
    count,
    acc,
    options
  ) when is_utf8_newline_like_char(c) do
    if options[:keep_newline] do
      count = count + utf8_char_byte_size(c)
      <<seg::binary-size(count), rest::binary>> = blob
      do_split_by_newlines(
        rest,
        rest,
        add_meta_line(meta),
        0,
        [seg | acc],
        options
      )
    else
      nl_size = utf8_char_byte_size(c)
      <<seg::binary-size(count), _nl::binary-size(nl_size), rest::binary>> = blob
      do_split_by_newlines(
        rest,
        rest,
        add_meta_line(meta),
        0,
        [seg | acc],
        options
      )
    end
  end

  defp do_split_by_newlines(
    blob,
    <<c::utf8, rest::binary>>,
    meta,
    count,
    acc,
    options
  ) do
    do_split_by_newlines(
      blob,
      rest,
      add_meta_col(meta, utf8_char_byte_size(c)),
      count + utf8_char_byte_size(c),
      acc,
      options
    )
  end

  @doc """
  Variant of list_to_utf8_binary, but specifically for handling multiline strings
  """
  @spec multiline_list_to_utf8_binary(list()) :: {:ok, binary()} | {:error, term()}
  def multiline_list_to_utf8_binary(list) when is_list(list) do
    # need to flatten it first to unroll any sub-lists
    list = List.flatten(list)
    lines = split_multiline_list(list)

    case lines do
      [] ->
        {:ok, ""}

      [{:esc, _} | _lines] ->
        {:error, {:invalid_end_line, :line_contains_escaped_chars}}

      [{:uesc, chars}] ->
        # Handles empty multiline, but with last quote indented, we just determine if the
        # chars are spaces and then dump it
        case multiline_determine_spaces([0x0A | chars]) do
          {:error, reason} ->
            {:error, {:invalid_end_line, reason: reason, line: chars}}

          {:ok, _} ->
            {:ok, ""}
        end

      [{:uesc, chars} | lines] ->
        case multiline_determine_spaces(chars) do
          {:error, reason} ->
            {:error, {:invalid_end_line, reason: reason, line: chars}}

          {:ok, spaces} ->
            result =
              Enum.reduce_while(lines, {:ok, []}, fn {_, line}, {:ok, acc} ->
                case line do
                  [c1, c2 | line] when is_utf8_twochar_newline(c1, c2) ->
                    case dedent_multline_by_spaces(line, spaces) do
                      {:ok, line} ->
                        {:cont, {:ok, [[c1, c2 | line] | acc]}}

                      {:error, reason} ->
                        {:halt, {:error, {reason, line: line}}}
                    end

                  [c | line] when is_utf8_newline_like_char(c) ->
                    case dedent_multline_by_spaces(line, spaces) do
                      {:ok, line} ->
                        {:cont, {:ok, [[c | line] | acc]}}

                      {:error, reason} ->
                        {:halt, {:error, {reason, line: line}}}
                    end

                  line ->
                    case dedent_multline_by_spaces(line, spaces) do
                      {:ok, line} ->
                        {:cont, {:ok, [line | acc]}}

                      {:error, reason} ->
                        {:halt, {:error, {reason, line: line}}}
                    end
                end
              end)

            case result do
              {:error, _reason} = err ->
                err

              {:ok, lines} ->
                # and because we started with the lines reversed, this list is now in the correct
                # order
                {:ok, list_to_utf8_binary(lines)}
            end
        end
    end
  end

  def dedent_multline_by_spaces(left, right, state \\ :start)

  def dedent_multline_by_spaces([] = line, _, :start) do
    {:ok, line}
  end

  def dedent_multline_by_spaces([c | line], [c | spaces], _) do
    dedent_multline_by_spaces(line, spaces, :body)
  end

  def dedent_multline_by_spaces(line, [], _) do
    {:ok, line}
  end

  def dedent_multline_by_spaces(_, _, _) do
    {:error, :incomplete_dedentation}
  end

  def multiline_determine_spaces([c1, c2 | chars]) when is_utf8_twochar_newline(c1, c2) do
    do_multiline_determine_spaces(chars)
  end

  def multiline_determine_spaces([c | chars]) when is_utf8_newline_like_char(c) do
    do_multiline_determine_spaces(chars)
  end

  defp do_multiline_determine_spaces(chars, acc \\ [])

  defp do_multiline_determine_spaces([], acc) do
    {:ok, Enum.reverse(acc)}
  end

  defp do_multiline_determine_spaces([c | chars], acc) when is_utf8_space_like_char(c) do
    do_multiline_determine_spaces(chars, [c | acc])
  end

  defp do_multiline_determine_spaces([_c | _chars], _acc) do
    {:error, :expected_spaces}
  end

  @doc """
  Splits a multiline list, this will mark each line with its escape status, a line with a :esc
  status should not be used for whitespace trimming/dedent, as it was explictly set.

  One thing to note is all lines in the returned list start with a newline if its not the
  first line.

  The returned array is always reversed, so the last line will be first
  """
  @spec split_multiline_list([char_or_code()], esc_multiline(), [esc_multiline()]) ::
    [esc_multiline()]
  def split_multiline_list(list, line \\ {:uesc, []}, acc \\ [])

  def split_multiline_list([], {_status, []}, acc) when is_list(acc) do
    acc
  end

  def split_multiline_list([], {status, line}, acc) when is_list(line) and is_list(acc) do
    # commit the last line
    [{status, Enum.reverse(line)} | acc]
  end

  def split_multiline_list([{:esc, c} | list], {_status, line}, acc) do
    # the line contains an escape sequence, lines with escape sequences cannot be used for
    # dedent pattern, so if this is the _last_ line, it will be an error
    split_multiline_list(list, {:esc, [{:esc, c} | line]}, acc)
  end

  def split_multiline_list([c1, c2 | list], {status, line}, acc) when is_utf8_twochar_newline(c1, c2) do
    # CRLF - Carriage Return + Line Feed, standard Windows line ending
    split_multiline_list(list, {:uesc, [c2, c1]}, [{status, Enum.reverse(line)} | acc])
  end

  def split_multiline_list([c | list], {status, line}, acc) when is_utf8_newline_like_char(c) do
    # For everyone else, the single character line endings
    split_multiline_list(list, {:uesc, [c]}, [{status, Enum.reverse(line)} | acc])
  end

  def split_multiline_list([c | list], {status, line}, acc) do
    split_multiline_list(list, {status, [c | line]}, acc)
  end
end
