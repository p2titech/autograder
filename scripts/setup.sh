#!/bin/bash

for assignment in r1 r1p2 r2p1 r2p2 r2p3 r3p1 r3p2 r4p1 r5p1 r5p2 r6p1 r7p1; do
  if [[ ! -d assignments/"$assignment" ]]; then
    gh repo clone p2titech/"$assignment" assignments/"$assignment"
  fi
done
