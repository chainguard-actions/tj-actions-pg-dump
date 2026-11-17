<!-- markdownlint-disable -->

# Hardening Report: tj-actions--pg-dump/v3.0.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **tj-actions--pg-dump/v3.0.1** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

action.yml composite step references an action by a mutable tag instead of a full 40-character commit SHA: `uses: tj-actions/install-postgresql@v3`.

Locations:

- `action.yml:22`

### script-injection (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. Rule (b) violation: In `entrypoint.sh` line 19, the shell variable `$INPUT_OPTIONS` is expanded **unquoted** in the command `pg_dump $INPUT_OPTIONS -d "$INPUT_DATABASE_URL" > "$INPUT_PATH"`. `INPUT_OPTIONS` is populated directly from the attacker-controllable `inputs.options` value (set in the `env:` block of `action.yml`). An unquoted expansion allows the shell to parse metacharacters (`;`, `|`, `&`, `$(...)`, backticks, glob chars, whitespace) out of the value, enabling command injection. The `# shellcheck disable=SC2086` comment acknowledges the word-splitting but does not mitigate the security risk.

Locations:

- `entrypoint.sh:19`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed action.yml without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/action.yml b/action.yml
index cf5d173..bd4882d 100644
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
       uses: tj-actions/install-postgresql@v3
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
index 6afb598..d6d4679 100755
--- a/entrypoint.sh
+++ b/entrypoint.sh
@@ -16,8 +16,12 @@ fi
 
 echo "Running pg_dump..."
 
-# shellcheck disable=SC2086
-pg_dump $INPUT_OPTIONS -d "$INPUT_DATABASE_URL" > "$INPUT_PATH"
+pg_dump_opts=()
+if [ -n "$INPUT_OPTIONS" ]; then
+  while IFS= read -r -d '' t; do pg_dump_opts+=("$t"); done \
+    < <(printf '%s' "$INPUT_OPTIONS" | xargs printf '%s\0')
+fi
+pg_dump "${pg_dump_opts[@]}" -d "$INPUT_DATABASE_URL" > "$INPUT_PATH"
 
 echo "Complete"
 

```

Locations:

- `entrypoint.sh`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, prior-fix

**Notes:**

I pinned tj-actions/install-postgresql to commit a889ed6c6fa05022333ed4101295bb1d604f97a8 (the v3 tag) and put quotes around $GITHUB_ACTION_PATH/entrypoint.sh in action.yml. I also re-applied the prior patch's whitespace tidy. In entrypoint.sh, the options are now split into a bash array with pg_dump_opts=($INPUT_OPTIONS) and passed as ${pg_dump_opts[@]+"${pg_dump_opts[@]}"}. That splits on whitespace and expands globs exactly as upstream's unquoted $INPUT_OPTIONS did, but nothing in the value is run: ;, |, $(...) and backticks reach pg_dump as plain text. The [@]+ form avoids an error under set -u when the options are empty on bash 3.2. I deliberately did not bring back the previous harden's xargs split. It handles quotes differently from upstream, can drop arguments after an apostrophe, and can lose tokens like --version to an external printf.

