defmodule EDST.UtilsTest do
  use ExUnit.Case

  import EDST.Tokens

  describe "split_by_newlines/2" do
    test "can split a string by newlines" do
      assert {[""], _} = EDST.Utils.split_by_newlines("", token_meta())
      assert {["", "", ""], _} = EDST.Utils.split_by_newlines("\n\n", token_meta())
      assert {["a", "b", "c"], _} = EDST.Utils.split_by_newlines("a\nb\nc", token_meta())
      assert {["a", "b", "c"], _} = EDST.Utils.split_by_newlines("a\r\nb\r\nc", token_meta())
      assert {["a\r\n", "b\r\n", "c"], _} = EDST.Utils.split_by_newlines("a\r\nb\r\nc", token_meta(), keep_newline: true)
    end
  end
end
