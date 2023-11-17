defmodule EDST.Tokens do
  import Record

  defrecord :token_meta, [line_no: 1, col_no: 1]

  defrecord :newline, [:unused, :meta]

  defrecord :header, [:value, :meta]

  defrecord :comment, [:value, :meta]

  defrecord :block_tag, [:value, :meta]

  defrecord :named_block, [:pair, :meta]

  defrecord :block, [:children, :meta]

  defrecord :tag, [:pair, :meta]

  defrecord :open_block, [:unused, :meta]

  defrecord :close_block, [:unused, :meta]

  defrecord :line_item, [:value, :meta]

  defrecord :label, [:value, :meta]

  defrecord :dialogue, [:pair, :meta]

  defrecord :quoted_string, [:value, :meta]

  defrecord :word, [:value, :meta]

  defrecord :p, [:children, :meta]
end
