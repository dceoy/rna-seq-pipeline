#!/usr/bin/env bash
#
# Usage:
#   count_reads_in_fq.sh <fq_gz>...

set -uex

case "${OSTYPE}" in
  darwin* )
    CPUS=$(sysctl -n hw.ncpu)
    ;;
  linux* )
    CPUS=$(grep -ce '^processor\s\+:' /proc/cpuinfo)
    ;;
  * )
    CPUS=1
    ;;
esac

printf "fastq_gz_path\tread_count\n"
for p in "${@}"; do
  n_lines=$(pigz -p "${CPUS}" -dc "${p}" | wc -l)
  printf "%s\t%d\n" "${p}" $(( n_lines / 4 ))
done
