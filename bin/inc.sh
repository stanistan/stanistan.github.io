#!/bin/bash

err() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

pushd() {
    command pushd "$@" > /dev/null
}

# shellcheck disable=SC2120
popd() {
    command popd "$@" > /dev/null
}

current_git_branch() {
    git branch | grep '\*' | awk '{ print $2 }'
}

abs_path() {
    local dir
    local base
    dir=$(dirname "$1")
    base=$(basename "$1")
    echo "$(cd "$dir" && pwd)/$base"
}
