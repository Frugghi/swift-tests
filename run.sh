#!/bin/bash

function check::linux {
  local tempDir="/tmp/${PWD##*/}"
  if [[ "$(uname)" == Linux ]] && [[ -f "${tempDir}/.build/debug/swift-tests" ]]; then
    return 0
  else
    return 1
  fi
}

function run::linux {
  local tempDir="/tmp/${PWD##*/}"

  cd "${tempDir}"
  "${tempDir}/.build/debug/swift-tests" "$@"
  cd - > /dev/null
  find "${tempDir}/Results" -type f -name '*.md' ! -name 'README*' -exec cp '{}' ./Results ';'
}

function check::docker {
  if [[ -x "$(command -v docker)" ]] && [[ $(docker images | grep -c fr8r-apis) -gt 0 ]]; then
    return 0
  else
    return 1
  fi
}

function run::docker {
  local dir extra=()
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ ! -z "${KUBECONFIG}" ]]; then
    extra+=(--volume "$(dirname "${KUBECONFIG}"):/kubeconfig")
  fi

  docker run --rm \
             --tty \
             --volume "${dir}/Resources:/swift-tests/Resources" \
             --volume "${dir}/Results:/swift-tests/Results" \
             "${extra[@]}" \
             swift-tests "$@"
}

if check::docker ; then
  run::docker "$@"
elif check::linux ; then
  run::linux "$@"
else
  echo "At least one of the following conditions must be met:"
  echo "- Docker installed and swift-tests image built"
  echo "- Linux OS and swift-tests built with ./compile.sh"
  exit 1
fi
