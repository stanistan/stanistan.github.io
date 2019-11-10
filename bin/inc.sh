#!/bin/bash

err() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
}

pushd() {
    command pushd "$@" > /dev/null
}

popd() {
    command popd "$@" > /dev/null
}

current_git_branch() {
    git branch | grep \* | awk '{ print $2 }'
}
