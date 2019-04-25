#!/bin/bash

set -o errexit
set -o errtrace
set -o pipefail
set -o nounset

function error_handler() {
  echo "Error in script: ${3} line: ${1} status code: ${2}"
}

trap 'error_handler ${LINENO} $? "$(basename ${BASH_SOURCE[0]})"' ERR

set -o xtrace