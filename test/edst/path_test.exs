defmodule EDST.PathTest do
  use ExUnit.Case, async: true

  describe "find_nodes/2" do
    test "can extract nodes of specified type" do
      # this test is here mostly to ensure that find_nodes returns in the _correct_ order
      # at the time of this writing it had a bug where the nodes appeared randomly in list
      # not great for things like labels in chapters which require specific ordering
      blob = """
      %%body
      {
        -- A --

        Something

        -- --

        -- B --

        Other

        -- --

        -- C --

        Must

        -- --

        -- D --

        Happen

        -- --
      }
      """

      document = EDST.parse!(blob)

      labels = EDST.find_nodes(document, [:label])

      assert [
        {:label, "A", _},
        {:label, "", _},
        {:label, "B", _},
        {:label, "", _},
        {:label, "C", _},
        {:label, "", _},
        {:label, "D", _},
        {:label, "", _},
      ] = labels
    end
  end
end
