# Output format

Both `align-table.md` and `gaps.md` are rendered from the templates by simple
Mustache-style substitution (handlebars-compatible). The skill performs the
substitution in-memory; we do not pull in a templating library — the small
helper below is sufficient.

## Substitution helper (Python)

```python
def render(tmpl: str, ctx: dict) -> str:
    # Replace {{key}} scalars; {{#each list}} blocks; {{#if cond}} blocks.
    # ... (simple implementation; OK for our small templates)
```

## Strict rules

- Empty section ⇒ still render the heading, but show `_(none)_` row instead
  of the table (avoids confusing dangling header).
- All values inside backticks unless they're prose.
- Sort each table by HTML value for diff stability.
