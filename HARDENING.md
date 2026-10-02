<!-- markdownlint-disable -->

# Hardening Report: tj-actions--pg-dump/v3.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **tj-actions--pg-dump/v3.0** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

action.yml references `tj-actions/install-postgresql@v2`, which uses a mutable version tag (`@v2`) instead of a pinned 40-character commit SHA. This means the action could be silently replaced with malicious code on the next run without any change to the workflow file, enabling a supply-chain attack.

Locations:

- `action.yml:23`

### script-injection (severity: high)

Rule (b) violation: In `entrypoint.sh` line 20, the shell variable `$INPUT_OPTIONS` is expanded **unquoted** in the command `pg_dump $INPUT_OPTIONS -d "$INPUT_DATABASE_URL" > "$INPUT_PATH"`. `INPUT_OPTIONS` is populated from `inputs.options` (an attacker-controlled input) via the `env:` block in `action.yml`. The unquoted expansion allows the shell to parse metacharacters (`;`, `|`, `&`, `$(...)`, etc.) from the value, enabling command injection. The `# shellcheck disable=SC2086` comment on the preceding line confirms the author intentionally suppressed the shellcheck warning but does not mitigate the security risk. The fix is to quote the variable (`"$INPUT_OPTIONS"`) or use an array to pass options safely.

Locations:

- `entrypoint.sh:20`
- `action.yml:35`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection

**Notes:**

1. action.yml line 23: Pinned `tj-actions/install-postgresql@v2` to full SHA `0eb77dc75e7388ffdbc8542800cb55de1a935d29` with `# v2` comment for readability.
2. entrypoint.sh line 20: Replaced unquoted `$INPUT_OPTIONS` expansion (with shellcheck disable comment) with a safe xargs-based array tokenization pattern. The `options` input is a whitespace-separated list of pg_dump flags, so it uses the guarded `while IFS= read -r -d '' t; do options+=("$t"); done < <(printf '%s' "$INPUT_OPTIONS" | xargs printf '%s\0')` idiom to safely tokenize the value into a bash array, then expands it as `"${options[@]}"`. This prevents shell metacharacter injection (`;`, `|`, `&`, `$(...)`, etc.) while correctly handling quoted arguments within the options list.

