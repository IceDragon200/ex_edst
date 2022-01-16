defmodule EDST.Path.ParserTest do
  use ExUnit.Case, async: true

  alias EDST.Path.Parser

  describe "parse/1" do
    test "can parse a simple path" do
      assert {:ok, ["john"]} = Parser.parse("john")
    end

    test "can parse a node type path" do
      assert {:ok, [:named_block]} = Parser.parse("@named_block")
    end

    test "can parse a node type path with value" do
      assert {:ok, [{:named_block, "head"}]} = Parser.parse("@named_block:head")
    end

    test "can parse a node type path with multiple values" do
      assert {:ok, [{:dialogue, "Narrator", {{:op, :contains}, "Feed the beast already!"}}]} = Parser.parse("@dialogue:Narrator#\"Feed the beast already!\"")
    end

    test "can parse multiple terms" do
      assert {:ok, [
        {:named_block, "head"},
        {:tag, "id", {{:op, :equals}, "2"}}
      ]} = Parser.parse("@named_block:head @tag:id=2")

      assert {:ok, [
        {:named_block, "head"},
        {:tag, "id", "2"}
      ]} = Parser.parse("@named_block:head\n@tag:id:2")

      assert {:ok, [
        {:named_block, {{:op, :equals}, "head"}},
        {:tag, "id", "2"}
      ]} = Parser.parse("@named_block=head\n@tag:id:2")

      assert {:ok, [
        {:tag, {{:op, :icontains}, "id"}, {{:op, :equals}, "2"}}
      ]} = Parser.parse("@tag~#id=2")
    end

    test "can handle aliases forms" do
      assert {:ok, [
        {:named_block, "head"},
        {:tag, "id", {{:op, :equals}, "2"}}
      ]} = Parser.parse("%%head %id=2")
    end

    test "can parse a comparison path" do
      assert {:ok, [{{:op, :equals}, "thing"}]} = Parser.parse("=thing")
      assert {:ok, [{{:op, :contains}, "thing"}]} = Parser.parse("#thing")
      assert {:ok, [{{:op, :starts_with}, "thing"}]} = Parser.parse("#>thing")
      assert {:ok, [{{:op, :ends_with}, "thing"}]} = Parser.parse(">#thing")

      assert {:ok, [{{:op, :iequals}, "thing"}]} = Parser.parse("~=thing")
      assert {:ok, [{{:op, :icontains}, "thing"}]} = Parser.parse("~#thing")
      assert {:ok, [{{:op, :istarts_with}, "thing"}]} = Parser.parse("~#>thing")
      assert {:ok, [{{:op, :iends_with}, "thing"}]} = Parser.parse("~>#thing")
    end
  end
end
