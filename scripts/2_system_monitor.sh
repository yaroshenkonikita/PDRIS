#!/bin/bash
# system_monitor.sh — Мониторинг системных метрик (демон)
# Команды: START | STOP | STATUS
# Каждые 10 минут (по умолчанию) пишет строку в CSV-файл system_report_YYYY-MM-DD.csv
# Формат строки: timestamp;all_memory;free_memory;%memory_used;%cpu_used;%disk_used;load_average_1m

set -euo pipefail

INTERVAL_SEC="${INTERVAL_SEC:-600}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pid_file="$script_dir/system_monitor.pid"

is_running() {
  if [ -f "$pid_file" ]; then
    pid="$(cat "$pid_file")"
    if kill -0 "$pid" 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

write_header_if_needed() {
  local file="$1"
  if [ ! -f "$file" ] || [ ! -s "$file" ]; then
    echo "timestamp;all_memory(MiB);free_memory(MiB);%memory_used;%cpu_used;%disk_used;load_average_1m" >> "$file"
  fi
}

cpu_used_pct() {
  read -r _ u1 n1 s1 i1 w1 irq1 sirq1 st1 g1 gn1 < /proc/stat
  sleep 1
  read -r _ u2 n2 s2 i2 w2 irq2 sirq2 st2 g2 gn2 < /proc/stat
  local idle1=$(( i1 + w1 ))
  local idle2=$(( i2 + w2 ))
  local total1=$(( u1 + n1 + s1 + i1 + w1 + irq1 + sirq1 + st1 + g1 + gn1 ))
  local total2=$(( u2 + n2 + s2 + i2 + w2 + irq2 + sirq2 + st2 + g2 + gn2 ))
  local dt=$(( total2 - total1 ))
  local didle=$(( idle2 - idle1 ))
  local du=$(( dt - didle ))
  if [ "$dt" -gt 0 ]; then
    awk -v u="$du" -v t="$dt" 'BEGIN{printf "%.2f", (u*100)/t}'
  else
    echo "0.00"
  fi
}

monitor_loop() {
  trap 'exit 0' TERM INT
  while :; do
    ts="$(date '+%Y-%m-%d %H:%M:%S')"

    mem_total_kb="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
    mem_avail_kb="$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)"
    mem_total_mb=$(( (mem_total_kb + 1023) / 1024 ))
    mem_free_mb=$(( (mem_avail_kb + 1023) / 1024 ))
    mem_used_pct="$(awk -v t="$mem_total_kb" -v a="$mem_avail_kb" 'BEGIN{if (t>0) printf "%.2f", (t-a)*100/t; else print "0.00"}')"

    cpu_pct="$(cpu_used_pct)"

    disk_used_pct="$(df -P / | awk 'NR==2 {gsub("%","",$5); print $5}')"

    load1="$(awk '{print $1}' /proc/loadavg)"

    current_date="$(date +%F)"
    outfile="$script_dir/system_report_${current_date}.csv"
    write_header_if_needed "$outfile"

    printf "%s;%s;%s;%s;%s;%s;%s\n" \
      "$ts" "$mem_total_mb" "$mem_free_mb" "$mem_used_pct" "$cpu_pct" "$disk_used_pct" "$load1" >> "$outfile"

    sleep "$INTERVAL_SEC"
  done
}

if [ "${1:-}" = "__run" ]; then
  monitor_loop
  exit 0
fi

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") START|STOP|STATUS
Environment:
  INTERVAL_SEC   Интервал опроса в секундах (по умолчанию: 600)
Выводит CSV: system_report_YYYY-MM-DD.csv в каталоге $(basename "$script_dir")
EOF
}

case "${1:-}" in
  START)
    if is_running; then
      echo "Уже запущен (PID: $(cat "$pid_file"))"
      exit 0
    fi
    nohup "$0" __run >/dev/null 2>&1 &
    echo $! > "$pid_file"
    echo "Запущен (PID: $(cat "$pid_file"))"
    ;;
  STOP)
    if ! is_running; then
      echo "Не запущен"
      exit 0
    fi
    pid="$(cat "$pid_file")"
    kill -TERM "$pid" 2>/dev/null || true
    for _ in 1 2 3 4 5; do
      if ! kill -0 "$pid" 2>/dev/null; then break; fi
      sleep 1
    done
    if kill -0 "$pid" 2>/dev/null; then
      kill -KILL "$pid" 2>/dev/null || true
    fi
    rm -f "$pid_file"
    echo "Остановлен"
    ;;
  STATUS)
    if is_running; then
      echo "Статус: запущен (PID: $(cat "$pid_file"))"
    else
      echo "Статус: не запущен"
    fi
    ;;
  -h|--help|"")
    usage
    ;;
  *)
    echo "Неизвестная команда: $1" >&2
    usage
    exit 1
    ;;
esac

