# Mode decisions

## How modes are selected

1. User passes `--mode=X` explicitly → use X.
2. Target file `lib/pages/<slug>.dart` exists AND `--force` not set → force `--mode=incremental`. Announce.
3. Otherwise → default `--mode=safe`.

## safe (default for new files)

- Pause after every phase for user confirmation.
- Show the artifact (summary.md, diff-report.md) before the pause.
- User can: `continue`, `skip`, `abort`.

## fast

- Auto-chain Phase 1 → 2 → 3.
- Pause after Phase 0 (to confirm align-table is reasonable) and after Phase 4 (to review verdict).

## auto

- Run all 5 phases without pausing. Suitable for demos.
- On Phase 4 `yellow`, automatically retry Phase 2 once on diff-hit nodes.
- On Phase 4 `red`, finalize anyway with prominent warning.

## incremental (auto-selected for existing files)

- Skip Phase 1.
- Run Phase 0 → Phase 4 first.
- If verdict is `green`: emit "UI matches design, no changes." Do not modify the dart file.
- If `yellow` / `red`: run Phase 2 limited to diff-hit nodes, then re-run Phase 4. Max 2 rounds.
- Phase 3 (assets) runs only if new assets are referenced in the HTML that aren't present in `assets/`.

## --force opts out of incremental

If `--force` is passed even though the file exists, treat the file as if it didn't exist. Backup the original to `<file>.bak` before overwriting (`.bak` is not committed; suggest user diff before discarding).
