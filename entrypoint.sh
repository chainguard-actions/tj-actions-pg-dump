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

# Parse INPUT_OPTIONS into an array to prevent shell metacharacter injection
# while still allowing multiple space-separated flags (e.g. "-O -Fc --no-acl").
IFS=' ' read -ra pg_dump_options <<< "$INPUT_OPTIONS"
pg_dump "${pg_dump_options[@]}" -d "$INPUT_DATABASE_URL" > "$INPUT_PATH"

echo "Complete"

echo "::endgroup::"
