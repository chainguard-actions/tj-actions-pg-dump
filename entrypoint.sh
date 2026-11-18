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

# Split the options list exactly as upstream's unquoted $INPUT_OPTIONS did
# (whitespace split + glob). Word splitting does not evaluate ';', '|',
# '$(...)' or backticks in the value, so nothing in it is executed.
# shellcheck disable=SC2206
options=(${INPUT_OPTIONS:-})
pg_dump ${options[@]+"${options[@]}"} -d "$INPUT_DATABASE_URL" > "$INPUT_PATH"

echo "Complete"

echo "::endgroup::"
