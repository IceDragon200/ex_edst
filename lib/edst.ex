defmodule EDST do
  @type tokens :: EDST.Parser.tokens()

  defdelegate tokenize(binary), to: EDST.Tokenizer

  defdelegate parse(binary), to: EDST.Parser

  defdelegate parse!(binary), to: EDST.Parser

  defdelegate find_nodes(tokens, path), to: EDST.Path
end
