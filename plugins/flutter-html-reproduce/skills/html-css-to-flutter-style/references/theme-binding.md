# Theme binding via align-table

## Rule

For each computed Flutter property value V:
1. Look up V in `align-table.md`. If matched, replace the literal with the project Theme reference.
2. Else, emit the literal AND add `// TODO: theme gap — consider adding to lib/theme/` as a trailing comment on the line.

## Examples

### Matched color
```dart
// Before (hardcoded)
BoxDecoration(color: Color(0xFF1976D2))

// After (align-table hit on #1976d2 → colorScheme.primary)
BoxDecoration(color: Theme.of(context).colorScheme.primary)
```

### Matched text style
```dart
// Before
Text('Title', style: TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w700))

// After (matched against textTheme.displaySmall)
Text('Title', style: Theme.of(context).textTheme.displaySmall)
```

### Partial match — override the rest
```dart
// align-table hits textTheme.bodyLarge for size+family+weight, but not color
Text('Note',
  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
    color: Color(0xFF7C4DFF), // TODO: theme gap
  ),
)
```

## Strict rules

- Theme.of must use `Theme.of(context)` (full form) — never short-circuit imports.
- For widgets that don't have a `BuildContext` in scope (`StatelessWidget` constructor list, top-level constants), the binding gracefully falls back to literal + theme-gap comment. The widget code in Phase 1 always has a build method context, so this rarely matters.
- Never bind `EdgeInsets` to a theme spacing scale unless the project defines a `Spacing` ThemeExtension with named members — implicit "8 = theme.spacing.s2" mapping is too fragile and would silently change semantics.
