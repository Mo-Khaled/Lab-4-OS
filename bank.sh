#!/usr/bin/env bash
# Exercise 5 - Bank account (shell version)
# Usage: bash bank.sh
# 4 background jobs share ONE file (balance.txt):
#   2 depositors  : +1 EGP, 250 times each
#   2 withdrawers : -1 EGP, 250 times each
# Starts at 10000, so it must END at 10000.

echo 10000 > balance.txt

deposit() {
  for i in $(seq 250); do
    # TODO: make this read-modify-write safe (use flock)
    b=$(cat balance.txt)
    echo $((b + 1)) > balance.txt
  done
}

withdraw() {
  for i in $(seq 250); do
    # TODO: make this read-modify-write safe (use the SAME lock file)
    b=$(cat balance.txt)
    echo $((b - 1)) > balance.txt
  done
}

deposit & deposit & withdraw & withdraw &
wait
echo "Final balance = $(cat balance.txt)   (expected 10000)"
