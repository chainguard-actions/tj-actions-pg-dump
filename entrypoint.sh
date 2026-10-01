#!/usr/bin/env bash

set -euo pipefail

echo "::group::pg-dump"

echo "Checking if the output directory exists..."

if [ ! -d "$(dirname "$INPUT_PATH")" ]; then
    echo "The output directory does not exist. Creating it..."
    mkdir -p "$(dirname "$INPUT_PATH")"
    echo "Created the output directory"
else
    echo "The output directory already exists"
fi

echo "Running pg_dump..."

pg_dump_opts=()
if [ -n "$INPUT_OPTIONS" ]; then
  while IFS= read -r -d '' t; do pg_dump_opts+=("$t"); done \
    < <(printf '%s' "$INPUT_OPTIONS" | xargs printf '%s\0')
fi
pg_dump "${pg_dump_opts[@]}" -d "$INPUT_DATABASE_URL" > "$INPUT_PATH"

echo "Complete"

echo "::endgroup::"
