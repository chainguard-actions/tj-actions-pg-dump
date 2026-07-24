<!-- markdownlint-disable -->

# Hardening Report: tj-actions--pg-dump/v3.0.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **tj-actions--pg-dump/v3.0.1** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

Multiple files reference GitHub Actions and the composite action step using mutable tag or branch refs instead of immutable 40-character commit SHAs, making the action vulnerable to supply-chain attacks.

action.yml:
  - uses: tj-actions/install-postgresql@v3

.github/workflows/codacy-analysis.yml:
  - uses: actions/checkout@v4
  - uses: codacy/codacy-analysis-cli-action@v4.3.0
  - uses: github/codeql-action/upload-sarif@v3

.github/workflows/rebase.yml:
  - uses: actions/checkout@v4
  - uses: cirrus-actions/rebase@1.8

.github/workflows/sync-release-version.yml:
  - uses: actions/checkout@v4
  - uses: tj-actions/release-tagger@v4
  - uses: tj-actions/sync-release-version@v13
  - uses: tj-actions/git-cliff@v1
  - uses: peter-evans/create-pull-request@v5.0.2

.github/workflows/test.yml:
  - uses: actions/checkout@v4 (multiple)
  - uses: reviewdog/action-shellcheck@v1.19
  - uses: tj-actions/verify-changed-files@v17 (multiple)
  - uses: ad-m/github-push-action@master (branch ref!)

.github/workflows/update-readme.yml:
  - uses: actions/checkout@v4
  - uses: tj-actions/auto-doc@v3
  - uses: tj-actions/remark@v3
  - uses: tj-actions/verify-changed-files@v17
  - uses: peter-evans/create-pull-request@v5

Locations:

- `action.yml:21`
- `.github/workflows/codacy-analysis.yml:29`
- `.github/workflows/codacy-analysis.yml:34`
- `.github/workflows/codacy-analysis.yml:55`
- `.github/workflows/rebase.yml:10`
- `.github/workflows/rebase.yml:14`
- `.github/workflows/sync-release-version.yml:9`
- `.github/workflows/sync-release-version.yml:11`
- `.github/workflows/sync-release-version.yml:13`
- `.github/workflows/sync-release-version.yml:17`
- `.github/workflows/sync-release-version.yml:19`
- `.github/workflows/test.yml:18`
- `.github/workflows/test.yml:21`
- `.github/workflows/test.yml:42`
- `.github/workflows/test.yml:51`
- `.github/workflows/test.yml:63`
- `.github/workflows/test.yml:80`
- `.github/workflows/test.yml:91`
- `.github/workflows/test.yml:100`
- `.github/workflows/test.yml:109`
- `.github/workflows/update-readme.yml:11`
- `.github/workflows/update-readme.yml:15`
- `.github/workflows/update-readme.yml:18`
- `.github/workflows/update-readme.yml:21`
- `.github/workflows/update-readme.yml:33`

### missing-permissions (severity: medium)

None of the workflow files define a top-level `permissions:` key, and no individual job defines a `permissions:` block. Without explicit permissions, workflows run with the default (potentially broad) GITHUB_TOKEN permissions.

Locations:

- `.github/workflows/codacy-analysis.yml:1`
- `.github/workflows/rebase.yml:1`
- `.github/workflows/sync-release-version.yml:1`
- `.github/workflows/test.yml:1`
- `.github/workflows/update-readme.yml:1`

### script-injection (severity: high)

Sub-rule (a): A `run:` block in the `test-postgresql` job directly interpolates `${{ matrix.postgresql_version }}` inside a shell command. The matrix value flows through YAML template substitution before the shell sees it, allowing an attacker who controls the matrix (e.g. via a forked PR or workflow_dispatch) to inject arbitrary shell commands.

Offending line:
  git add backups/${{ matrix.postgresql_version }}/backup.sql

This expression should be moved to an `env:` variable and the shell variable should be double-quoted.

Locations:

- `.github/workflows/test.yml:57`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, missing-permissions, script-injection

**Notes:**

Fixed all three findings:

1. unpinned-uses: Pinned all action references to full 40-char commit SHAs across action.yml and all 5 workflow files. Notable: ad-m/github-push-action@master (branch ref) was pinned to its current master SHA.

2. missing-permissions: Added minimal top-level permissions blocks to all 5 workflow files: codacy-analysis.yml (contents:read, security-events:write), rebase.yml (contents:write, pull-requests:read), sync-release-version.yml (contents:write, pull-requests:write), test.yml (contents:write), update-readme.yml (contents:write, pull-requests:write).

3. script-injection: In test.yml's 'Commit changes to backup file' step, moved ${{ matrix.postgresql_version }} out of the run: shell into an env: block as POSTGRESQL_VERSION, then referenced it as "$POSTGRESQL_VERSION" in the git add command.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Fixed the script injection vulnerability in entrypoint.sh at line 20. Replaced the unquoted `$INPUT_OPTIONS` expansion (`pg_dump $INPUT_OPTIONS ...`) with a safe bash array approach: `IFS=' ' read -ra pg_dump_options <<< "$INPUT_OPTIONS"` followed by `pg_dump "${pg_dump_options[@]}" ...`. This prevents shell metacharacter injection (`;`, `|`, `&`, `$(...)`, backticks, etc.) while still allowing multiple space-separated pg_dump flags to be passed correctly. The SC2086 shellcheck disable comment was also removed since it's no longer needed.

