#!/usr/bin/env bash
#
# Usage:
#   cat_fq.sh <in_dir> <out_dir>

set -uex

BC_DIRS=$(find "${1}" -type d -name 'BaseCalls')
OUT_DIR=$(realpath "${2}")

function extract_fq_ids {
  find "${*}" -maxdepth 1 -type f -name '*.fastq.gz' \
    -exec basename {} \; \
    | sed -e 's/_L[0-9]\{3\}_R[12]_[0-9]\{3\}.fastq.gz//' \
    | sort \
    | uniq
}

mkdir "${OUT_DIR}"

for bc_dir in ${BC_DIRS}; do
  run_id=$(echo "${bc_dir}" | awk -F / '{print $(NF-3)}')
  for fq_id in $(extract_fq_ids "${bc_dir}"); do
    echo ">>> FASTQ ID: ${fq_id}"
    for i in $(seq 1 2); do
      dest="${OUT_DIR}/${fq_id}_${run_id}.R${i}.fastq.gz"
      if [[ -f "${dest}" ]]; then
        echo "already exists: ${dest}" && exit 1
      else
        echo ">>>>>> ${dest}"
        cat "${bc_dir}/${fq_id}"_*_"R${i}"_*.fastq.gz > "${dest}"
      fi
    done
  done
done
