<!-- markdownlint-disable -->

# Hardening Report: tj-actions--pg-dump/v3.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **tj-actions--pg-dump/v3.0** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

Multiple `uses:` references are pinned to mutable tags or branch names instead of immutable 40-character commit SHAs, making the action vulnerable to supply-chain attacks.

**action.yml:**
- `tj-actions/install-postgresql@v2`

**auto-approve.yml:**
- `hmarr/auto-approve-action@v3`

**codacy-analysis.yml:**
- `actions/checkout@v4`
- `codacy/codacy-analysis-cli-action@v4.3.0`
- `github/codeql-action/upload-sarif@v2`

**greetings.yml:**
- `actions/first-interaction@v1`

**rebase.yml:**
- `actions/checkout@v4`
- `cirrus-actions/rebase@1.8`

**sync-release-version.yml:**
- `actions/checkout@v4`
- `tj-actions/release-tagger@v4`
- `tj-actions/sync-release-version@v13`
- `tj-actions/git-cliff@v1`
- `peter-evans/create-pull-request@v5.0.2`

**test.yml:**
- `actions/checkout@v4`
- `reviewdog/action-shellcheck@v1.19`
- `tj-actions/verify-changed-files@v16`
- `ad-m/github-push-action@master`

**update-readme.yml:**
- `actions/checkout@v4`
- `tj-actions/auto-doc@v3`
- `tj-actions/remark@v3`
- `tj-actions/verify-changed-files@v16`
- `peter-evans/create-pull-request@v5`

Locations:

- `action.yml:21`
- `.github/workflows/auto-approve.yml:10`
- `.github/workflows/codacy-analysis.yml:30`
- `.github/workflows/codacy-analysis.yml:35`
- `.github/workflows/codacy-analysis.yml:45`
- `.github/workflows/greetings.yml:9`
- `.github/workflows/rebase.yml:10`
- `.github/workflows/rebase.yml:14`
- `.github/workflows/sync-release-version.yml:10`
- `.github/workflows/sync-release-version.yml:12`
- `.github/workflows/sync-release-version.yml:13`
- `.github/workflows/sync-release-version.yml:15`
- `.github/workflows/sync-release-version.yml:16`
- `.github/workflows/test.yml:19`
- `.github/workflows/test.yml:22`
- `.github/workflows/test.yml:47`
- `.github/workflows/test.yml:62`
- `.github/workflows/update-readme.yml:11`
- `.github/workflows/update-readme.yml:15`
- `.github/workflows/update-readme.yml:18`
- `.github/workflows/update-readme.yml:21`
- `.github/workflows/update-readme.yml:31`

### missing-permissions (severity: medium)

None of the workflow files define a top-level `permissions:` key, and no job within any of these files defines job-level `permissions:` either. Without explicit permissions, workflows run with the default (often broad) token permissions, violating the principle of least privilege.

Locations:

- `.github/workflows/auto-approve.yml:1`
- `.github/workflows/codacy-analysis.yml:1`
- `.github/workflows/greetings.yml:1`
- `.github/workflows/rebase.yml:1`
- `.github/workflows/sync-release-version.yml:1`
- `.github/workflows/test.yml:1`
- `.github/workflows/update-readme.yml:1`

### script-injection (severity: high)

Sub-rule (a): A `${{ matrix.postgresql_version }}` expression is interpolated directly inside a `run:` shell command string. Although `matrix` values are typically developer-controlled, any `${{ ... }}` expression inside a `run:` block is a script-injection risk because the value is substituted into the shell command before the shell parses it, allowing special characters to be interpreted. The offending line is:

```
git add backups/${{ matrix.postgresql_version }}/backup.sql
```

This should be replaced with an env-var reference (e.g. `env: PG_VERSION: ${{ matrix.postgresql_version }}`) and then `"$PG_VERSION"` used inside the script.

Locations:

- `.github/workflows/test.yml:57`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, missing-permissions, script-injection

**Notes:**

Fixed all three findings:

1. **unpinned-uses**: Pinned all `uses:` references to full 40-char commit SHAs with original tags as comments:
   - action.yml: tj-actions/install-postgresql@v2 → @0eb77dc75e7388ffdbc8542800cb55de1a935d29
   - auto-approve.yml: hmarr/auto-approve-action@v3 → @7d0ab8fdbb906da8a6297d373561d5ccb137d98f
   - codacy-analysis.yml: actions/checkout@v4 → @11d5960..., codacy/codacy-analysis-cli-action@v4.3.0 → @5cc54a7..., github/codeql-action/upload-sarif@v2 → @b8d3b6e...
   - greetings.yml: actions/first-interaction@v1 → @2ec0f0f...
   - rebase.yml: actions/checkout@v4 → @11d5960..., cirrus-actions/rebase@1.8 → @b87d481...
   - sync-release-version.yml: actions/checkout@v4, tj-actions/release-tagger@v4, tj-actions/sync-release-version@v13, tj-actions/git-cliff@v1, peter-evans/create-pull-request@v5.0.2 — all pinned
   - test.yml: actions/checkout@v4, reviewdog/action-shellcheck@v1.19, tj-actions/verify-changed-files@v16 (×2), ad-m/github-push-action@master (×2) — all pinned
   - update-readme.yml: actions/checkout@v4, tj-actions/auto-doc@v3, tj-actions/remark@v3, tj-actions/verify-changed-files@v16, peter-evans/create-pull-request@v5 — all pinned

2. **missing-permissions**: Added minimal `permissions:` blocks to all 7 workflow files at the top level.

3. **script-injection**: In test.yml, moved `${{ matrix.postgresql_version }}` out of the `git add` shell command into an `env:` block as `PG_VERSION`, then referenced it as `"$PG_VERSION"` in the run script.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Fixed the script injection vulnerability in entrypoint.sh (line 20). The unquoted `$INPUT_OPTIONS` expansion (`pg_dump $INPUT_OPTIONS ...`) was replaced with a safe array-based approach: `IFS=' ' read -ra pg_dump_options <<< "$INPUT_OPTIONS"` followed by `pg_dump "${pg_dump_options[@]}" ...`. The `read -ra` builtin splits on whitespace but does NOT interpret shell metacharacters (`;`, `|`, `$(...)`, backticks), preventing injection attacks. Each option element is then passed as a properly quoted separate argument via `"${pg_dump_options[@]}"`.

