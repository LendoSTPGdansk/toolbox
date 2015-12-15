#!/bin/bash

MESSAGE="[wip][pp]"

if [ "$1" != "" ]; then
    MESSAGE="$MESSAGE: $1"
fi

git add --all
git commit -m "$MESSAGE"
git push origin `git rev-parse --abbrev-ref HEAD`
