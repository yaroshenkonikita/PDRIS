#!/bin/bash
# log_search.sh — Поиск по логу и сохранение результатов
# Использование: log_search.sh <log_file> <keyword>
# Выход: 
#  - <basename>.<keyword>.matches.txt — строки, содержащие ключевое слово
#  - <basename>.<keyword>.count.txt   — количество найденных строк

set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") <log_file> <keyword>
Produces:
  - <basename>.<keyword>.matches.txt    lines containing the keyword
  - <basename>.<keyword>.count.txt      number of matching lines
Also prints the count to stdout.
EOF
}

if [ "$#" -ne 2 ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 1
fi

log_file="$1"
keyword="$2"

if [ ! -f "$log_file" ]; then
  echo "Файл не найден: $log_file" >&2
  exit 2
fi

log_base="$(basename "$log_file")"
sanitize() { echo "$1" | sed 's/[^A-Za-z0-9._-]/_/g'; }
safe_key="$(sanitize "$keyword")"

matches_file="${log_base}.${safe_key}.matches.txt"
count_file="${log_base}.${safe_key}.count.txt"

set +e
grep -F -- "$keyword" "$log_file" > "$matches_file"
grep_status=$?
set -e

if [ "$grep_status" -ne 0 ] && [ ! -s "$matches_file" ]; then
  : > "$matches_file"
fi

count="$(wc -l < "$matches_file" | tr -d '[:space:]')"
printf "%s\n" "$count" > "$count_file"

echo "Найдено совпадений: $count"
echo "Файл с совпадениями: $matches_file"
echo "Файл с количеством:  $count_file"

