# Owner B test artifact

Independent quarter-turn mapping for source pixels

```text
R G
B Y
M C
```

Clockwise `(x', y') = (height - 1 - y, x)`:

```text
M B R
C Y G
```

Counterclockwise negative control `(x', y') = (y, width - 1 - x)`:

```text
G Y C
R B M
```

The integration test checks all six coordinates in each result and alpha 255. Inverse direction preserves output dimensions and the color multiset, so it must fail the clockwise spatial oracle.
