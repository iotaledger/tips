#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0
# Source: https://github.com/rust-lang/rfcs/blob/85c95c7179acc8986eae709f773ff3a91f1e2e43/generate-book.sh

set -e

rm -rf src
mkdir src
cp -r tips src

printf '[Introduction](introduction.md)\n\n' > src/SUMMARY.md

# create summary, extract tip titles and numbers
find ./src ! -type d -name '*.md' ! -path ./src ! -path ./src/SUMMARY.md -print0 \
  | sed -e 's/.\/src\///g' \
  | sort -z \
  | while read -r -d '' file;
do
    tipNum=$(sed 's/-0*/-/' <<< $(basename "$file" ".md"))
    printf -- '- [%s%s](%s)\n' ${tipNum^^} "$(sed -n 's/^title:\(.*\)$/\1/p' < $file)" "$file"
done >> src/SUMMARY.md

# remove "---" from tip header and replace it h <pre> and </pre>
find ./src ! -type d -name '*.md' ! -path ./src ! -path ./src/SUMMARY.md -print0 \
  | sort -z \
  | while read -r -d '' file;
do
    ./format-tip-header.sh $file
done

ln -frs README.md src/introduction.md

mdbook build
