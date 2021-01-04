defmodule EDST do
  defdelegate parse(binary), to: EDST.Parser
end
