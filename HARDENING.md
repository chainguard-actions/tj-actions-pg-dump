<!-- markdownlint-disable -->

# Hardening Report: tj-actions--pg-dump/v3.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **tj-actions--pg-dump/v3.0** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

action.yml references `tj-actions/install-postgresql@v2`, which uses a mutable tag (`v2`) instead of a pinned 40-character commit SHA. This means the action could be silently updated to a different (potentially malicious) version without any change to this repository.

Locations:

- `action.yml:21`

### script-injection (severity: high)

Rule (b) violation: In entrypoint.sh, the shell variable `$INPUT_OPTIONS` is expanded **unquoted** in the command `pg_dump $INPUT_OPTIONS -d "$INPUT_DATABASE_URL" > "$INPUT_PATH"`. `INPUT_OPTIONS` is populated directly from `${{ inputs.options }}` (a user-controlled action input) via the `env:` block in action.yml. Because the variable is unquoted, an attacker can inject shell metacharacters (`;`, `|`, `$(...)`, etc.) through the `options` input to execute arbitrary commands. Fix: quote the variable as `"$INPUT_OPTIONS"` or use an array approach.

Locations:

- `entrypoint.sh:19`
- `action.yml:33`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection

**Notes:**

1. Pinned `tj-actions/install-postgresql@v2` to full SHA `0eb77dc75e7388ffdbc8542800cb55de1a935d29` in action.yml (line 21), preserving the tag as a comment.
2. Fixed script injection in entrypoint.sh: replaced the unquoted `$INPUT_OPTIONS` expansion with a bash array populated via xargs-based quote-aware tokenization. The `if [ -n "$INPUT_OPTIONS" ]` guard prevents an empty argument when the variable is empty. The array is then expanded as `"${options[@]}"` so each token remains a separate, properly-quoted argument to pg_dump, preventing shell metacharacter injection.

