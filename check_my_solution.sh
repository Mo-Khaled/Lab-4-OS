#!/usr/bin/env bash
# Student self-check for Exercise 5.   Usage: bash check_my_solution.sh [file]
F="${1:-$HOME/lab4/bank.sh}"
[ -f "$F" ] || { echo "❌ $F not found"; exit 1; }
F="$(readlink -f "$F")"
cd "$(dirname "$F")" || exit 1
S=0
grep -v "^\s*#" "$F" | grep -q "flock" && { echo "✅ 1/3  flock is used"; S=$((S+1)); } || echo "❌ 1/3  flock not found (TODO)"
n=$(grep -v "^\s*#" "$F" | grep -c "flock")
[ "$n" -ge 2 ] && { echo "✅ 2/3  flock appears in both deposit and withdraw ($n times)"; S=$((S+1)); } || echo "❌ 2/3  both deposit() and withdraw() need the lock (found $n)"
good=0
for i in 1 2 3 4 5; do
  timeout 120 bash "$F" 2>/dev/null | grep -q "Final balance = 10000" && good=$((good+1))
done
[ "$good" -eq 5 ] && { echo "✅ 3/3  balance was 10000 in 5/5 runs"; S=$((S+1)); } || echo "❌ 3/3  correct in only $good/5 runs - race still there"
echo; echo "Score: $S / 3"
