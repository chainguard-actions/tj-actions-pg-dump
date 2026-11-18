<!-- markdownlint-disable -->

# Hardening Report: tj-actions--pg-dump/v3.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **tj-actions--pg-dump/v3.0** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The composite action step uses a mutable tag instead of a full 40-character commit SHA: `uses: tj-actions/install-postgresql@v2`. Pin it to a commit SHA, for example `tj-actions/install-postgresql@<40-hex-sha> # v2`.

Locations:

- `action.yml:22`

### script-injection (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. Rule (b) violation: In `entrypoint.sh` line 20, the shell variable `$INPUT_OPTIONS` is expanded **unquoted** in the command `pg_dump $INPUT_OPTIONS -d "$INPUT_DATABASE_URL" > "$INPUT_PATH"`. `INPUT_OPTIONS` is populated from `inputs.options` (an attacker-controlled input) via the `env:` block in `action.yml`. The unquoted expansion allows the shell to parse metacharacters (`;`, `|`, `&`, `$(...)`, etc.) from the value, enabling command injection. The `# shellcheck disable=SC2086` comment on the preceding line confirms the author intentionally suppressed the shellcheck warning but does not mitigate the security risk. The fix is to quote the variable (`"$INPUT_OPTIONS"`) or use an array to pass options safely.

Locations:

- `entrypoint.sh:20`
- `action.yml:35`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed action.yml without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/action.yml b/action.yml
index bd2f201..a0a5b91 100644
--- a/action.yml
+++ b/action.yml
@@ -2,7 +2,7 @@ name: pg-dump
 description: Run pg_dump to generate a backup
 author: tj-actions
 inputs:
-  postgresql_version: 
+  postgresql_version:
     description: 'Version of PostgreSQL. e.g 15'
     required: false
   database_url:
@@ -15,12 +15,28 @@ inputs:
     description: 'Extra [options](https://www.postgresql.org/docs/current/app-pgdump.html#PG-DUMP-OPTIONS) passed to pg_dump'
     required: true
     default: '-O'
-
 runs:
   using: 'composite'
   steps:
     - name: Setup PostgreSQL
       uses: tj-actions/install-postgresql@v2
       if: inputs.postgresql_version != ''
       with:
         postgresql-version: ${{ inputs.postgresql_version }}

```

Locations:

- `action.yml`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed entrypoint.sh without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/entrypoint.sh b/entrypoint.sh
index 6afb598..026c78a 100755
--- a/entrypoint.sh
+++ b/entrypoint.sh
@@ -16,8 +16,12 @@ fi
 
 echo "Running pg_dump..."
 
-# shellcheck disable=SC2086
-pg_dump $INPUT_OPTIONS -d "$INPUT_DATABASE_URL" > "$INPUT_PATH"
+options=()
+if [ -n "$INPUT_OPTIONS" ]; then
+  while IFS= read -r -d '' t; do options+=("$t"); done \
+    < <(printf '%s' "$INPUT_OPTIONS" | xargs printf '%s\0')
+fi
+pg_dump "${options[@]}" -d "$INPUT_DATABASE_URL" > "$INPUT_PATH"
 
 echo "Complete"
 

```

Locations:

- `entrypoint.sh`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, prior-fix

**Notes:**

I pinned tj-actions/install-postgresql to commit 0eb77dc75e7388ffdbc8542800cb55de1a935d29 (# v2). I also redid the earlier action.yml whitespace cleanup and put quotes around the $GITHUB_ACTION_PATH entrypoint path. In entrypoint.sh, pg_dump now gets its options from an array built with options=(${INPUT_OPTIONS:-}). This splits the value on whitespace and expands wildcards exactly like upstream's unquoted $INPUT_OPTIONS, and it never runs ;, |, $(...) or backticks found in the value. The array is passed as ${options[@]+"${options[@]}"} so an empty value adds no argument, even under set -u on older bash. I did not re-apply the earlier xargs-based split on purpose. It would treat quotes in the value differently from upstream, and an apostrophe would silently drop the remaining options. Quoting "$INPUT_OPTIONS" as one value, as the finding suggests, would hand pg_dump all the options as a single argument and break the action. I did not run the action or its tests.

