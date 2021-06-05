defmodule EDST.Path.TokenizerTest do
  use ExUnit.Case

  alias EDST.Path.Tokenizer

  describe "tokenize/1" do
    test "can tokenize a simple path" do
      assert {:ok, [{:word, "john", _}]} = Tokenizer.tokenize("john")
    end

    test "can tokenize a node type path" do
      assert {:ok, [{:node, "john", _}]} = Tokenizer.tokenize("@john")
    end

    test "can tokenize a node named_block alias" do
      assert {:ok, [{:node_alias, "named_block", _}]} = Tokenizer.tokenize("%%")
    end

    test "can tokenize a node tag alias" do
      assert {:ok, [{:node_alias, "tag", _}]} = Tokenizer.tokenize("%")
    end

    test "can tokenize a path with subs" do
      assert {:ok, [{:word, "john", _}, {:sub, nil, _}, {:word, "abc", _}]} =
        Tokenizer.tokenize("john:abc")

      assert {:ok, [{:node, "john", _}, {:sub, nil, _}, {:word, "abc", _}]} =
        Tokenizer.tokenize("@john:abc")
    end

    test "can tokenize a path with comparison operators" do
      assert {:ok, [{:word, "john", _}, {:sub, nil, _}, {:word, "abc", _}, {:sub, nil, _}, {:word, "def", _}]} =
        Tokenizer.tokenize("john:abc:def")

      assert {:ok, [{:node, "john", _}, {:sub, nil, _}, {:word, "abc", _}, {:equals, nil, _}, {:word, "def", _}]} =
        Tokenizer.tokenize("@john:abc=def")

      assert {:ok, [{:node, "john", _}, {:sub, nil, _}, {:word, "abc", _}, {:iequals, nil, _}, {:word, "def", _}]} =
        Tokenizer.tokenize("@john:abc~=def")

      assert {:ok, [{:node, "john", _}, {:sub, nil, _}, {:word, "abc", _}, {:starts_with, nil, _}, {:word, "def", _}]} =
        Tokenizer.tokenize("@john:abc#>def")

      assert {:ok, [{:node, "john", _}, {:sub, nil, _}, {:word, "abc", _}, {:istarts_with, nil, _}, {:word, "def", _}]} =
        Tokenizer.tokenize("@john:abc~#>def")

      assert {:ok, [{:node, "john", _}, {:sub, nil, _}, {:word, "abc", _}, {:ends_with, nil, _}, {:word, "def", _}]} =
        Tokenizer.tokenize("@john:abc>#def")

      assert {:ok, [{:node, "john", _}, {:sub, nil, _}, {:word, "abc", _}, {:iends_with, nil, _}, {:word, "def", _}]} =
        Tokenizer.tokenize("@john:abc~>#def")

      assert {:ok, [{:node, "john", _}, {:sub, nil, _}, {:word, "abc", _}, {:contains, nil, _}, {:word, "def", _}]} =
        Tokenizer.tokenize("@john:abc#def")

      assert {:ok, [{:node, "john", _}, {:sub, nil, _}, {:word, "abc", _}, {:icontains, nil, _}, {:word, "def", _}]} =
        Tokenizer.tokenize("@john:abc~#def")
    end

    test "can tokenize quoted strings" do
      assert {:ok, [{:quoted_string, "Hello, World", _}]} = Tokenizer.tokenize("\"Hello, World\"")

      assert {:ok, [{:quoted_string, "Hello:World", _}, {:sub, nil, _}, {:quoted_string, "Goodbye:Universe", _}]} =
        Tokenizer.tokenize("\"Hello:World\":\"Goodbye:Universe\"")

      assert {:ok, [{:quoted_string, "Hello World", _}, {:sub, nil, _}, {:quoted_string, "Goodbye Universe", _}]} =
        Tokenizer.tokenize("\"Hello\nWorld\":\"Goodbye\r\nUniverse\"")
    end

    test "can parse multiple words" do
      assert {:ok, [{:word, "Hello", _}, {:space, nil, _}, {:word, "World", _}]} =
        Tokenizer.tokenize("Hello World")

      assert {:ok, [{:word, "Hello", _}, {:newline, nil, _}, {:word, "World", _}]} =
        Tokenizer.tokenize("Hello\r\nWorld")

      assert {:ok, [{:word, "Hello", _}, {:newline, nil, _}, {:word, "World", _}]} =
        Tokenizer.tokenize("Hello\nWorld")
    end
  end
end
