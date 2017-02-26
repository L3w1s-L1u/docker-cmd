#! /bin/bash

# copied from: Joe Linoff's Stack Overflow post: 
# http://stackoverflow.com/questions/24481564/how-can-i-find-docker-image-with-specific-tag-in-docker-registry-in-docker-comma

# Simple script that will display docker repository tags.
#
# Usage:
#   $ docker-show-repo-tags.sh ubuntu centos
show_remote_repo_tags() {
    curl -s -S "https://registry.hub.docker.com/v2/repositories/$@/tags/" | jq '.results[]["name"]' |sort
}
show_repo_tags() {
    for Repo in $* ; do
      curl -s -S "https://registry.hub.docker.com/v2/repositories/library/$Repo/tags/" | \
      sed -e 's/,/,\n/g' -e 's/\[/\[\n/g' | \
      grep '"name"' | \
      awk -F\" '{print $4;}' | \
      sort -fu | \
      sed -e "s/^/${Repo}:/"
    done
}
