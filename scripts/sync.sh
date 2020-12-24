#!/bin/bash

for repo in r1 r1p2 r2p1 r2p2 r2p3
do
  cp runtest.sh ../"${repo}"
  cd ../"${repo}" || exit
  git switch master || git switch main
  git add runtest.sh
  git commit -m "Updated runtest.sh"
  git push
done
