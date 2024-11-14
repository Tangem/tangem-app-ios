#!/bin/bash

set -eo pipefail

# Input args
if [ -z "$1" ]; then
  echo "Error: No base branch argument provided or empty string given."
  echo "Usage: $0 <base-branch>"
  exit 1
fi
base_branch=$1

# Initialize variables to store the latest release branch and merge base
latest_branch=""
latest_merge_base=""

# Source refs to find branches from
local_refs="refs/heads/releases/*"  # For debug and development
remote_refs="refs/remotes/origin/releases/*"

# Iterate over all remote release branches, sorted by commit date (most recent first)
for branch in $(git for-each-ref --sort=-committerdate --format='%(refname:short)' "$remote_refs"); do
    # Find the merge base between 'base_branch' and the release branch
    merge_base=$(git merge-base "$base_branch" "$branch")

    echo "Merge base for branches '$branch' and '$base_branch' is '$merge_base'"

    # If no latest merge base is set, or if this merge base is newer, update it
    if [ -z "$latest_merge_base" ] || git rev-list "$latest_merge_base..$merge_base" | grep -q .; then
        latest_branch="$branch"
        latest_merge_base="$merge_base"
    fi
done

# Output validation
if [ -z "$latest_branch" ]; then
  echo "Error: Can't find the latest 'release/*' branch for the base branch '$base_branch'"
  exit 2
fi

# Stripping 'origin/' prefix if needed
latest_branch="${latest_branch#origin/}"

echo "$latest_branch" > "find-latest-release-branch.output"
echo "Latest release branch created directly from '$base_branch' or its ancestor: '$latest_branch'"
