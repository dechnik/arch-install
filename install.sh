#!/bin/bash

. ./errors.sh

for file in $(ls 0*.sh | sort -n); do
  echo "File: ${file}"
  bash ./${file}
  echo "File complete"
done