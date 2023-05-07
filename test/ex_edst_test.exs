defmodule EDSTTest do
  use ExUnit.Case, async: true

  describe "parse" do
    test "can parse an empty label" do
      assert {:ok, [{:label, "", _}], []} = EDST.parse("-- --")
    end

    test "can parse a label with contents" do
      assert {:ok, [{:label, "Something", _}], []} = EDST.parse("-- Something --")
      assert {:ok, [{:label, "A label with multiple words", _}], []} = EDST.parse("-- A label with multiple words --")
    end

    test "can correctly split words into paragraphs" do
      assert {:ok, tokens, []} = EDST.parse("""
      Some data on a line.

      And then another paragraph,
      this line should be treated as a part of the same paragraph.
      """)

      assert [
        {:p, [
          {:word, "Some", _},
          {:word, "data", _},
          {:word, "on", _},
          {:word, "a", _},
          {:word, "line.", _},
        ], _},
        {:p, [
          {:word, "And", _},
          {:word, "then", _},
          {:word, "another", _},
          {:word, "paragraph,", _},
          {:word, "this", _},
          {:word, "line", _},
          {:word, "should", _},
          {:word, "be", _},
          {:word, "treated", _},
          {:word, "as", _},
          {:word, "a", _},
          {:word, "part", _},
          {:word, "of", _},
          {:word, "the", _},
          {:word, "same", _},
          {:word, "paragraph.", _},
        ], _},
      ] = tokens
    end

    test "can handle quoted strings" do
      assert {:ok, tokens, []} = EDST.parse("""
      "Hello, World"
      """)

      assert [
        {:p, [{:quoted_string, "Hello, World", _}], _},
      ] = tokens
    end

    test "can handle quoted strings with nested quotes" do
      assert {:ok, tokens, []} = EDST.parse("""
      "And he said: \\"Bake me a cake\\""
      """)

      assert [
        {:p, [{:quoted_string, "And he said: \"Bake me a cake\"", _}], _},
      ] = tokens
    end

    test "can parse a simple document" do
      assert {:ok, tokens, []} = EDST.parse("""
      # Comment
      -- This is a label --

        Some body content

          @ Speaker "Some dialogue"

        Some more "body content".

      -- --
      """)

      assert [
        {:comment, " Comment", _},
        {:label, "This is a label", _},
        {:p, [
          {:word, "Some", _},
          {:word, "body", _},
          {:word, "content", _},
        ], _},
        {:dialogue, {"Speaker", "Some dialogue"}, _},
        {:p, [
          {:word, "Some", _},
          {:word, "more", _},
          {:quoted_string, "body content", _},
          {:word, ".", _},
        ], _},
        {:label, "", _},
      ] = tokens
    end
  end
end
