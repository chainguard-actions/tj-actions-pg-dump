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

# Split INPUT_OPTIONS into separate arguments exactly as upstream's unquoted
# expansion did (whitespace split + glob). Nothing in the value is evaluated:
# ';', '|', '$(...)' and backticks stay literal argument text.
# shellcheck disable=SC2206
pg_dump_opts=($INPUT_OPTIONS)
pg_dump ${pg_dump_opts[@]+"${pg_dump_opts[@]}"} -d "$INPUT_DATABASE_URL" > "$INPUT_PATH"

echo "Complete"

echo "::endgroup::"
