defmodule EDST.Path do
  @moduledoc """
  Path utilities for finding specific blocks or tags within a token list.
  """
  @type token :: EDST.Parser.token()

  @type tag_name :: String.t()

  @type label_name :: String.t()

  @type named_block_name :: String.t()

  @type node_type :: :header
                   | :comment
                   | :tag
                   | :line_item
                   | :dialogue
                   | :quoted_string
                   | :label
                   | :named_block
                   | :block
                   | :p

  @typedoc """
  By default the find_nodes will lookup named blocks, tags or labels by
  their name or effective value.
  """
  @type value_matcher :: String.t()

  @typedoc """
  The fuzzy matchers can be used to match, or partially match a node's value

  == equals
  ~= case insensitive equals

  """
  @type fuzzy_matcher :: {{:op, :equals}, value_matcher()}
                       | {{:op, :iequals}, value_matcher()}
                       | {{:op, :contains}, value_matcher()}
                       | {{:op, :icontains}, value_matcher()}
                       | {{:op, :starts_with}, value_matcher()}
                       | {{:op, :istarts_with}, value_matcher()}
                       | {{:op, :ends_with}, value_matcher()}
                       | {{:op, :iends_with}, value_matcher()}

  @type content_matcher :: value_matcher() | fuzzy_matcher()

  @typedoc """
  Node matchers allow looking up a specific node with a selected name.

  The four element tuple is used specifically for dialogue nodes in order to search for the
  speaker and contents.
  """
  @type node_matcher :: {node_type(), content_matcher()}
                      | {:dialogue, speaker::content_matcher(), body::content_matcher()}
                      | {:tag, name::content_matcher(), value::content_matcher()}

  @typedoc """
  These are all the selectors supported by the find nodes function.

  Fuzzy and value selectors will only check the names of named_blocks, tags and labels.

  In order to search other nodes, they must be specified either with the 2 element tuple
  or 3 element tuple.
  """
  @type matcher :: value_matcher()
                 | fuzzy_matcher()
                 | node_type()
                 | node_matcher()

  @typedoc """
  An EDST path is comprised of a list of selectors
  """
  @type t :: [matcher()]

  @spec decode_path(String.t()) :: {:ok, t()}
  def decode_path(path) when is_binary(path) do
    EDST.Path.Parser.parse(path)
  end

  @spec encode_path(t()) :: String.t()
  def encode_path(path) when is_list(path) do
    EDST.Path.Encoder.encode(path)
  end

  @spec find_nodes([token()], t()) :: [token()]
  def find_nodes(tokens, matchers) do
    matchers
    |> Enum.reduce(tokens, fn matcher, tokens ->
      do_find_nodes(tokens, matcher, [])
    end)
  end

  defp matches_value?({:op, :equals}, base, expected) do
    base == expected
  end

  defp matches_value?({:op, :iequals}, base, expected) do
    String.downcase(base) == String.downcase(expected)
  end

  defp matches_value?({:op, :contains}, base, expected) do
    String.contains?(base, expected)
  end

  defp matches_value?({:op, :icontains}, base, expected) do
    String.contains?(String.downcase(base), String.downcase(expected))
  end

  defp matches_value?({:op, :starts_with}, base, expected) do
    String.starts_with?(base, expected)
  end

  defp matches_value?({:op, :istarts_with}, base, expected) do
    String.starts_with?(String.downcase(base), String.downcase(expected))
  end

  defp matches_value?({:op, :ends_with}, base, expected) do
    String.ends_with?(base, expected)
  end

  defp matches_value?({:op, :iends_with}, base, expected) do
    String.ends_with?(String.downcase(base), String.downcase(expected))
  end

  defp node_matches(token, {:>, matcher}) do
    case node_matches(token, matcher) do
      true ->
        :immediate

      rest ->
        rest
    end
  end

  defp node_matches(token, {name, matcher}) when is_atom(name) do
    case token do
      {^name, _, _} ->
        node_matches(token, matcher)

      {_, _, _} ->
        false
    end
  end

  defp node_matches(token, {{:op, _} = op, name}) when is_binary(name) do
    case token do
      {:header, value, _} -> matches_value?(op, value, name)
      {:comment, value, _} -> matches_value?(op, value, name)
      {:line_item, value, _} -> matches_value?(op, value, name)
      {:label, value, _} -> matches_value?(op, value, name)
      {:tag, {value, _}, _} -> matches_value?(op, value, name)
      {:dialogue, {value, _}, _} -> matches_value?(op, value, name)
      {:quoted_string, value, _} -> matches_value?(op, value, name)
      {:named_block, {value, _children}, _} ->
        if matches_value?(op, value, name) do
          true
        else
          :has_children
        end
      {:block, _children, _} -> :has_children
      {:p, _children, _} -> :has_children
      {:word, value, _} -> matches_value?(op, value, name)
    end
  end

  defp node_matches(token, name) when is_binary(name) do
    node_matches(token, {{:op, :equals}, name})
  end

  defp node_matches(token, name) when is_atom(name) do
    case token do
      {^name, _, _} ->
        true

      _ ->
        false
    end
  end

  defp get_children({:p, children, _}) do
    children
  end

  defp get_children({:block, children, _}) do
    children
  end

  defp get_children({:named_block, {_name, children}, _}) do
    children
  end

  defp get_children({_, _, _}) do
    []
  end

  defp do_find_nodes([], _matcher, acc) do
    Enum.reverse(acc)
  end

  defp do_find_nodes([token | tokens], matcher, acc) do
    acc =
      case node_matches(token, matcher) do
        true -> # matches the specified token
          acc = [token | acc]

          case get_children(token) do
            [] ->
              acc

            children when is_list(children) ->
              do_find_nodes(children, matcher, acc)
          end

        :has_children -> # doesn't match, but does have children
          case get_children(token) do
            [] ->
              acc

            children when is_list(children) ->
              do_find_nodes(children, matcher, acc)
          end

        :immediate -> # immediate match, don't check any children
          [token | acc]

        false ->
          acc
      end

    do_find_nodes(tokens, matcher, acc)
  end
end
