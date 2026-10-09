# 🧵 Lab 4 (Commands Edition) — Thread Application + Race Condition Demo

**Course:** ECE3503 Operating Systems · **Week 4** · **Time:** ~90 minutes
**Reference:** Stallings, *Operating Systems*, Ch. 4 (Threads) and Ch. 5 (Concurrency)
**No programming needed** — you will only type Linux commands in the terminal.

## 🎯 What you will learn
1. See threads inside real running programs (`ps`, `top`, `/proc`).
2. Run a **multi-threaded application** (`sort --parallel`) and measure the speedup.
3. **Cause** a race condition using only the shell.
4. Fix it with a **lock** (`flock`).

## 🧰 Setup
Open the terminal (**Ctrl + Alt + T**), go to the lab folder and run:
```
bash setup.sh
cd ~/lab4
```
This installs missing tools and creates `data.txt` (3 million random numbers), `counter.txt` and `bank.sh`.
Check how many CPU cores you have — you will need this number later:
```
nproc
```

---

## Exercise 1 — Where are the threads? (15 min)

**1.1 Processes vs threads.** Compare:
```
ps -e | wc -l          # number of processes
ps -eLf | wc -l        # number of threads (L = show threads)
```
Write both numbers. Which is bigger? Why?

**1.2 Who has the most threads?**
```
ps -eo pid,nlwp,comm --sort=-nlwp | head
```
`NLWP` = *Number of Light-Weight Processes* = number of threads. Which program has the most?

**1.3 Look inside one process.** Your shell has its own PID in `$$`:
```
echo $$
ls /proc/$$/task
grep Threads /proc/$$/status
```
Each folder in `task/` is one thread. How many threads does your shell have?

**1.4 Shared or private?** Pick any multi-threaded PID from 1.2 (call it `PID`):
```
grep -E 'Name|^Pid|Tgid' /proc/PID/task/*/status
```
Notice that every thread has a **different `Pid`** (its thread ID) but the **same `Tgid`** (the process it belongs to).
**Question:** Which is the *process ID* and which is the *thread ID* as Stallings defines them? (In Linux every thread is a task created with `clone()`.)

**1.5 Live view.**
```
top -H
```
`-H` shows threads instead of processes. Press **q** to quit.

---

## Exercise 2 — A multi-threaded application (20 min)
`sort` can use several threads. Sort the 3 million numbers using 1, 2, and 4 threads:
```
time sort -n --parallel=1 -S 300M data.txt > /dev/null
time sort -n --parallel=2 -S 300M data.txt > /dev/null
time sort -n --parallel=4 -S 300M data.txt > /dev/null
```
Use the **real** time. Fill in:

| Threads | real time (s) | Speedup (= time₁ ÷ time_N) |
|---------|---------------|-----------------------------|
| 1       |               | 1.00                        |
| 2       |               |                             |
| 4       |               |                             |

**2.1** Is 4 threads 4× faster? Compare with your `nproc`. Why can't speedup exceed the number of cores? (Tutorial 2, Amdahl's Law.)

**2.2 Catch the threads in action.** Start the sort in the background and inspect it quickly:
```
sort -n --parallel=4 -S 300M data.txt > /dev/null &
PID=$!
ps -T -p $PID
grep Threads /proc/$PID/status
wait
```
(`&` runs it in the background, `$!` is its PID.) How many threads did you see?

**2.3** Compare with a program that is **not** multi-threaded:
```
time gzip -c data.txt > /dev/null
```
Can adding threads make `gzip` faster? What would we need? *(Hint: try `xz -T4 -c data.txt | wc -c`.)*

---

## Exercise 3 — Race condition demo (20 min)
Several jobs will add 1 to a number stored in a **shared file**, `counter.txt`. The correct final answer is *jobs × 500*.
*(These jobs are processes, not threads, but they share a resource exactly like threads share a variable — the race is identical.)*

**3.1 One job — the baseline.** Define a function (copy exactly):
```
inc() { for i in $(seq 500); do n=$(cat counter.txt); echo $((n+1)) > counter.txt; done; }
```
It has three steps — **READ** (`cat`), **MODIFY** (`$((n+1))`), **WRITE** (`echo >`). Run it alone:
```
echo 0 > counter.txt
inc
cat counter.txt
```
Expected: 500 ✅

**3.2 Four jobs at once.**
```
echo 0 > counter.txt
inc & inc & inc & inc &
wait
cat counter.txt
```
Expected: 2000. What did you get? Run it **3 times** and write all results.

**3.3 Explain.** Why is the answer smaller — and different each time? Draw the timeline:
```
Job A:  READ (7) ─────────────────────► WRITE 8
Job B:        READ (7) ───────────────► WRITE 8     ← one increment LOST
```
**3.4** Which line is the **critical section**?

> 🔍 Sometimes you may see a result that is much lower than expected, or even an error. The shell can read `counter.txt` at the moment another job has just emptied it (`>` truncates the file before writing). More proof that unsynchronized access is dangerous.

---

## Exercise 4 — Fix it with a lock (15 min)
`flock` gives mutual exclusion: only one job can hold the lock at a time.
```
echo 0 > counter.txt
safe() { for i in $(seq 125); do ( flock 9; n=$(cat counter.txt); echo $((n+1)) > counter.txt ) 9>counter.lock; done; }
time ( safe & safe & safe & safe & wait )
cat counter.txt
```
Expected: 500 (4 jobs × 125).

**4.1** Run 3 times. Is it always correct?
**4.2** The lock file is `counter.lock`; `flock 9` locks file descriptor 9, which is opened by `9>counter.lock`. What would happen if each job used a *different* lock file?
**4.3** Time the unsafe version with the same total work (`inc` replaced by 125 iterations) and compare. What is the price of safety?

---

## 🏆 Exercise 5 — Challenge: the bank (15 min)
Open the script:
```
nano bank.sh
```
Two depositors and two withdrawers share `balance.txt` (start 10000 → must end at 10000).
1. Run `bash bank.sh` as-is. What balance do you get?
2. Fix it: wrap the **read-modify-write** in `( flock 9 ... ) 9>balance.lock` inside **both** functions. (Save with **Ctrl+O**, Enter, exit with **Ctrl+X**.)
3. Run the checker:
```
bash check_my_solution.sh
```
You should get **3 / 3**.

Answer in your report:
- **Q1.** Which lines form the critical section?
- **Q2.** Why must deposit and withdraw use the *same* lock file?
- **Q3.** Is `flock` a software or hardware solution? What does the OS provide to make it work? (Think Ch. 5: mutual exclusion.)

---

## 📝 Submission
A short report (PDF or Markdown) with: the numbers/answers for all Tasks, a screenshot of Ex. 3 (wrong result) and Ex. 4 (correct), your fixed `bank.sh`, and the answers to Q1–Q3.

## ✅ Self-check
- [ ] I can tell a process ID from a thread ID in `/proc`.
- [ ] I can explain why speedup is limited by the number of cores.
- [ ] I can define *race condition*, *critical section*, *mutual exclusion*.
- [ ] I can explain why `flock` fixes the race.

## 🧹 Cleanup
```
cd ~ && rm -rf ~/lab4
```
