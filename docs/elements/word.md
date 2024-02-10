## Word

A word is any unbroken sequence of characters not recognized as any other available element.

An unbroken sequence is any valid list of utf8 scalars that are neither spaces nor newlines.

Word will typically be folded into a paragraph `p` element during parsing to make handling them easier.

### Example

```
These are all words, the punctuation from before is apart of the word as well.
```
