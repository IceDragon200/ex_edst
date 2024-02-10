## Heredoc

__Since__ 5.0

Heredocs are quoted strings denoted by a starting `"""` followed immediately by a newline then
zero or more valid string characters and a closing `"""` on a newline.

Note that the contents of the string will be trimmed by the non-escaped space on the last line.

### Examples

The most basic example of a heredoc is the following:

```
"""
Contents
"""
```

Which is equivalent to:

```
"Contents"
```

A heredoc has the advantage of stripping spaces based on the final line in the heredoc itself:

```
  """
  ABC
  """

  """
    ABC
      DEF
        GHI
    """
```

Results in:

```
"ABC"
"ABC\n  DEF\n    GHI"
```

