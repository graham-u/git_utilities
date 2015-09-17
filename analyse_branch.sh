#!/bin/bash

feature_br=${1:-HEAD}

git_initial_fork_point () {
    # thanks to http://stackoverflow.com/a/4991675/14162
    diff -u <(git rev-list --first-parent "${1:-master}") <(git rev-list --first-parent "${2:-HEAD}") | sed -ne "s/^ //p" | head -1
}

# @TODO enable upstream branches as parameters to script 
for upstream_br in master develop qa; do
    initial_fork_point=$(git_initial_fork_point $upstream_br $feature_br)
    distance_to_intial_fork_point=$(git rev-list $feature_br ^$initial_fork_point --count)
    merge_base=$(git merge-base $upstream_br $feature_br)
    distance_to_merge_base_from_feature_br=$(git rev-list --first-parent $feature_br ^$merge_base --count)
    distance_to_merge_base_from_upstream_br=$(git rev-list --first-parent $upstream_br ^$merge_base --count)

    if [ -z "$shortest_distance" ] || [ "$distance_to_intial_fork_point" -lt "$shortest_distance" ]; then
      shortest_distance=$distance_to_intial_fork_point
      branch_with_most_recent_initial_fork=$upstream_br
    fi

    echo -e "\n"
    echo -e "[$feature_br]:"
    echo -e "Was forked from an ancestor of [$upstream_br] $distance_to_intial_fork_point commits ago at initial_fork_point"
    echo -e "Has most recent common ancestor (merge-base) $merge_base"
    echo -e "Distance to merge-base from [$feature_br] is $distance_to_merge_base_from_feature_br commits"
    echo -e "Distance to merge-base from [$upstream_br]'s $distance_to_merge_base_from_upstream_br commits\n"
done

echo "Forked from $branch_with_most_recent_initial_fork"