defmodule EDST.TokenizerTest do
  use ExUnit.Case

  alias EDST.Tokenizer, as: Subject

  describe "tokenize/1" do
    test "can tokenize a quoted string" do
      assert {:ok, tokens} = Subject.tokenize("\"Hello, World\"")

      assert [
        {:quoted_string, "Hello, World", _debug}
      ] = tokens
    end

    test "can tokenize a quoted string with nested quotes" do
      assert {:ok, tokens} = Subject.tokenize("\"And he said: \\\"Bake me a cake\\\"\"")

      assert [
        {:quoted_string, "And he said: \"Bake me a cake\"", _debug}
      ] = tokens
    end

    test "can tokenize a heredoc" do
      assert {:ok, tokens} = Subject.tokenize("""
          \"\"\"
          Abc
          def
          \"\"\"
      """)
      assert [
        {:quoted_string, "Abc\ndef", _},
        {:newline, _, _},
      ] = tokens
    end

    test "can tokenize a quoted string with embedded newlines" do
      assert {:ok, tokens} = Subject.tokenize("""
      "Abc
      def"
      """)
      assert [
        {:quoted_string, "Abc\ndef", _},
        {:newline, _, _},
      ] = tokens
    end
  end
end
