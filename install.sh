#!/bin/sh

REPO_DIR=$(PWD)

if [ ! -d "$REPO_DIR/Cheftasks" ]; then
  echo "Adding Cheftasks as a submodule"
  git submodule add https://github.com/jmbogaty/Cheftasks.git
  cd "$REPO_DIR/Cheftasks"
  rake install
else
  echo "Cheftasks is already a submodule. Updating it."
  cd "$REPO_DIR/Cheftasks"
  rake update
fi
