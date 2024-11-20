defmodule EDST.TokenizerTest do
  use ExUnit.Case

  alias EDST.Tokenizer, as: Subject

  import EDST.Tokens

  describe "tokenize/1" do
    test "can tokenize a comment" do
      assert {:ok, tokens} = Subject.tokenize("# This is a comment")
      assert [
        {:comment, " This is a comment", token_meta(line_no: 1)}
      ] = tokens
    end

    test "can tokenize a multiline comment" do
      assert {:ok, tokens} = Subject.tokenize("""
      # This is a comment
      # This is also a comment
      # And this is lastly a comment
      """)
      assert [
        {:comment, " This is a comment", token_meta(line_no: 1)},
        {:newline, nil, token_meta(line_no: 1)},
        {:comment, " This is also a comment", token_meta(line_no: 2)},
        {:newline, nil, token_meta(line_no: 2)},
        {:comment, " And this is lastly a comment", token_meta(line_no: 3)},
        {:newline, nil, token_meta(line_no: 3)},
      ] = tokens
    end

    test "can tokenize a quoted string" do
      assert {:ok, tokens} = Subject.tokenize("\"Hello, World\"")

      assert [
        {:quoted_string, "Hello, World", token_meta(line_no: 1)}
      ] = tokens
    end

    test "can tokenize a quoted string with nested quotes" do
      assert {:ok, tokens} = Subject.tokenize("\"And he said: \\\"Bake me a cake\\\"\"")

      assert [
        {:quoted_string, "And he said: \"Bake me a cake\"", token_meta(line_no: 1)}
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
        {:quoted_string, "Abc\ndef", token_meta(line_no: 1)},
        {:newline, _, token_meta(line_no: 4)},
      ] = tokens
    end

    test "can tokenize a quoted string with embedded newlines" do
      assert {:ok, tokens} = Subject.tokenize("""
      "Abc
      def"
      """)
      assert [
        {:quoted_string, "Abc\ndef", token_meta(line_no: 1)},
        {:newline, _, token_meta(line_no: 2)},
      ] = tokens
    end
  end
end
