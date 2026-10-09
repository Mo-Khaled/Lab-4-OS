#!/usr/bin/env bash
# Lab 4 setup: installs tools (if missing) and creates the lab files.
# Usage: bash setup.sh
set -e
need=""
for t in ps top pstree flock sort xz shuf; do command -v $t >/dev/null || need="$need $t"; done
if [ -n "$need" ]; then
  echo "Missing tools:$need  -> installing (needs your password)"
  sudo apt update && sudo apt install -y procps psmisc util-linux coreutils xz-utils
fi
mkdir -p ~/lab4 && cd ~/lab4
echo "Creating data.txt (3 million random numbers)..."
seq 1 3000000 | shuf > data.txt
echo 0 > counter.txt
echo 10000 > balance.txt
cp "$(dirname "$(readlink -f "$0")")/bank.sh" ~/lab4/bank.sh
echo "✅ Ready. Work in:  cd ~/lab4"
ls -lh ~/lab4
