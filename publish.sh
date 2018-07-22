#!/bin/sh
set -e
set -x

git diff-index --quiet HEAD -- || (echo "Please commit any pending changes."; exit 1)
git ls-files --exclude-standard --others || (echo "Please commit any pending changes."; exit 1)

git push origin src

HASH=$(git rev-parse HEAD)

HUGO_ENV="production" hugo

mv public .public

git checkout master
git pull

rm -rf *
mv .public/* .
rm -rf .public

git add . && git commit -s -m "Publish $HASH"
git push origin master

git checkout src
git clean -fdqx
