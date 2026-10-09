#!/usr/bin/env bash
# Instructor pre-flight check.  Usage: bash check_environment.sh
SRC="$(dirname "$(readlink -f "$0")")"; W=$(mktemp -d); cd "$W" || exit 1; cp "$SRC/bank.sh" .
P=0; F=0
ok(){ echo "  ✅ $1"; P=$((P+1)); }; bad(){ echo "  ❌ $1"; F=$((F+1)); }
. /etc/os-release 2>/dev/null; echo "OS: $PRETTY_NAME | cores: $(nproc)"
for t in ps top pstree flock sort xz shuf nano; do command -v $t >/dev/null && ok "$t installed" || bad "$t missing (bash setup.sh installs most)"; done
[ -d /proc/$$/task ] && ok "/proc/PID/task available" || bad "/proc/PID/task missing"
seq 1 1000000 | shuf > data.txt
sort -n --parallel=4 -S 100M data.txt >/dev/null & pid=$!; sleep 0.3
nt=$(grep Threads /proc/$pid/status 2>/dev/null | awk '{print $2}'); wait
[ "${nt:-1}" -gt 1 ] && ok "sort --parallel=4 shows $nt threads" || bad "could not observe sort threads (is the file too small / 1 core?)"
echo 0 > counter.txt
l(){ for i in $(seq 250); do n=$(cat counter.txt); echo $((n+1)) > counter.txt; done; }
l & l & l & l & wait; c=$(cat counter.txt)
[ "$c" -lt 1000 ] && ok "race reproduced: counter=$c (expected 1000)" || bad "race NOT reproduced (counter=$c)"
echo 0 > counter.txt
s(){ for i in $(seq 250); do ( flock 9; n=$(cat counter.txt); echo $((n+1)) > counter.txt ) 9>counter.lock; done; }
s & s & s & s & wait; c=$(cat counter.txt)
[ "$c" -eq 1000 ] && ok "flock fixes it: counter=$c" || bad "flock version wrong: $c"
b=$(bash bank.sh 2>/dev/null | grep -o "= [0-9]*" | head -1 | tr -d '= ')
[ "$b" != "10000" ] && ok "bank.sh starter is broken as intended ($b)" || bad "bank.sh starter gave 10000 - race not seen, rerun"
echo; echo "$P passed, $F failed"
