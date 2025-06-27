#!/bin/bash

# A script to generate two folders:
#
# - `public.bak/` with the previous version of the website.
# - `public/` with the staged version of the website.
#
# After running this script, I manually review the diff in VSCode.

set -xeo pipefail

# Constants.
head_build_dir=public.bak
staged_build_dir=public

hugo_generate_into() {
    hugo --destination "$1" --cleanDestinationDir
}

# Temporarily stash all changes. We need to regenerate the previous version of the website.
#
# We also create a separate stash for only staged changes,
# so that we can first apply back only these changes and generate the to-be-committed website.
git stash --staged -m 'changes to be committed'
git stash -u -m 'full local state'

# Generate the old version.
hugo_generate_into "$head_build_dir"

# Apply the stash with staged changes and stage them back.
git stash pop 1
git add --all

# Generate the staged version.
hugo_generate_into "$staged_build_dir"

# Restore all unstaged local changes.
git stash pop 0
