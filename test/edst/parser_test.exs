defmodule EDST.ParserTest do
  use ExUnit.Case, async: true

  import EDST.Tokens

  describe "parse/1" do
    test "can parse an edst document from a string" do
      assert {:ok, tokens, []} =
        EDST.Parser.parse("""
          #
          # Comment
          #
          %%head
          {
            %title Test Document
          }
          %%body
          {
            Contents of test document
          }
          """)

      assert [
        comment(),
        comment(value: " Comment"),
        comment(),
        named_block(pair: {"head", [
          tag(pair: {"title", "Test Document"}),
        ]}),
        named_block(pair: {"body", [
          p(children: [
            word(value: "Contents"),
            word(value: "of"),
            word(value: "test"),
            word(value: "document"),
          ]),
        ]}),
      ] = tokens
    end
  end
end
