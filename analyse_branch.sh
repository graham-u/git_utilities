#!/bin/bash

# Formatting vars
f_bold=$(tput bold)
f_und=$(tput smul)
f_normal=$(tput sgr0)

feature_br=${1:-HEAD}

if [ $# -gt 1 ]; then
  shift
  upsteam_brs=$@
else
  # @TODO bring in defaults from uncommitted config file
  upsteam_brs="master"
fi

if [ $feature_br = "HEAD" ]; then
    feature_br=$(git symbolic-ref --short HEAD)
fi

git_initial_fork_point () {
    # thanks to http://stackoverflow.com/a/4991675/14162
    diff -u <(git rev-list --first-parent "${1:-master}") <(git rev-list --first-parent "${2:-HEAD}") | sed -ne "s/^ //p" | head -1
}

for upstream_br in $upsteam_brs; do
    initial_fork_point=$(git rev-parse --short $(git_initial_fork_point $upstream_br $feature_br))
    time_ago_to_initial_fork=$(git log -n1 $initial_fork_point --format="%ar")
    distance_to_intial_fork_point=$(git rev-list $feature_br ^$initial_fork_point --count)

    merge_base=$(git rev-parse --short $(git merge-base $upstream_br $feature_br))
    time_ago_to_merge_base=$(git log -n1 $merge_base --format="%ar")
    distance_to_merge_base_from_feature_br=$(git rev-list --first-parent $feature_br ^$merge_base --count)
    distance_to_merge_base_from_upstream_br=$(git rev-list --first-parent $upstream_br ^$merge_base --count)

    if [ -z "$shortest_distance" ] || [ "$distance_to_intial_fork_point" -lt "$shortest_distance" ]; then
      shortest_distance=$distance_to_intial_fork_point
      branch_with_most_recent_initial_fork=$upstream_br
    fi

    echo -e "${f_bold}$feature_br in relation to ${f_und}$upstream_br${f_normal}"
    echo -e "Was forked from an ancestor of $upstream_br $distance_to_intial_fork_point commits ago at $initial_fork_point ($time_ago_to_initial_fork)"
    echo -e "Has most recent common ancestor (merge-base) with $upstream_br $time_ago_to_merge_base at $merge_base"
    echo -e "Distance to merge-base from $feature_br is $distance_to_merge_base_from_feature_br commits"
    echo -e "Distance to merge-base from $upstream_br's $distance_to_merge_base_from_upstream_br commits"
    echo -e "\n";
done

echo "Based on intial fork points from branches [$upsteam_brs], looks like $feature_br was forked from $branch_with_most_recent_initial_fork"
