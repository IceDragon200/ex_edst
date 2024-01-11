defmodule EDST.Utils do
  import EDST.Tokens

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
    split_spaces_and_newlines(rest, add_meta_col(meta, byte_size(<<c::utf8>>)), [<<c::utf8>> | acc])
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
    {:ok, IO.iodata_to_binary(Enum.reverse(acc)), rest, add_meta_line(meta)}
  end

  def split_up_to_newline(
    <<c::utf8, _rest::binary>> = rest,
    meta,
    acc
  ) when is_utf8_newline_like_char(c) do
    {:ok, IO.iodata_to_binary(Enum.reverse(acc)), rest, add_meta_line(meta)}
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
    split_up_to_newline(rest, add_meta_col(meta, byte_size(<<c::utf8>>)), [<<c::utf8>> | acc])
  end
end
