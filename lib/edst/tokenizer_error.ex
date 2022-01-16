defmodule EDST.TokenizerError do
  defexception [
    reason: nil
  ]

  def message(%{reason: reason}) do
    """
    Failed to tokenize given blob, caused by: #{inspect reason}
    """
  end
end
