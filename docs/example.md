## Example

Earthen Description & Scenario Text, is a markup language specifically designed for writing playwright-like text:

```
And so they went, venturing into the great expanse of space, he looked at the frosted glass of his common spaceshit and sighed to himself.

  @ Astronaut "I could really do with a peanut butter and jelly sandwich right now."

```

In addition the language provides structured sections in the form of blocks and tags:

```
%%head
{
  %chapter 2
  %title The Second Going
  %%characters
  {
    %= Joe
  }
}
%%body
{
-- Imperm Column --

  Drawing my last card from my deck of forty cards, I watched in horror as it was the least expected one.

    @ Joe "I've drawn the out!"

  Activating it in my central spell and trap zone, I smiled to myself, there was no way my opponent could counter this, or at least I hoped not.

  To my horror, his trap card was none other than Infinite Impermanence, in the same column as my feather duster.

  Watching as my spell fizzled out and hit the graveyard, I placed my hand down and lowered my head in shame.

  This dog had bested me at a children's card game.

-- --
}
%date 2022-11-27
```

The above is an example of a standard chapter structure used when writing stories.

It uses two blocks `head` and `body`, and a root level `date` tag.

Within the head are the `chapter`, and `title` tags which provide information on that chapter.

The `characters` block is primarily used for quick-reference to find out which characters or actors are present in the chapter.
