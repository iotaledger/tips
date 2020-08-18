#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0
# Source: https://github.com/rust-lang/rfcs/blob/85c95c7179acc8986eae709f773ff3a91f1e2e43/generate-book.sh

set -e

rm -rf src
cp -r text src

printf '[Introduction](introduction.md)\n\n' > src/SUMMARY.md

find ./src ! -type d -name '*.md' ! -path ./src ! -path ./src/SUMMARY.md -print0 \
  | sed -e 's/.\/src\///g' \
  | sort -z \
  | while read -r -d '' file;
do
    printf -- '- [%s](%s)\n' "$(basename "$file" ".md")" "$file"
done >> src/SUMMARY.md

ln -frs README.md src/introduction.md

mdbook build
