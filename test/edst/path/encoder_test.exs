defmodule EDST.Path.EncoderTest do
  use ExUnit.Case, async: true

  alias EDST.Path.Encoder

  @operators [
    equals: "=",
    iequals: "~=",
    contains: "#",
    icontains: "~#",
    starts_with: "#>",
    istarts_with: "~#>",
    ends_with: ">#",
    iends_with: "~>#",
  ]

  describe "encode/1" do
    test "can encode a simple path" do
      assert {:ok, "thing"} = Encoder.encode(["thing"])
    end

    test "can encode a quoted string for path" do
      assert {:ok, "\":thing\""} = Encoder.encode([":thing"])
    end

    test "can encode a node path" do
      assert {:ok, "@named_block"} = Encoder.encode([:named_block])
    end

    test "can encode a node with name" do
      assert {:ok, "@named_block:head"} = Encoder.encode([{:named_block, "head"}])
    end

    test "can encode a node with name and value" do
      assert {:ok, "@tag:id:2"} = Encoder.encode([{:tag, "id", "2"}])
    end

    for {name, symbol} <- @operators do
      test "can encode a node name and value with operators (#{symbol})" do
        assert {:ok, "@tag#{unquote(symbol)}id#{unquote(symbol)}2"} =
          Encoder.encode([{:tag, {{:op, unquote(name)}, "id"}, {{:op, unquote(name)}, "2"}}])
      end

      test "can encode operator #{name} as #{symbol}" do
        assert {:ok, "#{unquote(symbol)}value"} == Encoder.encode([{{:op, unquote(name)}, "value"}])
      end
    end
  end
end
