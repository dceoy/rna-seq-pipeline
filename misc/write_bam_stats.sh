#!/usr/bin/env bash
#
# Usage:
#   write_bam_stats.sh <in_dir> <out_dir>

set -uex

IN_DIR=$(realpath "${1}")
OUT_DIR=$(realpath "${2}")

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

[[ -d "${IN_DIR}" ]]
[[ -d "${OUT_DIR}" ]]

BAM_PATHS=$(find "${IN_DIR}" -type f -name '*.bam')
CMDS=()
for p in ${BAM_PATHS}; do
  [[ -f "${p}" ]]
  bam_name=$(basename "${p}")
  for c in 'idxstats' 'flagstat' 'stats'; do
    CMDS+=("set -x && samtools ${c} ${p} | tee ${OUT_DIR}/samtools.${c}.${bam_name}.txt")
  done
done

printf '%s\n' "${CMDS[@]}" | xargs -L 1 -P "${CPUS}" -i bash -c '{}'
