#!/bin/bash

for repo in r1 r1p2 r2p1 r2p2 r2p3 r3p1 r3p2 r4p1 r5p1 r5p2 r6p1 r7p1; do
  cp runtest.sh assignments/"${repo}"
  pushd assignments/"${repo}" || exit
  git switch master || git switch main
  git pull
  git add runtest.sh
  git commit -m "Updated runtest.sh"
  git push
  popd
done
