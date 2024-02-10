## Block

A block is a slighty more complex element which is actually made up of three primitives.

The first is the tag-like element denoted by a line with `%%` followed by a name, like tags the name
is everything up till the newline.

It is immediately followed by an opening brace `{` followed by a newline and then can contain any document elements and finally closed by `}` on a line by itself.

Blocks can be nested inside other blocks.

And the block tag cannot be used without its braces.

### Example

```
%%head
{
  %title Some title
}
%%body
{
  Contents here.
}
```
