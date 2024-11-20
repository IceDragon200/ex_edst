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
        comment(meta: token_meta(line_no: 1)),
        comment(value: " Comment", meta: token_meta(line_no: 2)),
        comment(meta: token_meta(line_no: 3)),
        named_block(pair: {"head", [
          tag(pair: {"title", "Test Document"}, meta: token_meta(line_no: 6)),
        ]}, meta: token_meta(line_no: 4)),
        named_block(pair: {"body", [
          p(children: [
            word(value: "Contents"),
            word(value: "of"),
            word(value: "test"),
            word(value: "document"),
          ], meta: token_meta(line_no: 10)),
        ]}, meta: token_meta(line_no: 8)),
      ] = tokens
    end
  end
end
