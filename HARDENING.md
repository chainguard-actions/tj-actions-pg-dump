<!-- markdownlint-disable -->

# Hardening Report: tj-actions--pg-dump/v3.0.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **tj-actions--pg-dump/v3.0.1** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The composite action step uses `tj-actions/install-postgresql@v3`, which is pinned to a mutable version tag rather than an immutable 40-character commit SHA. A tag can be silently moved to point to different (potentially malicious) code, enabling supply-chain attacks.

Locations:

- `action.yml:23`

### script-injection (severity: high)

Rule (b) violation: In `entrypoint.sh` line 19, the shell variable `$INPUT_OPTIONS` is expanded **unquoted** in the command `pg_dump $INPUT_OPTIONS -d "$INPUT_DATABASE_URL" > "$INPUT_PATH"`. `INPUT_OPTIONS` is populated directly from the attacker-controllable `inputs.options` value (set in the `env:` block of `action.yml`). An unquoted expansion allows the shell to parse metacharacters (`;`, `|`, `&`, `$(...)`, backticks, glob chars, whitespace) out of the value, enabling command injection. The `# shellcheck disable=SC2086` comment acknowledges the word-splitting but does not mitigate the security risk.

Locations:

- `entrypoint.sh:19`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection

**Notes:**

1. action.yml: Pinned `tj-actions/install-postgresql@v3` to full commit SHA `a889ed6c6fa05022333ed4101295bb1d604f97a8` with `# v3` comment for readability.
2. entrypoint.sh: Replaced the unsafe unquoted `$INPUT_OPTIONS` expansion (with `# shellcheck disable=SC2086`) with a safe xargs-based tokenization into a bash array. The array is built using `printf '%s' "$INPUT_OPTIONS" | xargs printf '%s\0'` with a null-delimited read loop, which handles quoted arguments correctly and prevents shell metacharacters from being interpreted. The array is then expanded with `"${pg_dump_opts[@]}"` in the pg_dump call.

