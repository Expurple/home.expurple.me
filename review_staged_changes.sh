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

# Temporarily stash all changes, so that we can generate the previous version of the website.
#
# But first, create a separate stash with only staged changes,
# so that we can first apply only these changes and generate the to-be-committed website.
# `--keep-index` is needed so that we always have something to stash into the "full" stash.
git stash push --staged --keep-index -m 'changes to be committed'
git stash push -u -m 'full local state'

# Generate the old version.
hugo_generate_into "$head_build_dir"

# Apply the stash with staged changes and stage them back.
git stash pop 1
git add --all

# Generate the staged version.
hugo_generate_into "$staged_build_dir"

# Restore all unstaged local changes.
git stash pop 0
