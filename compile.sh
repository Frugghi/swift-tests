#!/bin/bash

DIR="/tmp/${PWD##*/}"

mkdir -p "$DIR"
ls --format single-column | sed "s|^|$DIR/|" | tr "\n" "\0" | xargs -0 rm -rf
cp -rf ./* "$DIR"
cd "$DIR"
if [[ -f ./Packages/Yaml-3.0.0/Yaml/LinuxPatch.swift ]]; then
  sudo swift build
else
  sudo swift build | sed '/.*\/Packages\/Yaml-3.0.0\/Yaml\// { N; N; d; }'
  echo -e "import Foundation\n\n#if os(Linux)\ntypealias NSRegularExpression = RegularExpression\n#endif\n" | sudo tee ./Packages/Yaml-3.0.0/Yaml/LinuxPatch.swift > /dev/null
  sudo swift build
fi
