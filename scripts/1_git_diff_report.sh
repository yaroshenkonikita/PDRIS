#!/bin/bash
# git_diff_report.sh — Сформировать структурированный TXT-отчет о различиях между двумя ветками удалённого Git-репозитория
# Использование: git_diff_report.sh <repo_url> <branch_1> <branch_2>

set -euo pipefail

err() { echo "Error: $*" >&2; }

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") <repo_url> <branch_1> <branch_2>
Generates: diff_report_<branch_1>_vs_<branch_2>.txt in the current directory.
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage; exit 0
fi

if [ "$#" -ne 3 ]; then
  usage; exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  err "git is required but not found in PATH"; exit 1
fi

repo_url="$1"
branch1="$2"
branch2="$3"

sanitize() {
  echo "$1" | sed 's/[^A-Za-z0-9._-]/_/g'
}

sb1="$(sanitize "$branch1")"
sb2="$(sanitize "$branch2")"
report_file="diff_report_${sb1}_vs_${sb2}.txt"

start_dir="$(pwd)"
tmpdir="$(mktemp -d -t gitdiff.XXXXXX)"
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

cd "$tmpdir"
git init -q repo
cd repo
git remote add origin "$repo_url"

set +e
git fetch -q --depth=1 origin "refs/heads/$branch1:refs/heads/$branch1" "refs/heads/$branch2:refs/heads/$branch2"
fetch_status=$?
set -e
if [ "$fetch_status" -ne 0 ]; then
  err "Failed to fetch branches from repository. Check URL and branch names."
  exit 2
fi

if ! git show-ref --verify --quiet "refs/heads/$branch1"; then
  err "Branch not found: $branch1"
  exit 3
fi
if ! git show-ref --verify --quiet "refs/heads/$branch2"; then
  err "Branch not found: $branch2"
  exit 3
fi

diff_output="$(git diff --name-status --no-renames --no-color "$branch1" "$branch2")"

total_files=0
count_A=0
count_D=0
count_M=0

if [ -n "$diff_output" ]; then
  total_files="$(printf "%s\n" "$diff_output" | sed '/^[[:space:]]*$/d' | wc -l | tr -d '[:space:]')"
  read -r count_A count_D count_M <<EOF
$(printf "%s\n" "$diff_output" | awk '
  {s=$1}
  s=="A" {a++}
  s=="D" {d++}
  s=="M" {m++}
  END {printf "%d %d %d\n", a+0, d+0, m+0}
')
EOF
fi

now="$(date '+%Y-%m-%d %H:%M:%S')"
{
  echo "Отчет о различиях между ветками"
  echo
  echo "================================"
  echo "Репозиторий:    $repo_url"
  echo "Ветка 1:        $branch1"
  echo "Ветка 2:        $branch2"
  echo "Дата генерации: $now"
  echo "================================"
  echo
  echo "СПИСОК ИЗМЕНЕННЫХ ФАЙЛОВ:"
  if [ -n "$diff_output" ]; then
    printf "%s\n" "$diff_output"
  else
    echo "(нет изменений)"
  fi
  echo
  echo "СТАТИСТИКА:"
  echo "Всего измененных файлов: $total_files"
  printf "Добавлено (A):    %s\n" "$count_A"
  printf "Удалено (D):      %s\n" "$count_D"
  printf "Изменено (M):     %s\n" "$count_M"
} > "$start_dir/$report_file"

echo "Готово: $report_file"

